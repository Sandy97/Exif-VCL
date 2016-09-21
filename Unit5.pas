unit Unit5;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Types, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.FileCtrl,
  myUtils,
  Vcl.ComCtrls, Vcl.CheckLst, Vcl.WinXCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.MongoDB, FireDAC.Phys.MongoDBDef, System.Rtti, System.JSON.Types,
  System.JSON.Readers, System.JSON.BSON, System.JSON.Builders,
  FireDAC.Phys.MongoDBWrapper, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    ListBox1: TListBox;
    Splitter1: TSplitter;
    leRoot: TLabeledEdit;
    SpeedButton1: TSpeedButton;
    btTdirectory: TButton;
    cbDoRecursive: TCheckBox;
    cbIncludeDirectories: TCheckBox;
    cbIncludeFiles: TCheckBox;
    edtFileMask: TEdit;
    StatusBar1: TStatusBar;
    GroupBox1: TGroupBox;
    ListBox2: TListBox;
    btJSON: TButton;
    Memo1: TMemo;
    btVolInfo: TButton;
    laVLabel: TLabel;
    laVSerial: TLabel;
    laFsystem: TLabel;
    laDrvType: TLabel;
    Volume: TGroupBox;
    btMongo: TButton;
    grpOptions: TGroupBox;
    ActivityIndicator1: TActivityIndicator;
    cbWThumb: TCheckBox;
    cbInsert: TCheckBox;
    cbBatch: TCheckBox;
    FDConnection1: TFDConnection;
    procedure ListBox1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure btTdirectoryClick(Sender: TObject);
    procedure btJSONClick(Sender: TObject);
    procedure btVolInfoClick(Sender: TObject);
    procedure btMongoClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    VolInfoRec: HDDVolumeInfo;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  System.JSON,
  System.JSON.Writers,
  ExifExtractor,
  // myUtils,

  System.Diagnostics, ExifWRTLoader;

var
  sw: TStopwatch;

procedure GetDirectories(const DirStr: string; ListBox: TCustomListBox);
var
  DirInfo: TSearchRec;
  r: Integer;
  Path: string;
begin
  Path := IncludeTrailingPathDelimiter(DirStr);
  r := FindFirst(Path + '*.*', FaDirectory, DirInfo);
  while r = 0 do
  begin
    Application.ProcessMessages;
    if ((DirInfo.Attr and FaDirectory = FaDirectory) and (DirInfo.Name <> '.')
      and (DirInfo.Name <> '..')) then
      ListBox.Items.Add(Path + DirInfo.Name);
    r := FindNext(DirInfo);
  end;
  System.SysUtils.FindClose(DirInfo);
end;

procedure GetFiles(const DirStr: string; mask: string; ListBox: TCustomListBox);
var
  DirInfo: TSearchRec;
  r: Integer;
  Path: string;
begin
  if mask = '' then
    mask := '*.jpg';
  Path := IncludeTrailingPathDelimiter(DirStr);
  r := FindFirst(Path + mask, FaAnyfile, DirInfo);
  while r = 0 do
  begin
    Application.ProcessMessages;
    if ((DirInfo.Attr and FaDirectory <> FaDirectory) and
      (DirInfo.Attr and faVolumeID <> faVolumeID)) then
      ListBox.Items.Add(Path + DirInfo.Name);
    r := FindNext(DirInfo);
  end;
  System.SysUtils.FindClose(DirInfo);
end;

procedure TForm1.btMongoClick(Sender: TObject);
var
  i: Integer;
  BatchArray: TJSONArray;
  tb: TBytes;
  strDoc: string;
  extr: TExifJSONExtractor;
begin
  sw := TStopwatch.StartNew;
  BatchArray := TJSONArray.Create;
  Memo1.Clear;
  ActivityIndicator1.Animate:=True;
  i:=0;
  try
    if not FDConnection1.Connected then
      FDConnection1.Connected:=True;
    for i := 0 to ListBox2.Items.Count - 1 do
    begin
       extr := TExifJSONExtractor.Create(ListBox2.Items[i]);
       extr.withThumbN:=cbWThumb.Checked;
      try
       strDoc := extr.toMongoDB(FDConnection1, cbInsert.Checked);
       BatchArray.Add(strDoc);
       Memo1.Lines.Add(strDoc);
      finally
//        if FDConnection1.Connected then
//          ToggleSwitch1.State:=tssOff;
        extr.Free;
      end;
    end;
  finally
    ActivityIndicator1.Animate:=False;
    BatchArray.Free;
  end;
  sw.Stop;
  StatusBar1.SimpleText := 'msec: ' + sw.ElapsedMilliseconds.ToString;
end;

procedure TForm1.btTdirectoryClick(Sender: TObject);
var
  LList: TStringDynArray;
  i: Integer;
  LSearchOption: TSearchOption;
begin
  sw := TStopwatch.StartNew;
  { Select the search option }
  if cbDoRecursive.Checked then
    LSearchOption := TSearchOption.soAllDirectories
  else
    LSearchOption := TSearchOption.soTopDirectoryOnly;

  try
    { For all entries use GetFileSystemEntries method }
    if cbIncludeDirectories.Checked and cbIncludeFiles.Checked then
      LList := TDirectory.GetFileSystemEntries(leRoot.Text, LSearchOption, nil);

    { For directories use GetDirectories method }
    if cbIncludeDirectories.Checked and not cbIncludeFiles.Checked then
      LList := TDirectory.GetDirectories(leRoot.Text, edtFileMask.Text,
        LSearchOption);

    { For files use GetFiles method }
    if not cbIncludeDirectories.Checked and cbIncludeFiles.Checked then
      LList := TDirectory.GetFiles(leRoot.Text, edtFileMask.Text,
        LSearchOption);
  except
    { Catch the possible exceptions }
    MessageDlg('Incorrect path or search mask', mtError, [mbOK], 0);
    Exit;
  end;

  { Populate the memo with the results }
  ListBox2.Clear;

  for i := 0 to Length(LList) - 1 do
    ListBox2.Items.Add(LList[i]);
  sw.Stop;
  StatusBar1.SimpleText := 'msec: ' + sw.ElapsedMilliseconds.ToString;
end;


procedure TForm1.btVolInfoClick(Sender: TObject);
var
  Drive: String;
  DriveLetter: String;
  VolDriveType: DRVTYPECONST;
begin
  Drive := ExtractFileDrive(leRoot.Text);
  DriveLetter := Drive + '\';
  VolDriveType := GetDriveType(PChar(DriveLetter));
  laDrvType.Caption := format('%s (%d)', [DriveTypeNames[VolDriveType],
    VolDriveType]);
  if VolDriveType in drvseeking Then
  begin
    VolInfoRec := GetVolumeInfo(PChar(DriveLetter));
    VolInfoRec.diskType := VolDriveType;
    with VolInfoRec do
    begin
      laVSerial.Caption := VolInfoRec.serialNum.ToHexString;
      laVLabel.Caption := VolInfoRec.VolLabel;
      laFsystem.Caption := VolInfoRec.fileSysName;
    end;
  end;
end;

procedure TForm1.btJSONClick(Sender: TObject);
var
  i: Integer;
  Writer: TJsonObjectWriter;
  extr: TExifJSONExtractor;
  ewloader: TExifWriter;
  //tb: TBytes;
  jv: TJSONObject;
  BatchArray: TJSONArray;
begin
  sw := TStopwatch.StartNew;
  Writer := TJsonObjectWriter.Create();
  //Writer.StringEscapeHandling:=TJsonStringEscapeHandling.EscapeNonAscii;
  //Writer.Formatting := TJsonFormatting.None;
  ewloader := TExifWriter.Create(Writer);
  BatchArray := TJSONArray.Create;
  Memo1.Clear;
  ActivityIndicator1.Animate:=True;
  i := 0;
  try
    while i < ListBox2.Items.Count do
    begin
      extr := TExifJSONExtractor.Create(ListBox2.Items[i]);
      extr.withThumbN := cbWThumb.Checked;
      // +test Memo1.Lines.Add(extr.AsString);
      try
        Writer.Rewind;
        jv := extr.toJSON(ewloader);
//Memo1.Lines.Add(jv.ToString);{ или Memo1.Lines.Add(Writer.JSON.ToString) }
        //jv := TJSONObject(Writer.JSON.Clone);
        BatchArray.Add(jv);
      finally
        //jv.Free;
        extr.Free;
      end;
      Inc(i);
    end;
    Memo1.Lines.Add(BatchArray.ToString);

  finally
    BatchArray.Free;
    ewloader.Free;
    Writer.Free;
    ActivityIndicator1.Animate:=false;
    sw.Stop;
  end;
  StatusBar1.SimpleText := format(' files %d, msec: %s', [i, sw.ElapsedMilliseconds.ToString]);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  i := 0;
  while i < ListBox1.Items.Count do
  begin
    GetDirectories(ListBox1.Items[i], ListBox1);
    Inc(i);
  end;
end;

procedure TForm1.ListBox1Click(Sender: TObject);
begin
  sw := TStopwatch.StartNew;
  ListBox2.Clear;
  GetFiles(ListBox1.Items[ListBox1.ItemIndex], Trim(edtFileMask.Text),  ListBox2);
  sw.Stop;
  StatusBar1.SimpleText := 'msec: ' + sw.ElapsedMilliseconds.ToString;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
var
  Sr: TSearchRec;
  Attr: Integer;
  Dir: string;
begin
  sw := TStopwatch.StartNew;
  // Путь к папке, в которой нужно произвести поиск. Начальное значение выбираем
  // равным пути к той папке, в которой расположена наша программа.
  if leRoot.Text = '' then
    leRoot.Text := 'C:\Users\asovtsov\Downloads';
  // ExtractFilePath(ParamStr(0));
  // Диалог выбора папки.
  Dir := leRoot.Text;
  if not Vcl.FileCtrl.SelectDirectory(Dir, [sdAllowCreate, sdPerformCreate,
    sdPrompt], 100) then
    Exit;
  leRoot.Text := Dir; // IncludeTrailingPathDelimiter(Dir);
  // Если конечный слеш отсутствует, то добавляем его.
  ListBox1.Items.Clear;
  ListBox2.Items.Clear;
  ListBox1.Items.Add(leRoot.Text);
  GetDirectories(leRoot.Text, ListBox1);
  sw.Stop;
  StatusBar1.SimpleText := 'msec: ' + sw.ElapsedMilliseconds.ToString;
end;

initialization

ReportMemoryLeaksOnShutdown := True;

end.


