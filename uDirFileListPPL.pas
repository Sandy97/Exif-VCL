unit uDirFileListPPL;
{
  ���������������:
  GUI
  �������� � ����������� �������:
  TaskQue
  Loader
  Writer\Builder
  ���������, ������������� �������
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Types, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.FileCtrl,
  Vcl.ComCtrls, Vcl.CheckLst, Vcl.WinXCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.MongoDB, FireDAC.Phys.MongoDBDef, System.Rtti, System.JSON.Types,
  System.JSON.Readers, System.JSON.BSON, System.JSON.Builders,
  FireDAC.Phys.MongoDBWrapper, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client,
  myUtils, mytaskQueue,
  ExifMemoContainer,
  ExifWRTLoader,
  System.Notification, ExifMongoLoaderTypes, System.IniFiles, System.Threading;

const
  DefaultIniPath = 'C:\Users\asovtsov\Downloads';

type
  TfmDirFileList = class(TForm)
    Panel1: TPanel;
    ListBox1: TListBox;
    Splitter1: TSplitter;
    leRoot: TLabeledEdit;
    SpeedButton1: TSpeedButton;
    edtFileMask: TEdit;
    StatusBar1: TStatusBar;
    ListBox2: TListBox;
    Memo1: TMemo;
    btMongo: TButton;
    grpOptions: TGroupBox;
    ActivityIndicator1: TActivityIndicator;
    cbWThumb: TCheckBox;
    cbInsert: TCheckBox;
    cbBatch: TCheckBox;
    FDConnection_2delete: TFDConnection;
    cbShow: TCheckBox;
    cbStandards: TCheckBox;
    cbMkNotes: TCheckBox;
    RadioGroup1: TRadioGroup;
    grMongo: TGroupBox;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ToggleSwitch1: TToggleSwitch;
    Edit2: TEdit;
    Edit1: TEdit;
    btFileListClear: TButton;
    btDelFilesSelected: TButton;
    Label2: TLabel;
    Edit3: TEdit;
    Label5: TLabel;
    procedure ListBox1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure btMongoClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btFileListClearClick(Sender: TObject);
    procedure btDelFilesSelectedClick(Sender: TObject);
    // procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FMakerNoteValueMap: TMemIniFile;
    opt: TPartOptSet;
    function ItemToMongo(it: TFileVolBinded): string;
    function ItemToMongoPPL(eextractor:TExifXtractor; aLoader:TExifMongoLoader; it:TFileVolBinded):string;
    procedure ReloadMakerNoteValueMap(const IniFileName: string);
    procedure DefineConnectionDef;
  public
    { Public declarations }
  end;

var
  fmDirFileList: TfmDirFileList;

implementation

{$R *.dfm}

uses
  // System.JSON, System.JSON.Writers,
  System.Diagnostics;

var
  sw: TStopwatch;

procedure TfmDirFileList.FormCreate(Sender: TObject);
var
  i: Integer;
  IniFileName: string;
begin
  FMakerNoteValueMap := TMemIniFile.Create('');
  IniFileName := ExtractFilePath(Application.ExeName) + 'MakerNotes.ini';
  ReloadMakerNoteValueMap(IniFileName);
  //JQueue := TmyTaskQueue<TFileVolBinded>.Create;
  opt := [];
//  i := 0;
//  while i < ListBox1.Items.Count do
//  begin
//    GetDirectories(ListBox1.Items[i], ListBox1.Items);
//    Inc(i);
//  end;
end;

procedure TfmDirFileList.FormDestroy(Sender: TObject);
begin
  FMakerNoteValueMap.Free;
end;

{$region '2: ������ �� ������� ������ ---------------------------------------'}
procedure TfmDirFileList.btDelFilesSelectedClick(Sender: TObject);
begin
  if ListBox2.SelCount > 0 then
    ListBox2.DeleteSelected;
  StatusBar1.SimpleText := '�����: ' + IntToStr(ListBox2.Items.Count);
end;

procedure TfmDirFileList.btFileListClearClick(Sender: TObject);
begin
  ListBox2.Clear;
end;

procedure TfmDirFileList.ListBox1Click(Sender: TObject);
var
  i: Integer;
begin
  StatusBar1.SimpleText := '...����������';
  TTask.Run(
    procedure
    var
      mdList: TStringList;
    begin
      mdList := TStringList.Create;
      try
        sw := TStopwatch.StartNew;
        btTdirectoryClick(ListBox1.Items[ListBox1.ItemIndex],
          Trim(edtFileMask.Text), mdList);
        TThread.Synchronize(nil, // TThread.CurrentThread,
          procedure
          begin
            ListBox2.Items.AddStrings(mdList);
            sw.Stop;
            StatusBar1.SimpleText := 'msec: ' + sw.ElapsedMilliseconds.ToString
              + ' �����: ' + IntToStr(ListBox2.Items.Count)+ '+' + IntToStr(mdList.Count);
          end);
      finally
        mdList.Free;
      end;
    end);
end;

procedure TfmDirFileList.SpeedButton1Click(Sender: TObject);
var
  Dir: string;
begin
  sw := TStopwatch.StartNew;
  // ���� � �����, � ������� ����� ���������� �����.
  // todo 1 : ��������� �������� �������� ������ ���� � ��� �����, � ������� ����������� ���� ���������.
  if leRoot.Text = '' then
    leRoot.Text := 'C:\Users\asovtsov\Downloads';
  // ExtractFilePath(ParamStr(0));
  // ������ ������ �����.
  Dir := leRoot.Text;
  if not Vcl.FileCtrl.SelectDirectory(Dir, [sdPerformCreate, sdPrompt], 100)
  then // sdAllowCreate,
    exit;
  leRoot.Text := ExcludeTrailingPathDelimiter(Dir); // Dir
  // ���� �������� ���� ������������, �� ������� ���.
  ListBox1.Items.Clear;
  ListBox2.Items.Clear;
  ListBox1.Items.Add(leRoot.Text);
  GetDirectories(leRoot.Text, ListBox1.Items);
  sw.Stop;
  StatusBar1.SimpleText := 'msec: ' + sw.ElapsedMilliseconds.ToString;
end;
{$endregion 2}

{$Region '3: ��������� EXIF -------------------------------------------------'}
procedure TfmDirFileList.btMongoClick(Sender: TObject);
var
  mxcnt: Integer;
  LoopResult: TParallel.TLoopResult;
begin
//  DefineConnectionDef;
  sw := TStopwatch.StartNew;
  Memo1.Clear;
  ActivityIndicator1.Animate := True;
  StatusBar1.SimpleText := '...���������';
  // ����������� ���������
  opt := [];
  if cbStandards.checked then
    include(opt, poStd);
  if cbWThumb.checked then
    include(opt, poThumb);
  if cbMkNotes.checked then
    include(opt, poMkNotes);
  if cbBatch.checked then
    include(opt, poBatch);

  mxcnt := ListBox2.Items.Count - 1;
  TTask.Run(
    procedure
    var
      Loader: TExifMongoLoader;
      EXIFXtractor: TExifXtractor;
    begin
      EXIFXtractor := TExifXtractor.Create;
      if RadioGroup1.ItemIndex = 0 then
        //Loader := TExifSingleLoader.Create('Mongo_Grafics', opt)
        Loader := TExifSingleLoader.Create(FDConnection_2delete, opt)
      else
      begin
        include(opt, poMkNotes); // ����� ��� ������ ������ � ��������� ���������
        //Loader := TExifCoupledLoader.Create('Mongo_Grafics', opt);
        Loader := TExifCoupledLoader.Create(FDConnection_2delete, opt);
      end;
      try
        LoopResult := TParallel.For(0, mxcnt,
          procedure(aIndex: Integer)
          begin
            //����� ����� ���������  ��������: sleep(100);
//            ItemToMongoPPL(EXIFXtractor,Loader,TFileVolBinded.Create(ListBox2.Items[aIndex]));
            if cbShow.checked then
            TThread.Queue(nil, //Queue(TThread.Current,
              procedure
              begin
                Memo1.Lines.Add(ListBox2.Items[aIndex]);
                //Memo1.Lines.Add(LdrResult);
              end);
          end);

        if LoopResult.Completed then
        begin
          TThread.Synchronize(nil, // TThread.CurrentThread,
            procedure
            begin
              Memo1.Lines.Add('--���������--');
            end);
        end;
      finally
        FDManager.CloseConnectionDef('Mongo_Grafics');
        ExifXtractor.Free;
        Loader.Free;
          TThread.Queue(nil, // TThread.CurrentThread,
            procedure
            begin
              ActivityIndicator1.Animate := False;
              sw.Stop;
              StatusBar1.SimpleText := 'msec: ' +
                sw.ElapsedMilliseconds.ToString + ' �����: ' + IntToStr(mxcnt+1);
            end);
      end;
    end);
end;

//function TfmDirFileList.ItemToMongoPPL(EXIFXtractor,Loader,TFileVolBinded.Create(ListBox2.Items[aIndex])):string;
function TfmDirFileList.ItemToMongoPPL(eextractor: TExifXtractor;
  aLoader: TExifMongoLoader; it: TFileVolBinded): string;
var
  LdrResult: string;
begin
  Result:='';
  eextractor.ReadExtract(it.UNCPath);
  if not eextractor.IsActive then
    exit;
  { Process Loader }
  // �����: { �����: [std, Thumb, MkNotes], insert:false, batch:false }
  // ���.�����: Log_in_memo
  // single : db, collection
  // coupled: db, collection1, collection2
//-------------------------------------------------------------------------------------
exit;
  with aLoader do
  begin
    Clear; // ������� �����.��������� ������
    if (poStd in opt) then
      LoadStandardValues(eextractor.MemExifData);
    if (poMkNotes in opt) and eextractor.FExifData.HasMakerNote then
      LoadMakerNoteValues(eextractor.MemMakerNotes, FMakerNoteValueMap);
    if (poThumb in opt) and not(eextractor.Thumbnail.Graphic = nil) then
      LoadGraphics(eextractor.Thumbnail);

    if (poBatch in opt) then
      LdrResult := aLoader.StoreDefaultDB(it, cbInsert.checked)
    else if (aLoader is TExifSingleLoader) then
      LdrResult := (aLoader as TExifSingleLoader).StoreToDB(it, nil {FDConnection1},
        DefaultDBName, [DefaultCollection], cbInsert.checked)
    else if (aLoader is TExifCoupledLoader) then
      LdrResult := (aLoader as TExifCoupledLoader).StoreToDB(it, nil {FDConnection1},
        DefaultDBName, [DefaultMainCollection, DefaultMkNotesCollection],
        cbInsert.checked)
    else
      raise Exception.Create('Undefined Loader');
  end;
  Result:=LdrResult;
end;

function TfmDirFileList.ItemToMongo(it: TFileVolBinded): string;
var
  LdrResult: string;
  Loader: TExifMongoLoader;
begin

(*  //--Application.ProcessMessages;
  // ��� ������ � ����� thread ����� ��������� ����� EXIFXtractor:= TExifXtractor.Create;
  EXIFXtractor.ReadExtract(it.UNCPath);
  if not EXIFXtractor.IsActive then
    exit;
  Memo1.Lines.Add(it.UNCPath);
  { Process Loader }
  // �����: { �����: [std, Thumb, MkNotes], insert:false, batch:false }
  // ���.�����: Log_in_memo
  // single : db, collection
  // coupled: db, collection1, collection2
  with Loader do
  begin
    Clear; // ������� �����.��������� ������
    if (poStd in opt) then
      LoadStandardValues(EXIFXtractor.MemExifData);
    if (poMkNotes in opt) and EXIFXtractor.FExifData.HasMakerNote then
      LoadMakerNoteValues(EXIFXtractor.MemMakerNotes, FMakerNoteValueMap);
    if (poThumb in opt) and not(EXIFXtractor.Thumbnail.Graphic = nil) then
      LoadGraphics(EXIFXtractor.Thumbnail);

    if (poBatch in opt) then
      LdrResult := Loader.StoreDefaultDB(it, cbInsert.checked)
    else if (Loader is TExifSingleLoader) then
      LdrResult := (Loader as TExifSingleLoader).StoreToDB(it, FDConnection1,
        DefaultDBName, [DefaultCollection], cbInsert.checked)
    else if (Loader is TExifCoupledLoader) then
      LdrResult := (Loader as TExifCoupledLoader).StoreToDB(it, FDConnection1,
        DefaultDBName, [DefaultMainCollection, DefaultMkNotesCollection],
        cbInsert.checked)
    else
      raise Exception.Create('Undefined Loader');
  end;
  //  if cbShow.checked then
  //  begin
  //    // memo1.Lines.Add(it.UNCPath);
  //    Memo1.Lines.Add(LdrResult);
  //  end;
  // ��� ������ � ����� thread EXIFXtractor.Free; .. ���� ��� ������ �����
*)
end;
{$endregion 3}

// ������� ������ ����� ��������� ������������� --------------------------------
procedure TfmDirFileList.ReloadMakerNoteValueMap(const IniFileName: string);
begin
  // ���������� ������� ��. � Region 1
  FMakerNoteValueMap.Rename(IniFileName, True);
end;

procedure TfmDirFileList.DefineConnectionDef;
var
  oParams: TStrings;
begin
  oParams := TStringList.Create;
  oParams.Add('DriverID=Mongo');
  oParams.Add('Server='+Edit2.Text);
  oParams.Add('Port='+Edit3.Text);
  oParams.Add('Database='+Edit1.Text);
  //  oParams.Add('MoreHosts='+Edit4.Text);
  //  oParams.Add('User_Name=ADDemo');
  //  oParams.Add('Password=a');
  oParams.Add('Pooled=True');
  FDManager.AddConnectionDef('Mongo_Grafics', 'Mongo', oParams);
end;

initialization
  ReportMemoryLeaksOnShutdown := True;

{$REGION '1'}
(*
  procedure TmyTaskQueue<T>.DoNotification(const nuName, nuTitle, nuBody: string);
  var
  MyNotification: TNotification;
  begin
  MyNotification := FNotificationCenter.CreateNotification;
  try
  MyNotification.Name := nuName;
  MyNotification.Title := nuTitle;
  MyNotification.AlertBody := nuBody;
  FNotificationCenter.PresentNotification(MyNotification);
  finally
  MyNotification.Free;
  end;
  end;

  procedure TfmDirFileList.ReloadMakerNoteValueMap;
  var
  ResStream: TResourceStream;
  IniFileName: string;
  begin
  IniFileName := ExtractFilePath(Application.ExeName) + 'MakerNotes.ini';
  if not FileExists(IniFileName) then
  try
  ResStream := TResourceStream.Create(HInstance, 'MakerNotes', RT_RCDATA);
  try
  ResStream.SaveToFile(IniFileName);
  finally
  ResStream.Free;
  end;
  except
  on EResNotFound do Exit;  //someone's been using ResHacker - grrr!!!
  on EFCreateError do Exit; //perhaps we're in Program Files?
  end;
  FMakerNoteValueMap.Rename(IniFileName, True);
  end;

  procedure TfmDirFileList.btMongoClick(Sender: TObject);
  var
  i: Integer;
  BatchArray: TJSONArray;
  tb: TBytes;
  strDoc: string;
  extr: TExifXtractor;
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
  extr := TExifXtractor.Create(ListBox2.Items[i]);
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

  procedure TfmDirFileList.btJSONClick(Sender: TObject);
  var
  i: Integer;
  Writer: TJsonObjectWriter;
  extr: TExifXtractor;
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
  extr := TExifXtractor.Create(ListBox2.Items[i]);
  extr.withThumbN := cbWThumb.Checked;
  // +test Memo1.Lines.Add(extr.AsString);
  try
  Writer.Rewind;
  jv := extr.toJSON(ewloader);
  //Memo1.Lines.Add(jv.ToString);{ ��� Memo1.Lines.Add(Writer.JSON.ToString) }
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

*)
{$ENDREGION}

end.
