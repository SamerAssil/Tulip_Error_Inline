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

unit TulipErrorInline.Options;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.StrUtils, System.win.Registry, ToolsAPI,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.NumberBox, Vcl.ComCtrls,
  Vcl.WinXCtrls;

type
  TTulipErrorInlineFrame = class(TFrame)
    GroupBox1: TGroupBox;
    cbxErrorFontColor: TColorBox;
    cbErrorEnabled: TCheckBox;
    GroupBox2: TGroupBox;
    cbxWarningFontColor: TColorBox;
    cbWarningEnabled: TCheckBox;
    GroupBox3: TGroupBox;
    cbxHintFontColor: TColorBox;
    cbHintEnabled: TCheckBox;
    cbErrorAlign: TComboBox;
    edtUpdateInterval: TNumberBox;
    Label5: TLabel;
    Label6: TLabel;
    edtIndent: TNumberBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
  private
    { Private declarations }
  public
    procedure SaveSettings;
    procedure LoadSettings;
  end;


type
  TInfoRec = Record
    Color: TColor;
    Enabled: Boolean;
  End;

  TErrorMessageAlign = (eaLeft = 0, eaRight = 1);

  TTulipErrorInlineAddInOptions = class(TInterfacedObject, INTAAddInOptions)
  private
    FFrame: TTulipErrorInlineFrame;
  public
    function GetArea: string;
    function GetCaption: string;
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    procedure DialogClosed(Accepted: Boolean);
    function ValidateContents: Boolean;
    function GetHelpContext: Integer;
    function IncludeInIDEInsight: Boolean;
  end;

var
  ErrorInlineOptionsIndex: INTAAddInOptions = nil;

  ErrorInfo: TInfoRec;
  WarningInfo: TInfoRec;
  HintInfo: TInfoRec;

  UpdateInterval: Cardinal;
  ErrorAlign: TErrorMessageAlign;
  ErrorIndent: Cardinal;

procedure Register;
procedure UnRegister;

implementation

{$R *.dfm}

uses TulipErrorInline.consts;

{ TTulipErrorInlineFrame }


procedure TTulipErrorInlineFrame.LoadSettings;
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
  ErrorIndent := 40;
  ErrorAlign := eaLeft;

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

procedure TTulipErrorInlineFrame.SaveSettings;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(REG_KEY, True) then
    begin
      ErrorInfo.color := cbxErrorFontColor.Selected;
      Reg.WriteInteger( FONT_COLOR_ERROR, Integer(ErrorInfo.Color));

      ErrorInfo.enabled := cbErrorEnabled.checked;
      Reg.WriteBool( ENABLED_ERROR, ErrorInfo.Enabled);

      WarningInfo.color := cbxWarningFontColor.Selected;
      Reg.WriteInteger(FONT_COLOR_WARNING, Integer(WarningInfo.Color));

      WarningInfo.enabled := cbWarningEnabled.checked;
      Reg.WriteBool( ENABLED_WARNING, WarningInfo.Enabled);

      HintInfo.color := cbxHintFontColor.Selected;
      Reg.WriteInteger(FONT_COLOR_HINT, Integer(HintInfo.Color));

      HintInfo.enabled := cbHintEnabled.checked;
      Reg.WriteBool( ENABLED_HINT, HintInfo.Enabled);

      UpdateInterval := Trunc(edtUpdateInterval.Value);
      Reg.WriteInteger(UPDATE_INTERVAL, UpdateInterval);

      if cbErrorAlign.ItemIndex <> -1 then
        ErrorAlign := TErrorMessageAlign(cbErrorAlign.ItemIndex)
        else
          ErrorAlign := eaLeft;

      Reg.WriteInteger(ERROR_ALIGN, cbErrorAlign.itemindex);

      if edtIndent.Value < 0 then
        edtIndent.Value := 0;
      ErrorIndent := Trunc(edtIndent.Value);
      Reg.WriteInteger(ERROR_INDENT, ErrorIndent);

      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;


{ TTulipErrorInlineAddInOptions }

procedure TTulipErrorInlineAddInOptions.DialogClosed(Accepted: Boolean);
begin
  if Accepted then
    FFrame.SaveSettings;
  FFrame := nil;
end;

procedure TTulipErrorInlineAddInOptions.FrameCreated(AFrame: TCustomFrame);
begin
  FFrame := TTulipErrorInlineFrame(AFrame);
  try
  if Assigned(FFrame) then
    begin
    FFrame.LoadSettings;
    FFrame.cbxErrorFontColor.Selected := ErrorInfo.Color;
    FFrame.cbErrorEnabled.checked := ErrorInfo.enabled;

    FFrame.cbxWarningFontColor.Selected := WarningInfo.Color;
    FFrame.cbWarningEnabled.checked := WarningInfo.enabled;

    FFrame.cbxHintFontColor.Selected := HintInfo.Color;
    FFrame.cbHintEnabled.checked := HintInfo.enabled;

    FFrame.edtUpdateInterval.Value := UpdateInterval;
    FFrame.edtIndent.Value := ErrorIndent;
    FFrame.cbErrorAlign.ItemIndex := Ord(ErrorAlign);
    end;
  finally

  end;
end;

function TTulipErrorInlineAddInOptions.GetArea: string;
begin
  Result := '';
end;

function TTulipErrorInlineAddInOptions.GetCaption: string;
begin
  result := 'Tulip Error Inline';
end;

function TTulipErrorInlineAddInOptions.GetFrameClass: TCustomFrameClass;
begin
  result := TTulipErrorInlineFrame;
end;

function TTulipErrorInlineAddInOptions.GetHelpContext: Integer;
begin
  result := 0;
end;

function TTulipErrorInlineAddInOptions.IncludeInIDEInsight: Boolean;
begin
  result := true;
end;

function TTulipErrorInlineAddInOptions.ValidateContents: Boolean;
begin
  result := true;
end;


procedure Register;
var
  EnvironmentOptions: INTAEnvironmentOptionsServices;
begin
  if Supports(BorlandIDEServices, INTAEnvironmentOptionsServices, EnvironmentOptions) then
  begin
  if ErrorInlineOptionsIndex = nil then
    begin
    ErrorInlineOptionsIndex := TTulipErrorInlineAddInOptions.Create;
    EnvironmentOptions.RegisterAddInOptions(ErrorInlineOptionsIndex);
    end;
  end;
end;


procedure UnRegister;
var
  EnvironmentOptions: INTAEnvironmentOptionsServices;
begin
  if (ErrorInlineOptionsIndex <> nil) and
     Supports(BorlandIDEServices, INTAEnvironmentOptionsServices, EnvironmentOptions) then
  begin
    EnvironmentOptions.UnregisterAddInOptions(ErrorInlineOptionsIndex);
    ErrorInlineOptionsIndex := nil;
  end;

end;

initialization

finalization
  UnRegister;

end.
