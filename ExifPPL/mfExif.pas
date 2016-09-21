unit mfExif;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, System.Actions,
  Vcl.ActnList, Vcl.WinXCtrls, Vcl.Imaging.pngimage, Vcl.StdCtrls,
  System.ImageList, Vcl.ImgList, Vcl.ButtonGroup, Vcl.CategoryButtons,
  Vcl.ComCtrls;

type
  TfmMainUI = class(TForm)
    Panel1: TPanel;
    imgMenu: TImage;
    SV: TSplitView;
    paTop: TPanel;
    paBottom: TPanel;
    Splitter1: TSplitter;
    paFolders: TPanel;
    Splitter2: TSplitter;
    Panel2: TPanel;
    Panel3: TPanel;
    ActionList1: TActionList;
    acImgMenu: TAction;
    lbLog: TListBox;
    grpThumbnail: TGroupBox;
    imgThumbnail: TImage;
    Button1: TButton;
    imlIcons: TImageList;
    Button2: TButton;
    DrivesCat: TCategoryButtons;
    procedure acImgMenuExecute(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmMainUI: TfmMainUI;

implementation

{$R *.dfm}

uses
  myUtils;

procedure TfmMainUI.acImgMenuExecute(Sender: TObject);
begin
  if SV.Opened then
    SV.Close
  else
    SV.Open;
end;

procedure TfmMainUI.Button2Click(Sender: TObject);
var
  Drive: Char;
  DriveLetter: String;
  DriveLabel: string;
  curbt: TButtonItem;
  //oLI: TlistItem;
begin
  DrivesCat.Categories[0].Items.BeginUpdate;
  try
    DrivesCat.Categories[0].Items.Clear;
    For Drive := 'A' To 'Z' Do
    begin
      DriveLetter := Drive + ':\';
      If GetDriveType(PChar(DriveLetter)) in drvseeking Then
      begin
        DriveLabel := GetVolumeLabel(Drive);
        curbt := DrivesCat.Categories[0].Items.Add;
        curbt.Caption := Drive + ': "' + GetVolumeLabel(Drive) + '"';
//        oLI := ListView1.Items.Add;
//        oLI.Caption:= Drive;
//        oLI.SubItems.Add( ': "' + DriveLabel + '"');
      end;
    end;
  finally
    DrivesCat.Categories[0].Items.EndUpdate;
    DrivesCat.ClientHeight := (DrivesCat.Categories[0].Items.Count+1) * DrivesCat.ButtonHeight ;
//    ListView1.Top := DrivesCat.ClientHeight + 5;
  end;
end;




initialization
  ReportMemoryLeaksOnShutdown := True;

end.
