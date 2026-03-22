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
  vcl.controls, System.StrUtils, vcl.Forms, vcl.dialogs, System.Math, System.Generics.Collections,
  ToolsAPI, ToolsAPI.Editor;

Type

  TErrorLineCache = record
    Text: string;
    Severity: Integer;
  end;

  TTulipErrorInline = class(TNotifierObject, INTACodeEditorEvents)
  private
    FErrors: TOTAErrors;
    FLastFile: string;
    FLastUpdate: Cardinal;
    FEditorFont: TFont;
    FCodeLineWidth: integer;
    FLineCache: TDictionary<Integer, TErrorLineCache>;
    procedure UpdateErrors(const Buffer: IOTAEditBuffer);
    procedure DrawInlineError(const Rect: TRect; const Context: INTACodeEditorPaintContext);


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
  EventNotifierIndex: integer = -1;
  GNotifier: INTACodeEditorEvents;


implementation

{ TTulipErrorInline }

uses TulipErrorInline.consts, TulipErrorInline.Options;

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
  FEditorFont := TFont.Create;
  FLineCache := TDictionary<Integer, TErrorLineCache>.Create;
end;

destructor TTulipErrorInline.Destroy;
begin
  FLineCache.Free;
  FEditorFont.Free;
  inherited Destroy;
end;

procedure TTulipErrorInline.DrawInlineError(const Rect: TRect; const Context: INTACodeEditorPaintContext);
var
  View: IOTAEditView;
  ErrorText: string;
  Canvas: TCanvas;
  EditorWidth: Integer;
  Severity: Integer;
  TargetRect: TRect;
  msgtextColor: Tcolor;
  msgbgColor: Tcolor;
  ErrorData: TErrorLineCache;

begin

  View := Context.EditView;
  if (View = nil) or (View.Buffer = nil) then
    Exit;

  UpdateErrors(View.Buffer);

  if Length(FErrors) = 0 then
    Exit;

  if not FLineCache.TryGetValue(Context.EditorLineNum, ErrorData) then
    Exit;

  ErrorText := ErrorData.Text;
  Severity := ErrorData.Severity;


  case Severity of
  1: if not ErrorInfo.Enabled then exit;
  2: if not WarningInfo.Enabled then exit;
  3: if not HintInfo.Enabled then exit;
  else
    exit;
  end;


  if ErrorText <> '' then begin
    Canvas := Context.Canvas;
  Canvas.Brush.Style := bsClear;
  FEditorFont.assign(Canvas.Font);

    msgbgColor := clNone;
    Canvas.Font.Style := [fsItalic, TFontStyle.fsBold];
    case Severity of
      1:  msgtextColor := ErrorInfo.color; //clRed; //clMaroon;
      2:  msgtextColor := WarningInfo.color;// $004080FF; // Warning (Orange)
      3:  msgtextColor := HintInfo.color; //$00FF8000; // Hint (Blue)
      else
        begin
          msgtextColor := clBlack;
          msgbgColor := clblack;
        end;
    end;

    if Assigned(Context.EditControl) then
      EditorWidth := Context.EditControl.ClientWidth
    else
      EditorWidth := 4000;

    TargetRect := Rect;

    var errorLineWidth: integer;
    errorLineWidth := canvas.TextWidth(pchar(ErrorText)) + 20;
    TargetRect.width := errorLineWidth;
//    TargetRect.Left := EditorWidth - errorLineWidth;
    TargetRect.Right := EditorWidth;
    TargetRect.height := canvas.TextHeight(pchar(ErrorText));

//    if ErrorAlign = eaLeft then
    if ErrorAlign = eaLeft then
      TargetRect.Left := FCodeLineWidth + Integer(ErrorIndent)
      else
        TargetRect.Right := EditorWidth - Integer(ErrorIndent);


//    else
//      TargetRect.Left := EditorWidth - errorLineWidth;

    canvas.font.color := msgtextColor;
    canvas.Brush.color := msgbgColor;

    if msgbgColor = clNone then
      Canvas.Brush.Style := bsClear
    else
      Canvas.Brush.Style := bsSolid;

    canvas.FillRect(TargetRect);

    var DrawFlags := DT_NOPREFIX or DT_WORDBREAK or DT_EDITCONTROL or DT_END_ELLIPSIS;

    if ErrorAlign = eaLeft then
      DrawFlags := DrawFlags or DT_LEFT
      else
        DrawFlags := DrawFlags or DT_RIGHT ;

    Winapi.Windows.DrawText(Canvas.Handle, PChar(ErrorText), -1, TargetRect, DrawFlags);
    Canvas.Font.Assign(FEditorFont);
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
begin

  {if  (Stage = plsBackground) then
    FCodeLineWidth := 0; }

  if (Stage = plsEndPaint) and not BeforeEvent then
    DrawInlineError(Rect, Context);
end;

procedure TTulipErrorInline.PaintText(const Rect: TRect; const ColNum: SmallInt; const Text: string;
    const SyntaxCode: TOTASyntaxCode; const Hilight, BeforeEvent: Boolean; var AllowDefaultPainting: Boolean;
    const Context: INTACodeEditorPaintContext);
begin
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
begin
  if Buffer = nil then
  begin
     SetLength(FErrors, 0);
     FLineCache.Clear;
     Exit;
  end;

  if (Buffer.FileName <> FLastFile) or ((GetTickCount - FLastUpdate) > UpdateInterval ) then begin
    FLastFile := Buffer.FileName;
    FLastUpdate := GetTickCount;
    Module := Buffer.Module;
    if (Module <> nil) and Supports(Module, IOTAModuleErrors, ModuleErrors) then begin
      FErrors := ModuleErrors.GetErrors(Buffer.FileName);
      FLineCache.Clear;
      for var I := Low(FErrors) to High(FErrors) do begin
        if FLineCache.TryGetValue(FErrors[I].Start.Line, LCache) then begin
          LCache.Text := LCache.Text + ' • ' + FErrors[I].Text.Trim;
          if FErrors[I].Severity < LCache.Severity then
            LCache.Severity := FErrors[I].Severity;
        end
        else begin
          LCache.Text := FErrors[I].Text.Trim;
          LCache.Severity := FErrors[I].Severity;
        end;
        FLineCache.AddOrSetValue(FErrors[I].Start.Line, LCache);
      end
    end
    else
    begin
      SetLength(FErrors, 0);
      FLineCache.Clear;
    end;
  end;

end;

procedure LoadSettings;
var
  Reg: TRegistry;
begin
  // Errors
  ErrorInfo.color := clred;
  ErrorInfo.Enabled := True;
  //Warning
  WarningInfo.color := $004080FF;
  WarningInfo.Enabled := true;
  //Hint
  HintInfo.Color := $00FF8000;
  HintInfo.Enabled := true;

  UpdateInterval := 1000;
  ErrorAlign := eaLeft;
  ErrorIndent := 40;

  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly(REG_KEY) then
    begin
      // Error
      if Reg.ValueExists(FONT_COLOR_ERROR) then
        ErrorInfo.Color := TColor(Reg.ReadInteger(FONT_COLOR_ERROR));
      if Reg.ValueExists(ENABLED_ERROR) then
        ErrorInfo.Enabled := Reg.ReadBool(ENABLED_ERROR);
      // Warning
      if Reg.ValueExists(FONT_COLOR_WARNING) then
        WarningInfo.Color := TColor(Reg.ReadInteger(FONT_COLOR_WARNING));
      if Reg.ValueExists(ENABLED_WARNING) then
        WarningInfo.Enabled := Reg.ReadBool(ENABLED_WARNING);
      // Hint
      if Reg.ValueExists(FONT_COLOR_HINT) then
        HintInfo.Color := TColor(Reg.ReadInteger(FONT_COLOR_HINT));
      if Reg.ValueExists(ENABLED_HINT) then
        HintInfo.Enabled := Reg.ReadBool(ENABLED_HINT);

      // update interval
      if Reg.ValueExists(UPDATE_INTERVAL) then
        UpdateInterval := Reg.ReadInteger(UPDATE_INTERVAL);

      if Reg.ValueExists(ERROR_ALIGN) then
        ErrorAlign := TErrorMessageAlign( Reg.ReadInteger(ERROR_ALIGN) );

      if Reg.ValueExists(ERROR_INDENT) then
        ErrorIndent := Reg.ReadInteger(ERROR_INDENT);

      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;


procedure Register;
var
  EditorServices: INTACodeEditorServices;
begin
  LoadSettings;
  if Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then begin
    if EventNotifierIndex = -1 then begin
      GNotifier := TTulipErrorInline.Create;
      EventNotifierIndex := EditorServices.AddEditorEventsNotifier(GNotifier);
    end;
  end;
end;

procedure Unregister;
var
  EditorServices: INTACodeEditorServices;
begin
  if EventNotifierIndex <> -1 then begin
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
