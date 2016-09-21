object Form12: TForm12
  Left = 0
  Top = 0
  Caption = 'Form12'
  ClientHeight = 307
  ClientWidth = 474
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 474
    Height = 307
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 6
      Top = 115
      Width = 83
      Height = 13
      Caption = 'Total executions:'
    end
    object lblTotalExec: TLabel
      Left = 95
      Top = 115
      Width = 12
      Height = 13
      Caption = '---'
    end
    object Label2: TLabel
      Left = 6
      Top = 135
      Width = 51
      Height = 13
      Caption = 'Total time:'
    end
    object lblTotalTime: TLabel
      Left = 95
      Top = 135
      Width = 12
      Height = 13
      Caption = '---'
    end
    object btnRun: TButton
      Left = 6
      Top = 78
      Width = 75
      Height = 25
      Caption = 'Run'
      TabOrder = 1
      OnClick = btnRunClick
    end
    object chPooled: TCheckBox
      Left = 6
      Top = 49
      Width = 82
      Height = 17
      Caption = 'Run pooled'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
    object Memo1: TMemo
      Left = 164
      Top = 14
      Width = 281
      Height = 279
      Lines.Strings = (
        'Memo1')
      TabOrder = 2
    end
    object cbDynamicDef: TCheckBox
      Left = 6
      Top = 3
      Width = 97
      Height = 17
      Caption = 'cbDynamicDef'
      TabOrder = 3
    end
    object cbPPLFor: TCheckBox
      Left = 6
      Top = 26
      Width = 97
      Height = 17
      Caption = 'cbPPLFor'
      TabOrder = 4
    end
  end
  object FDConnection1: TFDConnection
    Params.Strings = (
      'ConnectionDef=EMPLOYEE')
    Left = 236
    Top = 204
  end
end
