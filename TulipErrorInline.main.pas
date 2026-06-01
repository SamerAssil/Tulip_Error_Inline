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
  Vcl.GraphUtil,
  ToolsAPI, ToolsAPI.Editor, TulipErrorInline.common;

Type

  TTulipErrorInline = class(TNotifierObject, INTACodeEditorEvents)
  private

    FErrors: TOTAErrors;
    FLastFile: string;
    FLastUpdate: Cardinal;
    FEditorFont: TFont;
    FCodeLineWidth: integer;
    FLineCache: TDictionary<Integer, TErrorLineCache>;
    procedure UpdateErrors(const Buffer: IOTAEditBuffer);
    procedure DrawInlineErrorNew(const Rect: TRect; const Context: INTACodeEditorPaintContext;  ErrorData: TErrorLineCache);

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
  FEditorFont := TFont.Create;
  FLineCache := TDictionary<Integer, TErrorLineCache>.Create;
end;

destructor TTulipErrorInline.Destroy;
begin
  FLineCache.Free;
  FEditorFont.Free;
  inherited Destroy;
end;


procedure TTulipErrorInline.DrawInlineErrorNew(const Rect: TRect; const Context: INTACodeEditorPaintContext; ErrorData: TErrorLineCache);
var
  Canvas: TCanvas;
  EditorWidth: Integer;
  TargetRect: TRect;
  msgtextColor: Tcolor;
  msgbgColor: Tcolor;
begin
    if not FLineCache.TryGetValue(Context.EditorLineNum, ErrorData) then
      Exit;

  if ErrorData.Text.IsEmpty then
    exit;

//  ErrorText := ErrorData.Text;
//  Severity := ErrorData.Severity;

  case ErrorData.Severity of
    1: if not ErrorInfo.Enabled then exit;
    2: if not WarningInfo.Enabled then exit;
    3: if not HintInfo.Enabled then exit;
  else
   exit;
  end;

  case ErrorData.Severity of
    1:  begin
          msgtextColor := ErrorInfo.color;
          msgbgColor := ErrorBG;
          end;
    2:  begin
          msgtextColor := WarningInfo.color;
          msgbgColor := WarningBG;
          end;
    3:  begin
          msgtextColor := HintInfo.color;
          msgbgColor := HintBG;
        end;
    else
          msgtextColor := clblack;
          msgbgColor := clblack;
    end;


    Canvas := Context.Canvas;

    if Assigned(Context.EditControl) then
      EditorWidth := Context.EditControl.ClientWidth
    else
      EditorWidth := 4000;

    TargetRect := Rect;
    TargetRect.Left := FCodeLineWidth + Integer(ErrorIndent);
    TargetRect.width := canvas.TextWidth(pchar(ErrorData.Text)) + 20;
    TargetRect.Right := TargetRect.width + TargetRect.Left ;
    TargetRect.height := canvas.TextHeight(pchar(ErrorData.Text)) + 2;

    if ErrorAlign = eaRight then
        TargetRect.Right := EditorWidth - Integer(ErrorIndent);

    var DrawFlags := DT_NOPREFIX or DT_WORDBREAK or DT_EDITCONTROL or DT_END_ELLIPSIS;

    if ErrorAlign = eaLeft then
      DrawFlags := DrawFlags or DT_LEFT
      else
        DrawFlags := DrawFlags or DT_RIGHT ;

    if TargetRect.Width > EditorWidth - FCodeLineWidth then
      DrawFlags := DrawFlags or DT_LEFT;


     // CalculateErrorDrawingColors(msgtextColor, Context.Canvas.Brush.Color, msgbgColor, msgtextColor);
     // msgbgcolor = ide background color
     msgbgColor := Brighten(msgtextColor, Canvas.Brush.Color);
     FEditorFont.assign(Canvas.Font);

      canvas.font.color := msgtextColor;
      canvas.Brush.color := msgbgColor;// msgbgColor;
      canvas.Brush.Style := bsSolid;
      canvas.pen.Color := msgtextColor;
      canvas.pen.Width := 1;
      canvas.Pen.Style := psSolid;
      canvas.RoundRect(TargetRect, 12,12);


      TargetRect.Left := TargetRect.Left + 10;

      canvas.Brush.Style := bsClear;
    Winapi.Windows.DrawText(Canvas.Handle, PChar(ErrorData.Text), -1, TargetRect ,  DrawFlags);
   // Canvas.Font.Assign(FEditorFont);
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
    ErrorData: TErrorLineCache;
begin
  {if  (Stage = plsBackground) then
    FCodeLineWidth := 0; }
  if (Stage = plsEndPaint) and not BeforeEvent then
   // DrawInlineError(Rect, Context);
  begin
    View := Context.EditView;
    if (View = nil) or (View.Buffer = nil) then
      Exit;

    UpdateErrors(View.Buffer);

    if Length(FErrors) = 0 then
      Exit;


    DrawInlineErrorNew(Rect, Context, errorData)
  end;
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
        begin
          if FLineCache.TryGetValue(FErrors[I].Start.Line, LCache) then begin
            LCache.Text := LCache.Text + ' • ' + FErrors[I].Text.Trim;
            if FErrors[I].Severity < LCache.Severity then
              LCache.Severity := FErrors[I].Severity;
          end
          else begin
            LCache.Text := FErrors[I].Text.Trim;
            LCache.Severity := FErrors[I].Severity;
          end;
          LCache.index := I;
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
