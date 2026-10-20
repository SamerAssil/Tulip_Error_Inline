# Tulip Error Inline — findings and changes from a downstream fork

**To:** Samer Assil — author of [Tulip Error Inline](https://github.com/SamerAssil/Tulip_Error_Inline)
**From:** Ian Branch (GITLAK)
**Date:** 5 September 2026
**Base commit:** `73e5563`
**Environment:** RAD Studio / Delphi 13 (Florence, 37.0), Windows 11, both the 32-bit and 64-bit IDEs

Thank you for the plug-in — it is a genuinely useful addition to the editor, and the core idea
works well. In adapting it for our own use I reviewed the source closely and then verified the
behaviour in a running IDE. This document lists what I found, in the hope it is useful to you.

Everything below refers to **line numbers in your `73e5563` source**. Nothing here is a
complaint about the design; most items are small, and several only surface in conditions that
are easy to miss.

**Please note section C especially** — it records a place where I concluded your code was wrong,
changed it, and then proved in the running IDE that *you were right and I was wrong*. It
documents a genuinely confusing ToolsAPI detail that is worth a comment in the source.

---

## Summary

| # | Item | File (upstream) | Severity |
|---|---|---|---|
| A1 | Editor canvas left with the plug-in's font, brush and pen | `main.pas:195, 210` | High |
| A2 | Custom colours cannot be shown, and are silently overwritten on Save | `Options.dfm` | High |
| A3 | Update Interval is unbounded — `0` re-reads the error list on every painted line | `Options.pas:166` | High |
| A4 | Blank lines inherit the previous line's width, so the message is misplaced | `main.pas:270-271, 293` | Medium |
| A5 | `atComment` used as "the IDE background colour" | `main.pas:193` | Medium |
| A6 | Right alignment moves only the pill's right edge | `main.pas:174-175` | Medium |
| A7 | A failed `AddEditorEventsNotifier` is stored as if it succeeded | `main.pas:414` | Medium |
| A8 | Message can overdraw the line below | `main.pas:172` | Low |
| A9 | Unchecked enum cast from the registry | `main.pas:390`, `Options.pas:126` | Low |
| A10 | A bad registry value can raise out of package load | `main.pas:364-400` | Low |
| B1 | No exception guard anywhere in the paint path | `main.pas` | Robustness |
| B2 | `QueryInterface` per painted line, per repaint | `main.pas:191` | Performance |
| B3 | `LoadSettings` duplicated verbatim in two units | `main.pas:346`, `Options.pas:82` | Maintenance |
| B4 | Dead code and an unused parameter | several | Tidiness |
| C1 | **Not a bug** — a ToolsAPI subtlety worth documenting | `main.pas:125` | Information |

---

## A. Defects

### A1 — The editor canvas is left with the plug-in's font, brush and pen

`main.pas:195` saves the font, and `main.pas:210` restores it — but the restore is commented
out:

```pascal
FEditorFont.assign(Canvas.Font);          // line 195
...
// Canvas.Font.Assign(FEditorFont);       // line 210  <-- commented out
```

So `FEditorFont` is written on every draw and never read, and the canvas — which belongs to the
editor, not to us — is left with our font colour, brush colour, brush style, pen colour, pen
width and pen style.

**Fix.** Save all six values before drawing and restore them in a `try..finally`. (Restoring only
the font would still leave the brush and pen changed.)

---

### A2 — Custom colours cannot be shown, and are silently overwritten on Save

The three `TColorBox` controls in `TulipErrorInline.Options.dfm` set no `Style`, so they take the
VCL default:

```
[cbStandardColors, cbExtendedColors, cbSystemColors]
```

which does **not** include `cbCustomColor`. But two of your own shipped defaults are custom
colours that appear in none of those lists:

| Setting | Default | RGB |
|---|---|---|
| Warning | `$004080FF` | 255, 128, 64 (orange) |
| Hint | `$00FF8000` | 0, 128, 255 (blue) |

So on a fresh install those colours cannot be displayed or selected. `SaveSettings` then reads
`cbxWarningFontColor.Selected` and persists whatever list entry happens to be current — quietly
replacing a colour the user never touched. I believe this is how our own registry came to hold
pure `clBlue` and `clLime`.

**Fix.** Add `cbCustomColor` to the `Style` of all three boxes:

```
Style = [cbStandardColors, cbExtendedColors, cbSystemColors, cbCustomColor]
```

**Verified:** with `WarningFontColor` set to `$004080FF`, the box then reads "Custom…" with the
correct orange swatch. Before the change it did not.

---

### A3 — Update Interval is unbounded

`Options.pas:176` guards the indent against negatives, but `Options.pas:166` does not guard the
interval, and neither `TNumberBox` sets `MinValue`/`MaxValue` in the DFM. `TCustomNumberBox`
disables clamping entirely when both are zero (`IsMinMaxActive` returns `False` when
`MinValue = MaxValue = 0`), so any value can be typed. Two consequences:

- **`0`** → `(GetTickCount - FLastUpdate) > 0` is almost always true, so `ModuleErrors.GetErrors`
  runs **per painted line, per repaint**. The editor becomes very slow.
- **A negative value** → `Trunc` into `UpdateInterval: Cardinal` wraps to roughly 49 days, so the
  diagnostics never refresh again until the file changes.

**Fix.** Clamp on save (we used 100–60,000 ms), and set `MinValue`/`MaxValue` on both number
boxes so the UI enforces it too.

---

### A4 — Blank lines inherit the previous line's width

`FCodeLineWidth` is accumulated in `PaintText` (`main.pas:293`), which never fires for a line
with no text runs. A blank line therefore anchors its message using the width of the line above
it, and the message appears in the wrong place.

Your own commented-out code at `main.pas:270-271` is exactly the right fix:

```pascal
{if  (Stage = plsBackground) then
  FCodeLineWidth := 0; }
```

**Fix.** Reset it per line at `plsBackground` — we reset to the line rect's `Left` rather than to
`0`, so the message starts at the beginning of the code area rather than at the far left of the
control. This requires `plsBackground` in `AllowedLineStages`, which you already have.

---

### A5 — `atComment` used as "the IDE background colour"

`main.pas:193`, with your own comment two lines below saying `msgbgcolor = ide background color`:

```pascal
msgbgColor := Brighten(msgtextColor, EditorServices.Options.BackgroundColor[atComment]);
```

`atComment` (= 1) is the **Comment** element, which carries its own background in many themes.
The plain editor background is `atWhiteSpace` (= 0) — see `ToolsAPI.pas:443-444`.

**Fix.** Use `BackgroundColor[atWhiteSpace]`. Your `Brighten` function itself is correct — I
checked the `ColorRGBToHLS(clrRGB; var Hue, Luminance, Saturation)` argument order and the 0–240
`HLSMAX` range, and 225/40 are both valid.

---

### A6 — Right alignment moves only the pill's right edge

`main.pas:174-175`:

```pascal
if ErrorAlign = eaRight then
    TargetRect.Right := EditorWidth - Integer(ErrorIndent);
```

`Left` is left at `FCodeLineWidth + ErrorIndent`, so the rounded rectangle stretches from the end
of the code all the way to the right margin, with the text pushed to the right inside it — a
full-width pill rather than a right-aligned one.

**Fix.** Compute the pill width, then set `Left := Right - Width`, clamped so it never starts
before the code text ends.

(`main.pas:171`, `TargetRect.Right := TargetRect.width + TargetRect.Left`, is also redundant —
assigning `TRect.Width` already moves `Right`.)

---

### A7 — A failed `AddEditorEventsNotifier` is stored as if it succeeded

`main.pas:414`:

```pascal
EventNotifierIndex := EditorServices.AddEditorEventsNotifier(GNotifier);
```

`ToolsAPI.Editor.pas:962` documents *"If &lt;0 then an error occurred"*, but every guard in the
unit tests specifically for `-1`. A failure code such as `-2` therefore leaves the plug-in
permanently wedged: `Register` refuses to retry because the index is no longer `-1`, and
`Unregister` passes the bogus index back into the IDE.

**Fix.** Treat any negative result as failure — release the notifier and leave the index at `-1`
so a later `Register` can retry.

---

### A8 — The message can overdraw the line below

`main.pas:172` sets the height to `TextHeight + 2` without clipping to the line rectangle, so on
a line whose height is tight the pill spills into the next row.

**Fix.** Clamp `Bottom` to the line rect's `Bottom`.

---

### A9 — Unchecked enum cast from the registry

`main.pas:390` and `Options.pas:126`:

```pascal
ErrorAlign := TErrorMessageAlign( Reg.ReadInteger(ERROR_ALIGN) );
```

An arbitrary integer is cast straight into a two-value enumeration. Harmless today, but it is an
invalid enum value waiting to bite under range checking.

**Fix.** Range-check against `Low`/`High` before casting.

---

### A10 — A bad registry value can raise out of package load

`LoadSettings` is called from `Register`, i.e. while the IDE is loading the design-time package.
`ReadInteger` on a value of the wrong type raises `ERegistryException`, which would surface as a
package-load failure.

**Fix.** Wrap the reads and fall back to the defaults.

---

## B. Robustness, performance and structure

**B1 — No exception guard in the paint path.** There is no `try..except` anywhere in the plug-in.
`PaintLine` runs inside the editor's paint loop, which repaints continuously, so a single access
violation becomes a dialog storm rather than one report. We absorb exceptions in the paint path
and stop drawing after 10 consecutive failures, so a persistent fault does not burn CPU on every
repaint of every line.

**B2 — `QueryInterface` per painted line.** `Supports(BorlandIDEServices, INTACodeEditorServices, …)`
at `main.pas:191` sits inside the draw routine, so it runs for every painted line on every
repaint. We resolve it once and cache it, and refresh the background colour on the same interval
as the diagnostics.

**B3 — `LoadSettings` duplicated.** The same ~55 lines appear at `main.pas:346-403` and
`Options.pas:82-137`. Two copies will drift. We moved one implementation into the shared unit and
added a matching `SaveSettings` beside it. (One trap if you do this: inside
`TTulipErrorInlineFrame.LoadSettings`, an unqualified call to `LoadSettings` resolves to the
method itself and recurses — it must be unit-qualified.)

**B4 — Dead code.** `ErrorBG` / `WarningBG` / `HintBG` are declared and never assigned;
`TInfoRec.Background` and `TErrorLineCache.index` are never read; `FEditorFont` is written and
never read (see A1). `DrawInlineErrorNew`'s `ErrorData` parameter is passed an uninitialised local
by the caller and immediately overwritten by `TryGetValue` at `main.pas:125` — it wants to be a
local variable, not a parameter.

---

## C. Not a bug — a ToolsAPI subtlety worth documenting

**This one is a correction to myself, and it is the most useful thing in this document.**

Reading the source, I concluded `main.pas:125` was wrong:

```pascal
if not FLineCache.TryGetValue(Context.EditorLineNum, ErrorData) then
```

The cache is keyed on `FErrors[I].Start.Line`, and `ToolsAPI.pas:1150` documents
`TOTACharPos.Line` as `{ Line is one-based }`. I read that as a **source** line, and
`INTACodeEditorPaintContext` offers `LogicalLineNum` alongside `EditorLineNum`, so using
`EditorLineNum` looked like a clear bug that would misplace every message below a collapsed
region. I changed it to `LogicalLineNum`.

**Testing in the running IDE proved the opposite.** With a 9-line `{$REGION}` collapsed above an
error on **source line 34**, `IOTAModuleErrors.GetErrors` reports `Start.Line` = **25** — the
error's *visible* row, not its source line. My "fix" drew every message 9 rows too high, exactly
the number of hidden lines. I reverted it.

**`TOTAError.Start.Line` is expressed in the editor's VISIBLE line space.** Your original pairing —
key on `Start.Line`, look up by `EditorLineNum` — is correct, and the two spaces coincide only
while nothing is folded, which is why the difference is invisible in a flat file. The RTL comment
never says which space it means.

**Suggestion:** a one-line comment at `main.pas:125` would save the next reader (and any future
contributor) from making exactly the change I did.

A related trap, in case it ever tempts you: `INTACodeEditorLineState.VisibleTextRect` looks like a
cleaner way to find where a line's code ends, and is not — it does not report the end of the
line's text, and using it as the anchor draws the message on top of the code. Your `PaintText`
accumulation is the right mechanism; it only needed the A4 reset.

---

## D. Fork-specific changes — **not** proposed for upstream

These suit our environment and house standards, and you should not feel any need to take them:

- **Win64 added as a target platform**, defaults set to Release/Win64, and the inherited Android,
  iOS, Linux and macOS configurations removed. The 64-bit IDE (`bin64\bds.exe`) can only load a
  Win64 design package, so we build and register both architectures.
- **Package output paths** moved to `$(BDSCOMMONDIR)\Bpl|Dcp\$(Platform)` for Release and a
  `\$(Config)` subfolder for Debug, so a Debug build cannot replace the installed package.
- **`{$DESIGNONLY}`** added to the `.dpk`. The package requires `designide`, so nothing should be
  able to take it as a runtime requirement. This one may genuinely be worth adopting upstream.
- **`DCC_CBuilderOutput`** set to `None` — we never target C++Builder.
- **`.gitignore`**: `Win32/` and `Win64/` were commented out, so build output is not actually
  ignored by the repository itself. Worth a look on your side too.
- House conventions: UTF-8 BOM on compiled Pascal source, a `CHANGELOG.md`, and User Guide /
  Help documents.

---

## E. If you would like any of this

The fork is at **https://github.com/ijbranch/gllTulip** (currently private — happy to open it up
or send patches, whichever suits).

Sections A and B are all independent of one another, so they can be taken piecemeal. If it is
easier, I am glad to raise them as individual issues, or open a PR limited to just the defect
fixes with the fork-specific changes (section D) left out. Just say which you would prefer.

I would also suggest keeping a small test unit around: a file with a diagnostic below a
collapsible `{$REGION}` is the only reliable way to catch the class of bug in section C, since
everything looks correct while the file is flat.

Thanks again for the plug-in.

— Ian Branch

---
*Version: 1.0 – 05 September 2026 18:25*
