unit uDirFileListPPL;
{
  Ответственность:
  GUI
  Создание и уничтожение нужного:
  TaskQue
  Loader
  Writer\Builder
  Получение, представление ответов
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
  //ExifWRTLoader,
  System.Notification, ExifMongoLoaderTypesPPL, System.IniFiles, System.Threading;

const
  DefaultIniPath = 'C:\Users\asovtsov\Downloads';
  DefaultConnDefName = 'Mongo_Grafics';

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
    cnames: array of string;
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
  DefineConnectionDef;
  FDManager.Open;
end;

procedure TfmDirFileList.FormDestroy(Sender: TObject);
begin
  FDManager.Close;
  FMakerNoteValueMap.Free;
end;

{$region '2: Работа со списком файлов ---------------------------------------'}
procedure TfmDirFileList.btDelFilesSelectedClick(Sender: TObject);
begin
  if ListBox2.SelCount > 0 then
    ListBox2.DeleteSelected;
  StatusBar1.SimpleText := 'всего: ' + IntToStr(ListBox2.Items.Count);
end;

procedure TfmDirFileList.btFileListClearClick(Sender: TObject);
begin
  ListBox2.Clear;
end;

procedure TfmDirFileList.ListBox1Click(Sender: TObject);
var
  i: Integer;
begin
  StatusBar1.SimpleText := '...Начитываем';
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
              + ' всего: ' + IntToStr(ListBox2.Items.Count)+ '+' + IntToStr(mdList.Count);
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
  // Путь к папке, в которой нужно произвести поиск.
  // todo 1 : Начальное значение выбираем равным пути к той папке, в которой расположена наша программа.
  if leRoot.Text = '' then
    leRoot.Text := 'C:\Users\asovtsov\Downloads';
  // ExtractFilePath(ParamStr(0));
  // Диалог выбора папки.
  Dir := leRoot.Text;
  if not Vcl.FileCtrl.SelectDirectory(Dir, [sdPerformCreate, sdPrompt], 100)
  then // sdAllowCreate,
    exit;
  leRoot.Text := ExcludeTrailingPathDelimiter(Dir); // Dir
  // Если конечный слеш присутствует, то убираем его.
  ListBox1.Items.Clear;
  ListBox2.Items.Clear;
  ListBox1.Items.Add(leRoot.Text);
  GetDirectories(leRoot.Text, ListBox1.Items);
  sw.Stop;
  StatusBar1.SimpleText := 'msec: ' + sw.ElapsedMilliseconds.ToString;
end;
{$endregion 2}

{$Region '3: обработка EXIF -------------------------------------------------'}

{$region '//procedure TfmDirFileList.btMongoClickPPL(Sender: TObject);'}
//var
//  mxcnt: Integer;
//  LoopResult: TParallel.TLoopResult;
//begin
//  //DefineConnectionDef;
//  sw := TStopwatch.StartNew;
//  Memo1.Clear;
//  ActivityIndicator1.Animate := True;
//  StatusBar1.SimpleText := '...Загружаем';
//  // подготовить аргументы
//  opt := [];
//  if cbStandards.checked then
//    include(opt, poStd);
//  if cbWThumb.checked then
//    include(opt, poThumb);
//  if cbMkNotes.checked then
//    include(opt, poMkNotes);
//  if cbBatch.checked then
//    include(opt, poBatch);
//
//      if RadioGroup1.ItemIndex = 0 then
//        cnames:= [DefaultCollection]
//      else
//      begin
//        include(opt, poMkNotes); // иначе нет смысла писать в отдельную коллекцию
//        cnames:=[DefaultMainCollection, DefaultMkNotesCollection];
//      end;
//
//  mxcnt := ListBox2.Items.Count - 1;
//  TTask.Run(
//    procedure
//    var
//      cnt: integer;
//      Loader: TExifMongoLoader;
//      EXIFXtractor: TExifXtractor;
//    begin
//      EXIFXtractor := TExifXtractor.Create;
//      if RadioGroup1.ItemIndex = 0 then begin
//        Loader := TExifSingleLoader.Create(DefaultConnDefName, opt);
//      end
//      else
//      begin
//        include(opt, poMkNotes); // иначе нет смысла писать в отдельную коллекцию
//        Loader := TExifCoupledLoader.Create(DefaultConnDefName, opt);
//      end;
//      cnt:=0;
//      try
//        LoopResult := TParallel.For(0, mxcnt,
//          procedure(aIndex: Integer)
//          begin
//            //здесь магия обработки  заглушка:            sleep(100);
//            ItemToMongoPPL(EXIFXtractor,Loader,TFileVolBinded.Create(ListBox2.Items[aIndex]));
//            if cbShow.checked then
//            TThread.Queue(nil, //Queue(TThread.Current,
//              procedure
//              begin
//                inc(cnt);
//                Memo1.Lines.Add('#'+cnt.ToString +' '+ ListBox2.Items[aIndex]);
//                //Memo1.Lines.Add(LdrResult);
//              end);
//          end);
//
//        if LoopResult.Completed then
//        begin
//          TThread.Synchronize(nil, // TThread.CurrentThread,
//            procedure
//            begin
//              Memo1.Lines.Add('--Завершено--');
//            end);
//        end;
//      finally
//        FDManager.CloseConnectionDef(DefaultConnDefName);
//        ExifXtractor.Free;
//        Loader.Free;
//          TThread.Queue(nil, // TThread.CurrentThread,
//            procedure
//            begin
//              ActivityIndicator1.Animate := False;
//              sw.Stop;
//              StatusBar1.SimpleText := 'msec: ' +
//                sw.ElapsedMilliseconds.ToString + ' всего: ' + IntToStr(mxcnt+1);
//            end);
//      end;
//    end);
//end;
{$endregion}

procedure TfmDirFileList.btMongoClick(Sender: TObject);
var
  mxcnt: Integer;
  LoopResult: TParallel.TLoopResult;
      cnt: integer;
      Loader: TExifMongoLoader;
      EXIFXtractor: TExifXtractor;

      //aIndex: integer;
      LdrResult: string;
begin
  //DefineConnectionDef;
  sw := TStopwatch.StartNew;
  Memo1.Clear;
  ActivityIndicator1.Animate := True;
  StatusBar1.SimpleText := '...Загружаем';
  // подготовить аргументы
  opt := [];
  if cbStandards.checked then
    include(opt, poStd);
  if cbWThumb.checked then
    include(opt, poThumb);
  if cbMkNotes.checked then
    include(opt, poMkNotes);
  if cbBatch.checked then
    include(opt, poBatch);

  if RadioGroup1.ItemIndex = 0 then
    cnames:= [DefaultCollection]
  else
  begin
    include(opt, poMkNotes); // иначе нет смысла писать в отдельную коллекцию
    cnames:=[DefaultMainCollection, DefaultMkNotesCollection];
  end;

  mxcnt := ListBox2.Items.Count - 1;
  TTask.Run(
    procedure
    var
//      cnt: integer;
//      Loader: TExifMongoLoader;
//      EXIFXtractor: TExifXtractor;
       aIndex:integer;
    begin
      EXIFXtractor := TExifXtractor.Create;
      if RadioGroup1.ItemIndex = 0 then begin
        Loader := TExifSingleLoader.Create(DefaultConnDefName, opt);
      end
      else
      begin
        include(opt, poMkNotes); // иначе нет смысла писать в отдельную коллекцию
        Loader := TExifCoupledLoader.Create(DefaultConnDefName, opt);
      end;
      cnt:=0;
      try
//        LoopResult := TParallel.For(0, mxcnt,
//          procedure(aIndex: Integer)
        for aIndex := 0 to mxcnt do
          begin
            //здесь магия обработки  заглушка:            sleep(100);
            LdrResult:=ItemToMongoPPL(EXIFXtractor,Loader,TFileVolBinded.Create(ListBox2.Items[aIndex]));
            if cbShow.checked then
            TThread.Queue(nil, //TThread.Current,
              procedure
              begin
                inc(cnt);
                Memo1.Lines.Add('#'+cnt.ToString +' '+ ListBox2.Items[aIndex]);
                Memo1.Lines.Add(LdrResult);
                Memo1.Lines.Add(' ');
              end
              );
          end
          ; //);

//        if LoopResult.Completed then
//        begin
//          TThread.Synchronize(nil, // TThread.CurrentThread,
//            procedure
//            begin
//              Memo1.Lines.Add('--Завершено--');
//            end);
//        end;
      finally
        FDManager.CloseConnectionDef(DefaultConnDefName);
        ExifXtractor.Free;
        Loader.Free;
          TThread.Queue(nil, // TThread.CurrentThread,
            procedure
            begin
              ActivityIndicator1.Animate := False;
              sw.Stop;
              StatusBar1.SimpleText := 'msec: ' +
                sw.ElapsedMilliseconds.ToString + ' всего: ' + IntToStr(mxcnt+1);
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
  // опции: { части: [std, Thumb, MkNotes], insert:false, batch:false }
  // доп.опции: Log_in_memo
  // single : db, collection
  // coupled: db, collection1, collection2
//-------------------------------------------------------------------------------------
//exit; //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  with aLoader do
  begin
    Clear; // очистка внутр.хранилища частей
    if (poStd in opt) then
      LoadStandardValues(eextractor.MemExifData);
    if (poMkNotes in opt) and eextractor.FExifData.HasMakerNote then
      LoadMakerNoteValues(eextractor.MemMakerNotes, FMakerNoteValueMap);
    if (poThumb in opt) and not(eextractor.Thumbnail.Graphic = nil) then
      LoadGraphics(eextractor.Thumbnail);

    LdrResult := aLoader.StoreToDB(it, //nil {FDConnection1},
        DefaultDBName, cnames, cbInsert.checked);

//    if (poBatch in opt) then
//      LdrResult := aLoader.StoreDefaultDB(it, cbInsert.checked)

//    LdrResult := (aLoader as TExifSingleLoader).StoreToDB(it, //nil {FDConnection1},
//        DefaultDBName, [DefaultCollection], cbInsert.checked)
//    else if (aLoader is TExifCoupledLoader) then
//      LdrResult := (aLoader as TExifCoupledLoader).StoreToDB(it, nil {FDConnection1},
//        DefaultDBName, [DefaultMainCollection, DefaultMkNotesCollection],
//        cbInsert.checked)
//    else
//      raise Exception.Create('Undefined Loader');
  end;
  Result:=LdrResult;
end;

function TfmDirFileList.ItemToMongo(it: TFileVolBinded): string;
var
  LdrResult: string;
  Loader: TExifMongoLoader;
begin

(*  //--Application.ProcessMessages;
  // для работы в своем thread нужно создавать здесь EXIFXtractor:= TExifXtractor.Create;
  EXIFXtractor.ReadExtract(it.UNCPath);
  if not EXIFXtractor.IsActive then
    exit;
  Memo1.Lines.Add(it.UNCPath);
  { Process Loader }
  // опции: { части: [std, Thumb, MkNotes], insert:false, batch:false }
  // доп.опции: Log_in_memo
  // single : db, collection
  // coupled: db, collection1, collection2
  with Loader do
  begin
    Clear; // очистка внутр.хранилища частей
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
  // для работы в своем thread EXIFXtractor.Free; .. если был создан здесь
*)
end;
{$endregion 3}

// Утилита чтения карты элементов производителя --------------------------------
procedure TfmDirFileList.ReloadMakerNoteValueMap(const IniFileName: string);
begin
  // предыдущий вариант см. в Region 1
  FMakerNoteValueMap.Rename(IniFileName, True);
end;

procedure TfmDirFileList.DefineConnectionDef;
var
  oParams: TStrings;
begin
  oParams := TStringList.Create;
  try
  oParams.Add('DriverID=Mongo');
  oParams.Add('Server='+Edit2.Text);
  oParams.Add('Port='+Edit3.Text);
  oParams.Add('Database='+Edit1.Text);
  //  oParams.Add('MoreHosts='+Edit4.Text);
  //  oParams.Add('User_Name=ADDemo');
  //  oParams.Add('Password=a');
  //oParams.Add('Pooled=True');
  FDManager.AddConnectionDef(DefaultConnDefName, 'Mongo', oParams);
  finally
    oParams.Free;
  end;
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

*)
{$ENDREGION}

end.
