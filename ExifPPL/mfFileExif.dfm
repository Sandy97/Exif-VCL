object fmFileExif: TfmFileExif
  Left = 0
  Top = 0
  Caption = #1059#1087#1088#1072#1074#1083#1077#1085#1080#1077' EXIF '
  ClientHeight = 760
  ClientWidth = 978
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 17
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 978
    Height = 181
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alTop
    BevelOuter = bvNone
    Caption = ' '
    TabOrder = 0
    ExplicitWidth = 1286
    object Label2: TLabel
      Left = 10
      Top = 18
      Width = 86
      Height = 17
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #1048#1079#1086#1073#1088#1072#1078#1077#1085#1080#1077
    end
    object leRoot: TEdit
      Left = 103
      Top = 14
      Width = 338
      Height = 25
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 0
      Text = 'C:\Temp\fotos\100EOS7D\_72_9961.JPG'
    end
    object btOpen: TButton
      Left = 460
      Top = 11
      Width = 86
      Height = 32
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #1042#1099#1073#1088#1072#1090#1100
      TabOrder = 1
      OnClick = btOpenClick
    end
    object grpThumbnail: TGroupBox
      AlignWithMargins = True
      Left = 767
      Top = 0
      Width = 211
      Height = 181
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alRight
      Caption = #1052#1080#1085#1080#1072#1090#1102#1088#1072
      TabOrder = 2
      Visible = False
      ExplicitLeft = 1075
      object imThumbnail: TImage
        AlignWithMargins = True
        Left = 45
        Top = 18
        Width = 131
        Height = 160
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Proportional = True
        Stretch = True
      end
    end
    object Volume: TGroupBox
      AlignWithMargins = True
      Left = 10
      Top = 53
      Width = 196
      Height = 125
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #1053#1086#1089#1080#1090#1077#1083#1100
      TabOrder = 3
      object laDrvType: TLabel
        Left = 14
        Top = 23
        Width = 4
        Height = 17
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = ' '
      end
      object laFsystem: TLabel
        Left = 14
        Top = 94
        Width = 4
        Height = 17
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
      end
      object laVLabel: TLabel
        Left = 14
        Top = 46
        Width = 4
        Height = 17
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
      end
      object laVSerial: TLabel
        Left = 14
        Top = 70
        Width = 4
        Height = 17
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
      end
    end
    object btJSON: TButton
      Left = 460
      Top = 60
      Width = 121
      Height = 50
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'JSON'
      TabOrder = 4
      OnClick = btJSONClick
    end
    object btMongoDB: TButton
      Left = 460
      Top = 118
      Width = 121
      Height = 50
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'MongoDB'
      TabOrder = 5
      OnClick = btMongoDBClick
    end
    object grMongo: TGroupBox
      Left = 214
      Top = 53
      Width = 227
      Height = 125
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #1057#1077#1088#1074#1077#1088
      TabOrder = 6
      object Label1: TLabel
        Left = 15
        Top = 23
        Width = 59
        Height = 17
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = 'Host:port'
      end
      object Label3: TLabel
        Left = 55
        Top = 56
        Width = 18
        Height = 17
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = #1041#1044
      end
      object Label4: TLabel
        Left = 55
        Top = 90
        Width = 78
        Height = 17
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = #1057#1086#1077#1076#1080#1085#1077#1085#1080#1077
      end
      object ToggleSwitch1: TToggleSwitch
        Left = 140
        Top = 85
        Width = 79
        Height = 24
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        FrameColor = clScrollBar
        StateCaptions.CaptionOn = #1044#1072
        StateCaptions.CaptionOff = #1053#1077#1090
        SwitchHeight = 24
        SwitchWidth = 49
        TabOrder = 0
        OnClick = ToggleSwitch1Click
      end
      object Edit2: TEdit
        Left = 84
        Top = 16
        Width = 136
        Height = 25
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        TabOrder = 1
        Text = 'localhost:27017'
      end
      object Edit1: TEdit
        Left = 84
        Top = 50
        Width = 136
        Height = 25
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        TabOrder = 2
        Text = 'Grafics'
      end
    end
    object grpOptions: TGroupBox
      Left = 589
      Top = 53
      Width = 162
      Height = 125
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
      TabOrder = 7
      object cbInsert: TCheckBox
        Left = 11
        Top = 69
        Width = 135
        Height = 21
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = #1047#1072#1075#1088#1091#1078#1072#1090#1100' '#1074' '#1041#1044
        TabOrder = 0
      end
      object cbWThumb: TCheckBox
        Left = 11
        Top = 29
        Width = 130
        Height = 21
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = #1057' '#1084#1080#1085#1080#1072#1090#1102#1088#1086#1081
        TabOrder = 1
      end
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 736
    Width = 978
    Height = 24
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Panels = <>
    SimplePanel = True
    ExplicitTop = 909
    ExplicitWidth = 1286
  end
  object Memo1: TMemo
    AlignWithMargins = True
    Left = 4
    Top = 185
    Width = 970
    Height = 547
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alClient
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssBoth
    TabOrder = 2
    ExplicitWidth = 1278
    ExplicitHeight = 720
  end
  object OpenDialog1: TOpenDialog
    InitialDir = 'c:\temp'
    Left = 88
    Top = 284
  end
  object FDConnection1: TFDConnection
    Params.Strings = (
      'DriverID=Mongo')
    Left = 244
    Top = 244
  end
  object ActionList1: TActionList
    Left = 80
    Top = 168
    object acPickupFile: TAction
      Caption = 'acPickupFile'
      OnExecute = acPickupFileExecute
    end
    object acMongoExtract: TAction
      Caption = 'acMongoExtract'
      OnExecute = acMongoExtractExecute
    end
    object acJSONExtract: TAction
      Caption = 'acJSONExtract'
    end
    object acMongoConnect: TAction
      Caption = 'acMongoConnect'
      OnExecute = acMongoConnectExecute
    end
  end
end
