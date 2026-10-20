unit TulipErrorInline.common;

interface
uses
  System.SysUtils, System.Win.Registry, System.UITypes, vcl.GraphUtil, Vcl.Graphics, Winapi.Windows, Vcl.Themes, ToolsAPI;
Type

  TErrorMessageAlign = (eaLeft = 0, eaRight = 1);

  TErrorLineCache = record
    index: integer;
    Text: string;
    Severity: Integer;
  end;

  TInfoRec = Record
    Color: TColor;
    Background: TColor;
    Enabled: Boolean;
  End;

var
  ErrorBG, WarningBG, HintBG: TColor;
  ErrorInfo: TInfoRec;
  WarningInfo: TInfoRec;
  HintInfo: TInfoRec;

  UpdateInterval: Cardinal;
  ErrorAlign: TErrorMessageAlign;
  ErrorIndent: Cardinal;

procedure LoadSettings;
function Brighten(AColor: TColor; aBackColor: TColor): TColor;
//procedure DoBest(var aFront, aBack: TColor);

implementation

uses
  TulipErrorInline.consts;

procedure LoadSettings;
var
  Reg: TRegistry;
begin
  // Errors
  ErrorInfo.Color := clRed;
  ErrorInfo.Enabled := True;
  // Warning
  WarningInfo.Color := $004080FF;
  WarningInfo.Enabled := True;
  // Hint
  HintInfo.Color := $00FF8000;
  HintInfo.Enabled := True;

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
        ErrorAlign := TErrorMessageAlign(Reg.ReadInteger(ERROR_ALIGN));

      if Reg.ValueExists(ERROR_INDENT) then
        ErrorIndent := Reg.ReadInteger(ERROR_INDENT);

      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

function Brighten(AColor: TColor; aBackColor: TColor): TColor;
var
  H, S, L  : Word;
  bH, bS, bL : Word;
  NewL: Integer;
  ActualColor, b: TColor;
begin
  ActualColor := ColorToRGB(AColor);
  ColorRGBToHLS(ActualColor, H, L, S);

  b := ColorToRGB(aBackColor);
  ColorRGBToHLS(b, bH, bL, bS);

  if bL > 128 then
    NewL := 225
  else
    NewL := 40;

  Result := ColorHLSToRGB(H, NewL, S);
end;

//
//procedure DoBest(var aFront, aBack: TColor);
//var
//  H, S: Word;
//  f, b, tmp: TColor;
//  fL, bL: Word;
//begin
//  f := ColorToRGB(aFront);
//  b := ColorToRGB(aBack);
//  ColorRGBToHLS(f, H, fL, S);
//  ColorRGBToHLS(b, H, bL, S);
//
//  tmp := aFront;
//  if fL < bL then
//    begin
//    aFront := aBack;
//    aBack := tmp;
//    end;
//
//end;

end.
