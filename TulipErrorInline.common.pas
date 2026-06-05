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

function Brighten(AColor: TColor; aBackColor: TColor): TColor;
//procedure DoBest(var aFront, aBack: TColor);

implementation

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

  if l < bl then
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
