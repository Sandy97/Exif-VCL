unit uDirFileList;
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
  myUtils, //mytaskQueue, //ExifWRTLoader,
  ExifMemoContainer,
  System.Notification, ExifMongoLoaderTypes, System.IniFiles, System.Threading,
  Vcl.Imaging.pngimage;

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
    FDConnection1: TFDConnection;
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
    btCancel: TButton;
    grpThumbnail: TGroupBox;
    imgThumbnail: TImage;
    NotificationCenter1: TNotificationCenter;
    procedure ListBox1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure btMongoClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btFileListClearClick(Sender: TObject);
    procedure btDelFilesSelectedClick(Sender: TObject);
    procedure FDConnection1BeforeConnect(Sender: TObject);
    procedure ToggleSwitch1Click(Sender: TObject);
    procedure btCancelClick(Sender: TObject);
    procedure imgThumbnailClick(Sender: TObject);
    procedure ListBox2Click(Sender: TObject);
  private
    { Private declarations }
    //CCRValueMap: string;
    //JQueue: TmyTaskQueue<TFileVolBinded>;
    FMakerNoteValueMap: TMemIniFile;
    EXIFXtractor: TExifXtractor;
    Loader: TExifMongoLoader;
    opt: TPartOptSet;
    function ItemToMongo(it:TFileVolBinded): string;
    procedure ReloadMakerNoteValueMap(const IniFileName:string);
    procedure UpdateButtons(nstate: boolean);
    function rplurals(n: integer; subj: string): string;
    procedure DoNotification(const nuName, nuTitle, nuBody: string);
  public
    { Public declarations }
    cTSK: ITask;
  end;

var
  fmDirFileList: TfmDirFileList;

implementation

{$R *.dfm}

uses
  //System.JSON, System.JSON.Writers,
  System.Diagnostics ;

var
  sw: TStopwatch;

function TfmDirFileList.rplurals(n: integer; subj: string): string;
begin
  if n = 1 then // <задан>
    Result := subj + 'ие'  // subj+'е'
  else if (n > 0) and (n < 5) then
    Result := subj + 'ия'  // subj+'я'
  else
    Result := subj + 'ий'; // subj+'й';
end;

procedure TfmDirFileList.DoNotification(const nuName, nuTitle, nuBody: string);
var
  MyNotification: TNotification;
begin
  MyNotification := NotificationCenter1.CreateNotification;
  try
    MyNotification.Name := nuName;
    MyNotification.Title := nuTitle;
    MyNotification.AlertBody := nuBody;
    NotificationCenter1.PresentNotification(MyNotification);
  finally
    MyNotification.Free;
  end;
end;

procedure TfmDirFileList.FDConnection1BeforeConnect(Sender: TObject);
begin
  with (Sender as TFDConnection).Params do
  begin
    Clear;
    Add('DriverID=Mongo');
    Add('Database='+Edit1.Text);
    Add('Server='+Edit2.Text);
    Add('Port='+Edit3.Text);
    //    Add('User_Name=ADDemo');
    //    Add('Password=a');
  end;
end;

procedure TfmDirFileList.FormCreate(Sender: TObject);
var
  i: Integer;
  IniFileName :string;
begin
  //CCRValueMap:='';
  FMakerNoteValueMap := TMemIniFile.Create('');
  IniFileName := ExtractFilePath(Application.ExeName) + 'MakerNotes.ini';
  ReloadMakerNoteValueMap(IniFileName);
  //JQueue:=TmyTaskQueue<TFileVolBinded>.Create;
  EXIFXtractor:= TExifXtractor.Create;    //это может помешать параллельной работе TASKQueue
  opt:= [];
  i := 0;
  while i < ListBox1.Items.Count do
  begin
    GetDirectories(ListBox1.Items[i], ListBox1.Items);
    Inc(i);
  end;
end;

procedure TfmDirFileList.FormDestroy(Sender: TObject);
begin
  EXIFXtractor.Free;
  //JQueue.Free;
  FMakerNoteValueMap.Free;
end;

procedure TfmDirFileList.imgThumbnailClick(Sender: TObject);
begin
  //
end;

procedure TfmDirFileList.btDelFilesSelectedClick(Sender: TObject);
begin
  if ListBox2.SelCount > 0 then ListBox2.DeleteSelected;
  StatusBar1.SimpleText := 'всего: '+ IntToStr(ListBox2.Items.Count);
end;

procedure TfmDirFileList.btFileListClearClick(Sender: TObject);
begin
  ListBox2.Clear;
end;
procedure TfmDirFileList.UpdateButtons(nstate:boolean);
begin
  btMongo.Enabled := nstate;
  btCancel.Enabled := not btMongo.Enabled;
end;

procedure TfmDirFileList.btMongoClick(Sender: TObject);
var
  fls: integer;
  AcquiredException: Exception;
begin
  sw := TStopwatch.StartNew;
  Memo1.Clear;
  opt:=[];
  if cbStandards.checked then include(opt,poStd);
  if cbWThumb.checked then include(opt,poThumb);
  if cbMkNotes.checked then include(opt,poMkNotes);
  if cbBatch.checked then include(opt,poBatch);

  // Новый вариант,
  if RadioGroup1.ItemIndex = 0 then
    //подготовить аргументы
    Loader:=TExifSingleLoader.Create(FDConnection1,opt)
  else begin
    //подготовить аргументы
    include(opt,poMkNotes);  //иначе нет смысла писать в отдельную коллекцию
    Loader:=TExifCoupledLoader.Create(FDConnection1,opt);
  end;
  //Старый вариант: Loader:=TExifMongoLoader.Create(FDConnection1,opt);
  fls:=ListBox2.Items.Count;
  UpdateButtons(False);
  ActivityIndicator1.Animate:=True;
  StatusBar1.SimpleText := '...Обрабатываем файлов: ' + fls.ToString;
  cTSK := TTask.Run(
    procedure
    var
      i: integer;
    begin
      try
        try
          for i:=0 to ListBox2.Items.Count-1 do begin
            if TTask.CurrentTask.Status = TTaskStatus.Canceled then
              Exit;
            TThread.Synchronize(nil,
              procedure
              begin
                itemToMongo(TFileVolBinded.Create(ListBox2.Items[i]));
              end);
          end;
        finally
          Loader.Free;
          TThread.Synchronize(nil,
            procedure
            begin
              ActivityIndicator1.Animate:=False;
              sw.Stop;
              StatusBar1.SimpleText := 'msec: ' + sw.ElapsedMilliseconds.ToString;
              memo1.Lines.Add('*** конец обработки ***');
              UpdateButtons(True);
              DoNotification('tskqueue', 'Info', format('Завершено %d %s из %d',
                  [i, rplurals(i, 'задан'),fls]));
            end);
        end;
      except
      on e: Exception do
        begin
          AcquiredException := AcquireExceptionObject;
          TThread.Synchronize(nil, //TThread.CurrentThread,
            procedure
            begin
              raise AcquiredException;
            end);
        end
      end;
    end);
end;

procedure TfmDirFileList.btCancelClick(Sender: TObject);
begin
  if cTsk.Status = TTaskStatus.Running then
    cTsk.Cancel;
end;

function TfmDirFileList.ItemToMongo(it: TFileVolBinded): string;
var
  LdrResult: string;
begin
  Application.ProcessMessages;
  //для работы в своем thread нужно создавать здесь EXIFXtractor:= TExifXtractor.Create;
  EXIFXtractor.ReadExtract(it.UNCPath);
  if not EXIFXtractor.IsActive then exit;
  memo1.Lines.Add(it.UNCPath);
  { Process Loader}
          // опции: { части: [std, Thumb, MkNotes], insert:false, batch:false }
          // доп.опции: Log_in_memo
          //            single : db, collection
          //            coupled: db, collection1, collection2
  with Loader do begin
    Clear;             //очистка внутр.хранилища частей
    if  (poStd in opt)  then
      LoadStandardValues(ExifXtractor.MemExifData);
    if (poMkNotes in opt) and EXIFXtractor.FExifData.HasMakerNote then
      LoadMakerNoteValues(ExifXtractor.MemMakerNotes, FMakerNoteValueMap);
    if (poThumb in opt) and not (ExifXtractor.Thumbnail.Graphic = nil) then
      LoadGraphics(ExifXtractor.Thumbnail);

    if (poBatch in opt) then
      LdrResult := Loader.StoreDefaultDB(it,cbInsert.Checked)
    else if (Loader is TExifSingleLoader) then
      LdrResult := (Loader as TExifSingleLoader).StoreToDB(it,FDConnection1,
                    DefaultDBName,[DefaultCollection],cbInsert.Checked)
    else if (Loader is TExifCoupledLoader) then
      LdrResult := (Loader as TExifCoupledLoader).StoreToDB(it,FDConnection1,
                    DefaultDBName,[DefaultMainCollection,DefaultMkNotesCollection],
                    cbInsert.Checked)
    else
      raise Exception.Create('Undefined Loader');
  end;
  if cbShow.Checked then begin
    memo1.Lines.Add(LdrResult);  //memo1.Lines.Add(it.UNCPath);
  end;
  // для работы в своем thread EXIFXtractor.Free; .. если был создан здесь
end;

procedure TfmDirFileList.ListBox1Click(Sender: TObject);
var
  i: Integer;
  AcquiredException: Exception;
begin
  StatusBar1.SimpleText := '...Начитываем';
  UpdateButtons(False);
  cTSK := TTask.Run(
    procedure
    var
      mdList: TStringList;
    begin
      mdList := TStringList.Create;
      try
        sw := TStopwatch.StartNew;
        try
          if TTask.CurrentTask.Status = TTaskStatus.Canceled then
          begin
            TThread.Queue(TThread.CurrentThread,
              procedure
              begin
                sw.Stop;
                StatusBar1.SimpleText := 'msec: ' +
                  sw.ElapsedMilliseconds.ToString + ' Остановлено ';
              end);
            Exit;
          end;
          btTdirectoryClick(ListBox1.Items[ListBox1.ItemIndex],
            Trim(edtFileMask.Text), mdList);
          TThread.Synchronize(nil, // TThread.CurrentThread,
            procedure
            begin
              ListBox2.Items.AddStrings(mdList);
              sw.Stop;
              StatusBar1.SimpleText := 'msec: ' +
                sw.ElapsedMilliseconds.ToString + ' всего: ' +
                IntToStr(ListBox2.Items.Count) + ' (+' +
                IntToStr(mdList.Count) + ')';
              UpdateButtons(True);
            end);
        finally
          mdList.Free;
        end;
      except
        on e: Exception do
        begin
          AcquiredException := AcquireExceptionObject;
          TThread.Queue(TThread.CurrentThread,
            procedure
            begin
              raise AcquiredException;
            end);
        end
      end;
    end);
end;

procedure TfmDirFileList.ListBox2Click(Sender: TObject);
begin
  try
    imgThumbnail.Picture.LoadFromFile(ListBox2.Items[ListBox2.ItemIndex]);
  except
  end;
end;

procedure TfmDirFileList.SpeedButton1Click(Sender: TObject);
var
  Dir: string;
begin
  sw := TStopwatch.StartNew;
  // Путь к папке, в которой нужно произвести поиск.
  //todo 1 : Начальное значение выбираем равным пути к той папке, в которой расположена наша программа.
  if leRoot.Text = '' then
    leRoot.Text := 'C:\Users\asovtsov\Downloads';   // ExtractFilePath(ParamStr(0));
  // Диалог выбора папки.
  Dir := leRoot.Text;
  if not Vcl.FileCtrl.SelectDirectory(Dir, [sdPerformCreate,sdPrompt], 100) then //sdAllowCreate,
    Exit;
  leRoot.Text := ExcludeTrailingPathDelimiter(Dir); //Dir
  // Если конечный слеш присутствует, то убираем его.
  ListBox1.Items.Clear;
  ListBox2.Items.Clear;
  ListBox1.Items.Add(leRoot.Text);
  GetDirectories(leRoot.Text, ListBox1.Items);
  sw.Stop;
  StatusBar1.SimpleText := 'msec: ' + sw.ElapsedMilliseconds.ToString;
end;

procedure TfmDirFileList.ToggleSwitch1Click(Sender: TObject);
begin
  try
  FDConnection1.Connected := (Sender as TToggleSwitch).State = tssOn;
  except
    (Sender as TToggleSwitch).State := tssOff;
    raise;
  end;
end;

procedure TfmDirFileList.ReloadMakerNoteValueMap(const IniFileName:string);
begin
  // предыдущий вариант см. в Region 1
  FMakerNoteValueMap.Rename(IniFileName, True);
end;

initialization
ReportMemoryLeaksOnShutdown := True;

{$region '1'}
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
{$endregion}

end.
