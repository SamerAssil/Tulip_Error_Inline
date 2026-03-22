object TulipErrorInlineFrame: TTulipErrorInlineFrame
  Left = 0
  Top = 0
  Width = 409
  Height = 363
  TabOrder = 0
  object GroupBox1: TGroupBox
    Left = 16
    Top = 16
    Width = 376
    Height = 65
    Caption = 'Error'
    TabOrder = 0
    object cbxErrorFontColor: TColorBox
      Left = 191
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
      Caption = 'Enable'
      TabOrder = 1
    end
  end
  object GroupBox2: TGroupBox
    Left = 16
    Top = 87
    Width = 376
    Height = 65
    Caption = 'Warning'
    TabOrder = 1
    object cbxWarningFontColor: TColorBox
      Left = 191
      Top = 26
      Width = 145
      Height = 22
      TabOrder = 0
    end
    object cbWarningEnabled: TCheckBox
      Left = 48
      Top = 29
      Width = 73
      Height = 17
      Caption = 'Enable'
      TabOrder = 1
    end
  end
  object GroupBox3: TGroupBox
    Left = 16
    Top = 158
    Width = 376
    Height = 65
    Caption = 'Hint'
    TabOrder = 2
    object cbxHintFontColor: TColorBox
      Left = 191
      Top = 26
      Width = 145
      Height = 22
      TabOrder = 0
    end
    object cbHintEnabled: TCheckBox
      Left = 48
      Top = 29
      Width = 73
      Height = 17
      Caption = 'Enable'
      TabOrder = 1
    end
  end
  object GroupBox4: TGroupBox
    Left = 207
    Top = 229
    Width = 185
    Height = 92
    Caption = 'Alignment'
    TabOrder = 3
    object Label5: TLabel
      Left = 19
      Top = 27
      Width = 28
      Height = 15
      Caption = 'Align'
    end
    object Label6: TLabel
      Left = 19
      Top = 56
      Width = 34
      Height = 15
      Caption = 'Indent'
    end
    object cbErrorAlign: TComboBox
      Left = 72
      Top = 24
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
      Top = 53
      Width = 97
      Height = 23
      TabOrder = 1
      Value = 40.000000000000000000
    end
  end
  object GroupBox5: TGroupBox
    Left = 16
    Top = 229
    Width = 185
    Height = 92
    Caption = 'Update Interval (ms)'
    TabOrder = 4
    object edtUpdateInterval: TNumberBox
      Left = 23
      Top = 24
      Width = 146
      Height = 23
      TabOrder = 0
      Value = 1000.000000000000000000
    end
  end
end
