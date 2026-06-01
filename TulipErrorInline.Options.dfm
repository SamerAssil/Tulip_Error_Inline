object TulipErrorInlineFrame: TTulipErrorInlineFrame
  Left = 0
  Top = 0
  Width = 424
  Height = 281
  TabOrder = 0
  object GroupBox1: TGroupBox
    Left = 16
    Top = 16
    Width = 376
    Height = 121
    Caption = 'Error'
    TabOrder = 0
    object cbxErrorFontColor: TColorBox
      Left = 159
      Top = 26
      Width = 145
      Height = 22
      TabOrder = 0
    end
    object cbErrorEnabled: TCheckBox
      Left = 48
      Top = 29
      Width = 73
      Height = 17
      Caption = 'Error'
      TabOrder = 1
    end
    object cbWarningEnabled: TCheckBox
      Left = 48
      Top = 57
      Width = 73
      Height = 17
      Caption = 'Warning'
      TabOrder = 2
    end
    object cbxWarningFontColor: TColorBox
      Left = 159
      Top = 54
      Width = 145
      Height = 22
      TabOrder = 3
    end
    object cbHintEnabled: TCheckBox
      Left = 48
      Top = 85
      Width = 73
      Height = 17
      Caption = 'Hint'
      TabOrder = 4
    end
    object cbxHintFontColor: TColorBox
      Left = 159
      Top = 82
      Width = 145
      Height = 22
      TabOrder = 5
    end
  end
  object GroupBox4: TGroupBox
    Left = 207
    Top = 143
    Width = 185
    Height = 106
    Caption = 'Alignment'
    TabOrder = 1
    object Label5: TLabel
      Left = 19
      Top = 43
      Width = 28
      Height = 15
      Caption = 'Align'
    end
    object Label6: TLabel
      Left = 19
      Top = 72
      Width = 34
      Height = 15
      Caption = 'Indent'
    end
    object cbErrorAlign: TComboBox
      Left = 72
      Top = 40
      Width = 97
      Height = 23
      ItemIndex = 0
      TabOrder = 0
      Text = 'Left'
      Items.Strings = (
        'Left'
        'Right')
    end
    object edtIndent: TNumberBox
      Left = 72
      Top = 69
      Width = 97
      Height = 23
      TabOrder = 1
      Value = 40.000000000000000000
    end
  end
  object GroupBox5: TGroupBox
    Left = 16
    Top = 143
    Width = 185
    Height = 106
    Caption = 'Update Interval (ms)'
    TabOrder = 2
    object edtUpdateInterval: TNumberBox
      Left = 23
      Top = 40
      Width = 146
      Height = 23
      TabOrder = 0
      Value = 1000.000000000000000000
    end
  end
end
