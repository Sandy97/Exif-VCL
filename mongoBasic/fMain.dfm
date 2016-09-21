object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'MongoDB General Demo'
  ClientHeight = 462
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    640
    462)
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 520
    Top = 8
    Width = 97
    Height = 97
    Picture.Data = {
      055449636F6E0000010001002020100000000000E80200001600000028000000
      2000000040000000010004000000000080020000000000000000000000000000
      0000000000000000000080000080000000808000800000008000800080800000
      80808000C0C0C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000
      FFFFFF0000000000000000000000000000000000000000000000000000000000
      0000000000000000000008888800000000000000000000000008844444880000
      0000000000000000008447777744800000000000000000000844444444444800
      0000000000000000844444444444448000000000000000008444444444444480
      000000000000000844444E444444444800000000000000084444E44444444448
      0000000000000008444E6E44444444480000000000000008444CECECCCCC4448
      00000000000000084CCE6ECCCCCCCC4800000000000000008CCCE6ECCCCCCC80
      000000000000000088FCCECCCCCCF8800000000000000000088F8F8F8F8F8800
      00000000000000000088FFF8F8F88000000000000000000000088FFF8F880000
      0000000000000000000088FFF8800000000000000000000000007F8F8F700000
      0000000000000000000008FFF800000000000000000000000000088F88000000
      0000000000000000000008FFF800000000000000000000000000088F88000000
      0000000000000000000008FFF800000000000000000000000000088F88000000
      0000000000000000000008F87700000000000000000000000007888888870000
      0000000000000000000887777788000000000000000000000007788888770000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000FFFFFFFFFFF83FFFFFE00FFFFFC007FFFF8003FFFF0001FFFE0000FF
      FE0000FFFC00007FFC00007FFC00007FFC00007FFC00007FFE0000FFFE0000FF
      FF0001FFFF8003FFFFC007FFFFE00FFFFFE00FFFFFF01FFFFFF01FFFFFF01FFF
      FFF01FFFFFF01FFFFFF01FFFFFE00FFFFFC007FFFFC007FFFFC007FFFFE00FFF
      FFFFFFFF}
    Proportional = True
    Stretch = True
    Transparent = True
  end
  object Memo1: TMemo
    Left = 8
    Top = 116
    Width = 624
    Height = 338
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object btnInsert: TButton
    Left = 8
    Top = 9
    Width = 75
    Height = 25
    Caption = 'Insert'
    TabOrder = 1
    OnClick = btnInsertClick
  end
  object btnPing: TButton
    Left = 88
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Ping'
    TabOrder = 2
    OnClick = btnPingClick
  end
  object btnAggProj: TButton
    Left = 169
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Agg / Proj'
    TabOrder = 3
    OnClick = btnAggProjClick
  end
  object btnAggRedact: TButton
    Left = 250
    Top = 9
    Width = 75
    Height = 25
    Caption = 'Agg / Redact'
    TabOrder = 4
    OnClick = btnAggRedactClick
  end
  object btnInsFind: TButton
    Left = 331
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Find'
    TabOrder = 5
    OnClick = btnInsFindClick
  end
  object btnListCols: TButton
    Left = 8
    Top = 39
    Width = 75
    Height = 25
    Caption = 'ListCols'
    TabOrder = 6
    OnClick = btnListColsClick
  end
  object btnUpdInc: TButton
    Left = 88
    Top = 39
    Width = 75
    Height = 25
    Caption = 'Upd / Inc'
    TabOrder = 7
    OnClick = btnUpdIncClick
  end
  object btnUpdPush: TButton
    Left = 169
    Top = 39
    Width = 75
    Height = 25
    Caption = 'Upd / Push'
    TabOrder = 8
    OnClick = btnUpdPushClick
  end
  object Button9: TButton
    Left = 250
    Top = 39
    Width = 75
    Height = 25
    Caption = 'Bulk Ins'
    TabOrder = 9
    OnClick = Button9Click
  end
  object btnIterate: TButton
    Left = 331
    Top = 39
    Width = 75
    Height = 25
    Caption = 'Iterate'
    TabOrder = 10
    OnClick = btnIterateClick
  end
  object btnCurrentOp: TButton
    Left = 412
    Top = 8
    Width = 75
    Height = 25
    Caption = 'CurrentOp'
    TabOrder = 11
    OnClick = btnCurrentOpClick
  end
  object btTest: TButton
    AlignWithMargins = True
    Left = 412
    Top = 39
    Width = 75
    Height = 25
    Caption = 'btTest'
    TabOrder = 12
  end
  object bt2Test: TButton
    Left = 412
    Top = 70
    Width = 75
    Height = 25
    Caption = 'bt2Test'
    TabOrder = 13
    OnClick = bt2TestClick
  end
  object btMemToBytes: TButton
    Left = 8
    Top = 70
    Width = 75
    Height = 25
    Caption = 'btMemToBytes'
    TabOrder = 14
    OnClick = btMemToBytesClick
  end
  object btExifMongoDoc: TButton
    Left = 89
    Top = 70
    Width = 95
    Height = 25
    Caption = 'btExifMongoDoc'
    TabOrder = 15
  end
  object btLoadThumb: TButton
    Left = 331
    Top = 70
    Width = 75
    Height = 25
    Caption = 'Load Thumb'
    TabOrder = 16
    OnClick = btLoadThumbClick
  end
  object FDPhysMongoDriverLink1: TFDPhysMongoDriverLink
    Left = 176
    Top = 176
  end
  object FDMoniFlatFileClientLink1: TFDMoniFlatFileClientLink
    Left = 176
    Top = 232
  end
  object FDGUIxErrorDialog1: TFDGUIxErrorDialog
    Provider = 'Forms'
    Left = 312
    Top = 232
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 312
    Top = 176
  end
  object FDConnection1: TFDConnection
    Params.Strings = (
      'Server=localhost'
      'Port='
      'DriverID=Mongo')
    Left = 64
    Top = 176
  end
end
