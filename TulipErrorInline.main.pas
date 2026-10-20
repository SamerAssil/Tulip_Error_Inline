{*******************************************************}
{                                                       }
{             TULIP ERROR INLINE PLUGIN                 }
{                                                       }
{               Samer Assil - 2026                      }
{                                                       }
{              samerassil@gmail.com                     }
{          https://github.com/SAMERASSIL                }
{                                                       }
{*******************************************************}

unit TulipErrorInline.main;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Win.Registry, Vcl.Graphics, Winapi.Windows,
  Vcl.Controls, System.StrUtils, Vcl.Forms, Vcl.Dialogs, System.Math, System.Generics.Collections,
  Vcl.GraphUtil,
  ToolsAPI, ToolsAPI.Editor, TulipErrorInline.common;

type

  TTulipErrorInline = class(TNotifierObject, INTACodeEditorEvents)
  private
    FErrors: TOTAErrors;
    FLastFile: string;
    FLastUpdate: UInt64;
    FCodeLineWidth: Integer;
    FPaintErrorCount: Integer;
    FEditorServices: INTACodeEditorServices;
    FEditorBgColor: TColor;
    FLineCache: TDictionary<Integer, TErrorLineCache>;
    procedure UpdateErrors(const Buffer: IOTAEditBuffer);
    procedure DrawInlineErrorNew(const Rect: TRect; const Context: INTACodeEditorPaintContext);

    procedure EditorScrolled(const Editor: TWinControl; const Direction: TCodeEditorScrollDirection);
    procedure EditorResized(const Editor: TWinControl);
    procedure EditorElided(const Editor: TWinControl; const LogicalLineNum: Integer);
    procedure EditorUnElided(const Editor: TWinControl; const LogicalLineNum: Integer);
    procedure EditorMouseDown(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure EditorMouseMove(const Editor: TWinControl; Shift: TShiftState; X, Y: Integer);
    procedure EditorMouseUp(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BeginPaint(const Editor: TWinControl; const ForceFullRepaint: Boolean);
    procedure EndPaint(const Editor: TWinControl);
    procedure PaintGutter(const Rect: TRect; const Stage: TPaintGutterStage; const BeforeEvent: Boolean;
        var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);

    procedure PaintLine(const Rect: TRect; const Stage: TPaintLineStage; const BeforeEvent: Boolean;
        var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);

    procedure PaintText(const Rect: TRect; const ColNum: SmallInt; const Text: string; const SyntaxCode: TOTASyntaxCode;
        const Hilight, BeforeEvent: Boolean; var AllowDefaultPainting: Boolean;
        const Context: INTACodeEditorPaintContext);

    function AllowedEvents: TCodeEditorEvents;
    function AllowedGutterStages: TPaintGutterStages;
    function AllowedLineStages: TPaintLineStages;
    function UIOptions: TCodeEditorUIOptions;
  public
    constructor Create;
    destructor Destroy; override;
  end;


procedure LoadSettings;
procedure Register;
procedure Unregister;

var
  EventNotifierIndex: Integer = -1;
  GNotifier: INTACodeEditorEvents;

implementation

uses TulipErrorInline.consts;

{ TTulipErrorInline }

function TTulipErrorInline.AllowedEvents: TCodeEditorEvents;
begin
  Result := [cevPaintTextEvents, cevPaintLineEvents];
end;

function TTulipErrorInline.AllowedGutterStages: TPaintGutterStages;
begin
  Result := [];
end;

function TTulipErrorInline.AllowedLineStages: TPaintLineStages;
begin
  Result := [plsBackground, plsEndPaint];
end;

procedure TTulipErrorInline.BeginPaint(const Editor: TWinControl; const ForceFullRepaint: Boolean);
begin

end;

constructor TTulipErrorInline.Create;
begin
  inherited Create;
  LoadSettings;
  FLineCache := TDictionary<Integer, TErrorLineCache>.Create;
  if Supports(BorlandIDEServices, INTACodeEditorServices, FEditorServices) and
     Assigned(FEditorServices.Options) then
    FEditorBgColor := FEditorServices.Options.BackgroundColor[atWhiteSpace]
  else
    FEditorBgColor := clWhite;
end;

destructor TTulipErrorInline.Destroy;
begin
  FEditorServices := nil;
  FLineCache.Free;
  inherited Destroy;
end;

procedure TTulipErrorInline.DrawInlineErrorNew(const Rect: TRect; const Context: INTACodeEditorPaintContext);
var
  Canvas: TCanvas;
  EditorWidth: Integer;
  TargetRect: TRect;
  TextRect: TRect;
  msgtextColor: TColor;
  msgbgColor: TColor;
  ErrorData: TErrorLineCache;
  TextW, TextH: Integer;
  SavedDC: Integer;
  DrawFlags: Cardinal;
begin
  if not FLineCache.TryGetValue(Context.EditorLineNum, ErrorData) then
    Exit;

  if ErrorData.Text.IsEmpty then
    Exit;

  case ErrorData.Severity of
    1: if not ErrorInfo.Enabled then Exit;
    2: if not WarningInfo.Enabled then Exit;
    3, 4: if not HintInfo.Enabled then Exit;
  else
    Exit;
  end;

  case ErrorData.Severity of
    1:  msgtextColor := ErrorInfo.Color;
    2:  msgtextColor := WarningInfo.Color;
    3, 4: msgtextColor := HintInfo.Color;
  else
    msgtextColor := clBlack;
  end;

  Canvas := Context.Canvas;
  if Canvas = nil then
    Exit;

  if Assigned(Context.EditControl) then
    EditorWidth := Context.EditControl.ClientWidth
  else
    EditorWidth := 4000;

  msgbgColor := Brighten(msgtextColor, FEditorBgColor);

  SavedDC := SaveDC(Canvas.Handle);
  try
    Canvas.Font.Color := msgtextColor;

    TextW := Canvas.TextWidth(ErrorData.Text) + 20;
    TextH := Canvas.TextHeight(ErrorData.Text) + 2;

    // Vertically center inside the line cell
    TargetRect.Top := Rect.Top + (Rect.Height - TextH) div 2;
    TargetRect.Bottom := TargetRect.Top + TextH;

    if TargetRect.Top < Rect.Top then
      TargetRect.Top := Rect.Top;
    if TargetRect.Bottom > Rect.Bottom then
      TargetRect.Bottom := Rect.Bottom;

    if ErrorAlign = eaRight then
    begin
      TargetRect.Right := EditorWidth - Integer(ErrorIndent);
      TargetRect.Left := TargetRect.Right - TextW;
      if TargetRect.Left < FCodeLineWidth + 10 then
      begin
        TargetRect.Left := FCodeLineWidth + 10;
        TargetRect.Right := TargetRect.Left + TextW;
      end;
    end
    else
    begin
      TargetRect.Left := FCodeLineWidth + Integer(ErrorIndent);
      TargetRect.Right := TargetRect.Left + TextW;
    end;

    Canvas.Brush.Color := msgbgColor;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := msgtextColor;
    Canvas.Pen.Width := 1;
    Canvas.Pen.Style := psSolid;
    Canvas.RoundRect(TargetRect, 12, 12);

    TextRect := TargetRect;
    TextRect.Left := TextRect.Left + 10;
    TextRect.Right := TextRect.Right - 10;

    DrawFlags := DT_NOPREFIX or DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
    if ErrorAlign = eaRight then
      DrawFlags := DrawFlags or DT_RIGHT
    else
      DrawFlags := DrawFlags or DT_LEFT;

    Canvas.Brush.Style := bsClear;
    Winapi.Windows.DrawText(Canvas.Handle, PChar(ErrorData.Text), -1, TextRect, DrawFlags);
  finally
    RestoreDC(Canvas.Handle, SavedDC);
  end;
end;

procedure TTulipErrorInline.EditorElided(const Editor: TWinControl; const LogicalLineNum: Integer);
begin

end;

procedure TTulipErrorInline.EditorMouseDown(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState;
    X, Y: Integer);
begin

end;

procedure TTulipErrorInline.EditorMouseMove(const Editor: TWinControl; Shift: TShiftState; X, Y: Integer);
begin

end;

procedure TTulipErrorInline.EditorMouseUp(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState;
    X, Y: Integer);
begin

end;

procedure TTulipErrorInline.EditorResized(const Editor: TWinControl);
begin

end;

procedure TTulipErrorInline.EditorScrolled(const Editor: TWinControl; const Direction: TCodeEditorScrollDirection);
begin

end;

procedure TTulipErrorInline.EditorUnElided(const Editor: TWinControl; const LogicalLineNum: Integer);
begin

end;

procedure TTulipErrorInline.EndPaint(const Editor: TWinControl);
begin

end;

procedure TTulipErrorInline.PaintGutter(const Rect: TRect; const Stage: TPaintGutterStage; const BeforeEvent: Boolean;
    var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);
begin

end;

procedure TTulipErrorInline.PaintLine(const Rect: TRect; const Stage: TPaintLineStage; const BeforeEvent: Boolean;
    var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);
var
  View: IOTAEditView;
begin
  if FPaintErrorCount > 10 then
    Exit;

  try
    if Stage = plsBackground then
      FCodeLineWidth := Rect.Left;

    if (Stage = plsEndPaint) and not BeforeEvent then
    begin
      View := Context.EditView;
      if (View = nil) or (View.Buffer = nil) then
        Exit;

      UpdateErrors(View.Buffer);

      if Length(FErrors) = 0 then
        Exit;

      DrawInlineErrorNew(Rect, Context);
      FPaintErrorCount := 0;
    end;
  except
    Inc(FPaintErrorCount);
  end;
end;

procedure TTulipErrorInline.PaintText(const Rect: TRect; const ColNum: SmallInt; const Text: string;
    const SyntaxCode: TOTASyntaxCode; const Hilight, BeforeEvent: Boolean; var AllowDefaultPainting: Boolean;
    const Context: INTACodeEditorPaintContext);
begin
  if Rect.Right > FCodeLineWidth then
    FCodeLineWidth := Rect.Right;
end;

function TTulipErrorInline.UIOptions: TCodeEditorUIOptions;
begin
  Result := [];
end;

procedure TTulipErrorInline.UpdateErrors(const Buffer: IOTAEditBuffer);
var
  Module: IOTAModule;
  ModuleErrors: IOTAModuleErrors;
  LCache: TErrorLineCache;
  CurrentTick: UInt64;
begin
  if Buffer = nil then
  begin
    SetLength(FErrors, 0);
    FLineCache.Clear;
    Exit;
  end;

  CurrentTick := GetTickCount64;
  if (Buffer.FileName <> FLastFile) or ((CurrentTick - FLastUpdate) > UpdateInterval) then
  begin
    FLastFile := Buffer.FileName;
    FLastUpdate := CurrentTick;

    if FEditorServices = nil then
      Supports(BorlandIDEServices, INTACodeEditorServices, FEditorServices);
    if (FEditorServices <> nil) and Assigned(FEditorServices.Options) then
      FEditorBgColor := FEditorServices.Options.BackgroundColor[atWhiteSpace];

    Module := Buffer.Module;
    if (Module <> nil) and Supports(Module, IOTAModuleErrors, ModuleErrors) then
    begin
      FErrors := ModuleErrors.GetErrors(Buffer.FileName);
      FLineCache.Clear;
      for var I := Low(FErrors) to High(FErrors) do
      begin
        if FLineCache.TryGetValue(FErrors[I].Start.Line, LCache) then
        begin
          LCache.Text := LCache.Text + ' • ' + FErrors[I].Text.Trim;
          if FErrors[I].Severity < LCache.Severity then
            LCache.Severity := FErrors[I].Severity;
        end
        else
        begin
          LCache.Text := FErrors[I].Text.Trim;
          LCache.Severity := FErrors[I].Severity;
        end;
        FLineCache.AddOrSetValue(FErrors[I].Start.Line, LCache);
      end;
    end
    else
    begin
      SetLength(FErrors, 0);
      FLineCache.Clear;
    end;
  end;
end;

procedure LoadSettings;
begin
  TulipErrorInline.common.LoadSettings;
end;

procedure Register;
var
  EditorServices: INTACodeEditorServices;
begin
  LoadSettings;
  if Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then
  begin
    if EventNotifierIndex = -1 then
    begin
      GNotifier := TTulipErrorInline.Create;
      EventNotifierIndex := EditorServices.AddEditorEventsNotifier(GNotifier);
      if EventNotifierIndex < 0 then
      begin
        GNotifier := nil;
        EventNotifierIndex := -1;
      end;
    end;
  end;
end;

procedure Unregister;
var
  EditorServices: INTACodeEditorServices;
begin
  if EventNotifierIndex >= 0 then
  begin
    if Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then
      EditorServices.RemoveEditorEventsNotifier(EventNotifierIndex);

    GNotifier := nil;
    EventNotifierIndex := -1;
  end;
end;

initialization

finalization
  Unregister;
end.
