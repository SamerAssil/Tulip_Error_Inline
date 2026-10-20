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
  System.StrUtils, System.win.Registry, System.Math, ToolsAPI,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.NumberBox, Vcl.ComCtrls,
  Vcl.WinXCtrls, TulipErrorInline.common;

type
  TTulipErrorInlineFrame = class(TFrame)
    GroupBox1: TGroupBox;
    cbxErrorFontColor: TColorBox;
    cbErrorEnabled: TCheckBox;
    cbxWarningFontColor: TColorBox;
    cbWarningEnabled: TCheckBox;
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




procedure Register;
procedure UnRegister;

implementation

{$R *.dfm}

uses TulipErrorInline.consts;

{ TTulipErrorInlineFrame }


procedure TTulipErrorInlineFrame.LoadSettings;
begin
  TulipErrorInline.common.LoadSettings;
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

      UpdateInterval := EnsureRange(Trunc(edtUpdateInterval.Value), 100, 60000);
      Reg.WriteInteger(UPDATE_INTERVAL, UpdateInterval);

      if cbErrorAlign.ItemIndex <> -1 then
        ErrorAlign := TErrorMessageAlign(cbErrorAlign.ItemIndex)
        else
          ErrorAlign := eaLeft;

      Reg.WriteInteger(ERROR_ALIGN, cbErrorAlign.itemindex);

      ErrorIndent := EnsureRange(Trunc(edtIndent.Value), 0, 500);
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
