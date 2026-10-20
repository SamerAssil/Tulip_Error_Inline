unit TulipErrorInline.common;

interface
uses
  System.SysUtils, System.Win.Registry, System.UITypes, System.Math, vcl.GraphUtil, Vcl.Graphics, Winapi.Windows, Vcl.Themes, ToolsAPI;
Type

  TErrorMessageAlign = (eaLeft = 0, eaRight = 1);

  TErrorLineCache = record
    Text: string;
    Severity: Integer;
  end;

  TInfoRec = Record
    Color: TColor;
    Enabled: Boolean;
  End;

var
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

  try
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
          UpdateInterval := EnsureRange(Reg.ReadInteger(UPDATE_INTERVAL), 100, 60000);

        if Reg.ValueExists(ERROR_ALIGN) then
        begin
          var AlignVal := Reg.ReadInteger(ERROR_ALIGN);
          if (AlignVal >= Ord(Low(TErrorMessageAlign))) and (AlignVal <= Ord(High(TErrorMessageAlign))) then
            ErrorAlign := TErrorMessageAlign(AlignVal)
          else
            ErrorAlign := eaLeft;
        end;

        if Reg.ValueExists(ERROR_INDENT) then
          ErrorIndent := EnsureRange(Reg.ReadInteger(ERROR_INDENT), 0, 500);

        Reg.CloseKey;
      end;
    finally
      Reg.Free;
    end;
  except
    // Keep safe defaults if registry is corrupted or raises ERegistryException
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

end.
