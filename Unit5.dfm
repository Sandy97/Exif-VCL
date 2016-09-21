object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 669
  ClientWidth = 754
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 199
    Top = 165
    Height = 284
    ExplicitLeft = 384
    ExplicitTop = 352
    ExplicitHeight = 100
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 754
    Height = 165
    Align = alTop
    Caption = ' '
    TabOrder = 0
    object SpeedButton1: TSpeedButton
      Left = 319
      Top = 34
      Width = 58
      Height = 22
      Caption = #1074#1099#1073#1088#1072#1090#1100
      OnClick = SpeedButton1Click
    end
    object leRoot: TLabeledEdit
      Left = 8
      Top = 35
      Width = 305
      Height = 21
      EditLabel.Width = 39
      EditLabel.Height = 13
      EditLabel.Caption = 'Root Dir'
      TabOrder = 0
    end
    object GroupBox1: TGroupBox
      AlignWithMargins = True
      Left = 607
      Top = 7
      Width = 137
      Height = 145
      Caption = 'Directories'
      TabOrder = 1
      Visible = False
      object cbDoRecursive: TCheckBox
        Left = 8
        Top = 41
        Width = 97
        Height = 17
        Caption = 'cbDoRecursive'
        TabOrder = 0
      end
      object cbIncludeDirectories: TCheckBox
        Left = 8
        Top = 64
        Width = 121
        Height = 17
        Caption = 'cbIncludeDirectories'
        TabOrder = 1
      end
      object cbIncludeFiles: TCheckBox
        Left = 8
        Top = 18
        Width = 97
        Height = 17
        Caption = 'cbIncludeFiles'
        TabOrder = 2
      end
      object btTdirectory: TButton
        Left = 7
        Top = 107
        Width = 75
        Height = 25
        Caption = 'btTdirectory'
        TabOrder = 3
        OnClick = btTdirectoryClick
      end
    end
    object btJSON: TButton
      Left = 258
      Top = 82
      Width = 75
      Height = 25
      Caption = 'btJSON'
      TabOrder = 2
      OnClick = btJSONClick
    end
    object Volume: TGroupBox
      AlignWithMargins = True
      Left = 8
      Top = 62
      Width = 185
      Height = 95
      Caption = #1053#1086#1089#1080#1090#1077#1083#1100
      TabOrder = 3
      object laDrvType: TLabel
        Left = 11
        Top = 18
        Width = 49
        Height = 13
        Caption = 'laDrvType'
      end
      object laFsystem: TLabel
        Left = 11
        Top = 75
        Width = 48
        Height = 13
        Caption = 'laFsystem'
      end
      object laVLabel: TLabel
        Left = 11
        Top = 37
        Width = 39
        Height = 13
        Caption = 'laVLabel'
      end
      object laVSerial: TLabel
        Left = 11
        Top = 56
        Width = 32
        Height = 13
        Caption = 'VSerial'
      end
      object btVolInfo: TButton
        Left = 105
        Top = 65
        Width = 75
        Height = 25
        Caption = 'btVolInfo'
        TabOrder = 0
        OnClick = btVolInfoClick
      end
    end
    object btMongo: TButton
      Left = 258
      Top = 122
      Width = 75
      Height = 25
      Caption = 'btMongo'
      TabOrder = 4
      OnClick = btMongoClick
    end
    object grpOptions: TGroupBox
      Left = 396
      Top = 25
      Width = 185
      Height = 132
      Caption = #1055#1072#1088#1072#1084#1077#1090#1088#1099
      TabOrder = 5
      object edtFileMask: TEdit
        Left = 10
        Top = 97
        Width = 75
        Height = 21
        TabOrder = 0
        Text = '*.jpg'
      end
      object cbBatch: TCheckBox
        Left = 8
        Top = 69
        Width = 97
        Height = 17
        Caption = #1055#1072#1082#1077#1090#1085#1086
        Enabled = False
        TabOrder = 1
      end
      object cbInsert: TCheckBox
        Left = 8
        Top = 46
        Width = 97
        Height = 17
        Caption = #1047#1072#1075#1088#1091#1079#1082#1072' '#1074' '#1041#1044
        TabOrder = 2
      end
      object cbWThumb: TCheckBox
        Left = 8
        Top = 23
        Width = 97
        Height = 17
        Caption = #1089' '#1084#1080#1085#1080#1072#1090#1102#1088#1086#1081
        TabOrder = 3
      end
    end
  end
  object ListBox1: TListBox
    AlignWithMargins = True
    Left = 3
    Top = 168
    Width = 193
    Height = 278
    Align = alLeft
    ItemHeight = 13
    TabOrder = 1
    OnClick = ListBox1Click
    ExplicitHeight = 271
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 650
    Width = 754
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object ListBox2: TListBox
    AlignWithMargins = True
    Left = 205
    Top = 168
    Width = 546
    Height = 278
    Align = alClient
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 3
    ExplicitHeight = 271
  end
  object Memo1: TMemo
    AlignWithMargins = True
    Left = 3
    Top = 452
    Width = 748
    Height = 195
    Align = alBottom
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssBoth
    TabOrder = 4
  end
  object ActivityIndicator1: TActivityIndicator
    Left = 507
    Top = 82
    FrameDelay = 5
    IndicatorSize = aisXLarge
  end
  object FDConnection1: TFDConnection
    Params.Strings = (
      'DriverID=Mongo')
    Left = 232
    Top = 244
  end
end
