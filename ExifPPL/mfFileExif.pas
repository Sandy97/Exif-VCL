unit mfFileExif;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.WinXCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.MongoDB, FireDAC.Phys.MongoDBDef, System.Rtti,
  FireDAC.Phys.MongoDBWrapper, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client,
  System.JSON, System.JSON.Types, System.JSON.Readers, System.JSON.BSON, System.JSON.Builders,
  System.Actions, Vcl.ActnList;

type
  TfmFileExif = class(TForm)
    Panel1: TPanel;
    leRoot: TEdit;
    btOpen: TButton;
    OpenDialog1: TOpenDialog;
    Label2: TLabel;
    grpThumbnail: TGroupBox;
    imThumbnail: TImage;
    Volume: TGroupBox;
    laDrvType: TLabel;
    laFsystem: TLabel;
    laVLabel: TLabel;
    StatusBar1: TStatusBar;
    Memo1: TMemo;
    btJSON: TButton;
    btMongoDB: TButton;
    grMongo: TGroupBox;
    ToggleSwitch1: TToggleSwitch;
    FDConnection1: TFDConnection;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Edit2: TEdit;
    Edit1: TEdit;
    ActionList1: TActionList;
    acPickupFile: TAction;
    acMongoExtract: TAction;
    acJSONExtract: TAction;
    acMongoConnect: TAction;
    cbInsert: TCheckBox;
    laVSerial: TLabel;
    cbWThumb: TCheckBox;
    grpOptions: TGroupBox;
    procedure btOpenClick(Sender: TObject);
    procedure btVolInfoClick(Sender: TObject);
    procedure btJSONClick(Sender: TObject);
    procedure ToggleSwitch1Click(Sender: TObject);
    procedure acPickupFileExecute(Sender: TObject);
    procedure acMongoConnectExecute(Sender: TObject);
    procedure btMongoDBClick(Sender: TObject);
    procedure acMongoExtractExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    procedure showThumbNail;
  public
    { Public declarations }
  end;

var
  fmFileExif: TfmFileExif;

implementation

{$R *.dfm}

uses
  System.JSON.Writers,
  ExifExtractor, ExifWRTLoader,
  myUtils,
  //exifmongodoc,
  exifMongoHelper,ConvertersUtils,
  CCR.exif,

  system.DateUtils,
  System.Diagnostics;

var
  sw: TStopwatch;

procedure TfmFileExif.acMongoConnectExecute(Sender: TObject);
begin
    FDConnection1.Connected := (ToggleSwitch1.State = tssOn);
end;

procedure TfmFileExif.acMongoExtractExecute(Sender: TObject);
var
  strDoc: string;
  extr: TExifJSONExtractor;
begin
  Memo1.Clear;
  sw := TStopwatch.StartNew;
      extr := TExifJSONExtractor.Create(leRoot.Text);
      try
        imThumbnail.Picture.Assign(extr.thumbnail);
        if imThumbnail.Picture.Graphic <> nil then
          showThumbNail;

        if not FDConnection1.Connected then
          ToggleSwitch1.State:=tssOn;

        extr.withThumbN:=cbWThumb.Checked;

        strDoc := extr.toMongoDB(FDConnection1, cbInsert.Checked);
        Memo1.Lines.Add(strDoc);
      finally
//        if FDConnection1.Connected then
//          ToggleSwitch1.State:=tssOff;
        extr.Free;
      end;
  sw.Stop;
  StatusBar1.SimpleText := 'msec: ' + sw.ElapsedMilliseconds.ToString;
end;

procedure TfmFileExif.acPickupFileExecute(Sender: TObject);
begin
  with OpenDialog1 do
  begin
//    DefaultExt := edFileMask.Text;
    if OpenDialog1.Execute then begin
      leRoot.Text := OpenDialog1.filename;
      btVolInfoClick(Sender);
    end;
  end;
end;

procedure TfmFileExif.btJSONClick(Sender: TObject);
var
  Writer: TJsonObjectWriter;
  jv: TJSONValue;
  extr: TExifJSONExtractor;
  ewloader: TExifWriter;
  tb: TBytes;
begin
  Memo1.Clear;
  sw := TStopwatch.StartNew;
  Writer := TJsonObjectWriter.Create();
  ewloader := TExifWriter.Create(Writer);
  try
      extr := TExifJSONExtractor.Create(leRoot.Text);
      extr.withThumbN:=cbWThumb.Checked;
//+test Memo1.Lines.Add(extr.AsString);
      try
        imThumbnail.Picture.Assign(extr.thumbnail);
        if imThumbnail.Picture.Graphic <> nil then
          showThumbNail;
        Writer.Rewind;
        jv := extr.toJSON(ewloader);
        Memo1.Lines.Add(jv.ToString); {или Memo1.Lines.Add(Writer.JSON.ToString)}
      finally
        jv.Free;
        extr.Free;
      end;
  finally
    ewloader.Free;
    Writer.Free;
  end;
  sw.Stop;
  StatusBar1.SimpleText := 'msec: ' + sw.ElapsedMilliseconds.ToString;
end;

procedure TfmFileExif.btMongoDBClick(Sender: TObject);
begin
  acMongoExtract.Execute;
end;

procedure TfmFileExif.btOpenClick(Sender: TObject);
begin
  acPickupFile.Execute;
end;

procedure TfmFileExif.btVolInfoClick(Sender: TObject);
var
  Drive: String;
  DriveLetter: String;
  VolDriveType: DRVTYPECONST;
  VolInfoRec: HDDVolumeInfo;
begin
  Drive := ExtractFileDrive(leRoot.Text);
  DriveLetter := Drive + '\';
  VolDriveType := GetDriveType(PChar(DriveLetter));
  laDrvType.Caption := format('Тип:  %s (%d)', [DriveTypeNames[VolDriveType], VolDriveType]);
  if VolDriveType in drvseeking Then
  begin
    VolInfoRec := GetVolumeInfo(PChar(DriveLetter));
    VolInfoRec.diskType := VolDriveType;
    with VolInfoRec do
    begin
      laVSerial.Caption := 'Сер.#: '+VolInfoRec.serialNum.ToHexString;
      laVLabel.Caption := 'Метка: '+VolInfoRec.VolLabel;
      laFsystem.Caption := 'Ф.сист: '+VolInfoRec.fileSysName;
    end;
  end;
end;

procedure TfmFileExif.FormCreate(Sender: TObject);
begin
  btVolInfoClick(Sender);
end;

procedure TfmFileExif.showThumbNail;
begin
  grpThumbnail.Visible := False;
  if imThumbnail.Picture.Graphic <> nil then
  begin
//    grpThumbnail.Width := (grpThumbnail.Width - imThumbnail.Width) +
//      imThumbnail.Picture.Width;
    grpThumbnail.Visible := True;
  end
end;

procedure TfmFileExif.ToggleSwitch1Click(Sender: TObject);
begin
  acMongoConnect.Execute;
end;

initialization
  ReportMemoryLeaksOnShutdown := True;


end.
