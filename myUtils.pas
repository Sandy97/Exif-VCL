unit myUtils;

interface

uses
  Winapi.Windows, Winapi.Messages, Vcl.Graphics,
 {$IFDEF VCL}  Jpeg,{$ENDIF}{$IFDEF FMX}FMX.Types,{$ENDIF}
  System.SysUtils, System.Variants,  System.Classes, System.Types;

type
  DRVTYPECONST = DRIVE_UNKNOWN..DRIVE_RAMDISK;
const
  drvseeking: set of DRVTYPECONST = [
    DRIVE_UNKNOWN,      // = 0;
    DRIVE_NO_ROOT_DIR,  // = 1;
    DRIVE_REMOVABLE,    // = 2;
    DRIVE_FIXED,        // = 3;
    DRIVE_REMOTE,       // = 4;
    DRIVE_CDROM,        // = 5;
    DRIVE_RAMDISK       // = 6;
  ];

  DriveTypeNames : array [DRIVE_UNKNOWN..DRIVE_RAMDISK] of string = (
    'UNKNOWN',
    'NO_ROOT_DIR',
    'REMOVABLE',
    'FIXED',
    'REMOTE',
    'CDROM',
    'RAMDISK'
  );

type
  HDDVolumeInfo = record
    serialNum,
    diskType:DWORD;
    fileSysName: string;
    VolLabel: string;
  end;

  TFileVolBinded = record
    FVolumeInfo: HDDVolumeInfo;
    FDate: TDatetime;
    FFullPath: string;
    FUNCPath: string;
  private
    function GetDiskType: DWORD;
    function GetDrive: string;
    function GetDriveTypeName: string;
    function GetExt: string;
    function getFilename: string;
    function GetFileSystem: string;
    function GetSerialNum: DWORD;
    function GetVolLabel: string;
    function GetPath: string;
  public
    constructor Create(fn:String);
    property Filedate:TDatetime read FDate;
    property UNCPath:string read FUNCPath;
    property Path:string read GetPath;
    property Filename: string read GetFilename;
    property Ext: string read GetExt;
    property Drive: string read GetDrive;
    property DriveTypeName: string read GetDriveTypeName;
    property DiskType: DWORD read GetDiskType;
    property Filesystem: string read GetFileSystem;
    property VolSerialNum: DWORD read GetSerialNum;
    property VolLabel: string read GetVolLabel;
  end;

(*
//laVSerial.Caption := HDDVolumeInfo.serialNum.ToHexString;
//laVLabel.Caption := HDDVolumeInfo.VolLabel;
//laFsystem.Caption := HDDVolumeInfo.fileSysName;
//laDrvType.Caption:=format('dType=%d, "%s"',[HDDVolumeInfo.diskType, DriveTypeNames[HDDVolumeInfo.diskType]]);
*)

function GetVolumeLabel(const DriveChar: Char): string;
function GetVolumeInfo(const DrivePath: String): HDDVolumeInfo;
function getHDDVolumeInfo(const DrivePath: string): HDDVolumeInfo;
procedure GetDirectories(const DirStr : string; Items : TStrings);
procedure GetFiles(const DirStr : string; mask: string; Items : TStrings);
function CheckScapeString(const Value: string): string;
function ImageToBytes(img:TGraphic): TBytes;
procedure ScanDir(StartDir: string; Mask: string; List: TStrings);
procedure btTdirectoryClick(const StartDir: string; const Mask: string; List: TStrings);

implementation

uses
  System.Diagnostics, System.IOUtils;

var
  sw: TStopwatch;

procedure GetDirectories(const DirStr : string; Items : TStrings);
var
  DirInfo: TSearchRec;
  r : Integer;
  path: string;
begin
  Path := IncludeTrailingPathDelimiter(DirStr);
  r := FindFirst(Path + '*.*', FaDirectory, DirInfo);
  while r = 0 do  begin
    //Application.ProcessMessages;
    if ((DirInfo.Attr and FaDirectory = FaDirectory) and
         (DirInfo.Name <> '.') and
         (DirInfo.Name <> '..'))  then
      Items.Add(DirStr + '\' + DirInfo.Name);
    r := FindNext(DirInfo);
  end;
  System.SysUtils.FindClose(DirInfo);
end;

procedure GetFiles(const DirStr : string; mask: string; Items : TStrings);
var
  DirInfo: TSearchRec;
  r : Integer;
  Path: string;
begin
  if mask = '' then
    mask := '*.jpg';
  Path := IncludeTrailingPathDelimiter(DirStr);
  r := FindFirst(Path + mask, FaAnyfile, DirInfo);
  while r = 0 do  begin
    //Application.ProcessMessages;
    if ((DirInfo.Attr and FaDirectory <> FaDirectory) and
        (DirInfo.Attr and faVolumeID <> FaVolumeID)) then
      Items.Add(DirStr + '\' + DirInfo.Name);
    r := FindNext(DirInfo);
  end;
  System.SysUtils.FindClose(DirInfo);
end;


function GetVolumeLabel(const DriveChar: Char): string;
var
  NotUsed: DWORD;
  VolumeFlags: DWORD;
  VolumeInfo: array [0 .. MAX_PATH] of Char;
  VolumeSerialNumber: DWORD;
  Buf: array [0 .. MAX_PATH] of Char;
begin
  GetVolumeInformation(PChar(DriveChar + ':\'),
    Buf, SizeOf(VolumeInfo), @VolumeSerialNumber, NotUsed,
    VolumeFlags, nil, 0);
  SetString(Result, Buf, StrLen(Buf)); { Set return result }
  Result := AnsiUpperCase(Result)
end;

function GetVolumeInfo(const DrivePath: string): HDDVolumeInfo;
var
  NotUsed: DWORD;
  VolumeFlags: DWORD;
  VolumeInfo: array [0 .. MAX_PATH] of Char;
  VolumeSerialNumber: DWORD;
  VolumeFSysName: array [0 .. MAX_PATH] of Char;
  Buf: array [0 .. MAX_PATH] of Char;
  RecVolumeInfo: HDDVolumeInfo;
  rc: boolean;
begin
  Result := RecVolumeInfo;
  rc:=GetVolumeInformation(PChar(DrivePath),
    Buf, SizeOf(VolumeInfo), @VolumeSerialNumber, NotUsed,
    VolumeFlags, VolumeFSysName, SizeOf(VolumeInfo));
  SetString(Result.VolLabel, Buf, StrLen(Buf)); { Set return result }
  SetString(Result.fileSysName, VolumeFSysName, StrLen(VolumeFSysName)); { Set return result }
  Result.serialNum := VolumeSerialNumber;
end;

function getHDDVolumeInfo(const DrivePath: string): HDDVolumeInfo;
var
  //VolInfoRec: HDDVolumeInfo;
  Drive: String;
  DriveLetter: String;
  VolDriveType: DRVTYPECONST;
begin
  Drive:= ExtractFileDrive(DrivePath);
  DriveLetter := Drive + '\';
  Result:=GetVolumeInfo(PChar(DriveLetter));
  VolDriveType:=GetDriveType(PChar(DriveLetter));
  Result.diskType:=VolDriveType;
end;

function StreamToByteArray(Stream: TStream): TBytes;
begin
  if Assigned(Stream) then   // Check stream
  begin
     Stream.Position:=0;    // Reset stream position
     SetLength(result, Stream.Size); // Allocate size
     Stream.Read(result[0], Stream.Size); // Read contents of stream
  end
  else
     SetLength(result, 0);  // Clear result
end;

function CheckScapeString(const Value: string): string;
var
  I: Integer;
  tmpStr: string;
begin
  Result := '';
  tmpStr := '';
  for I := 1 to Length(Value) do
    if Value[I] in [ '''', '\', '"', ';']
      then tmpStr := tmpStr + '\' + Value[I]
      else tmpStr := tmpStr + Value[I];
  Result := tmpStr;
end;

function ImageToBytes(img:TGraphic): TBytes;
var
  stream: TBytesStream;
begin
  stream:=TBytesStream.Create;
  try
    img.SaveToStream(stream);
    Result:=stream.Bytes; // Read contents of stream
    SetLength(Result, stream.Size);
  finally
    stream.Free;
  end;
end;

(*
function BytesToImage(src:TBytes;Grafictype: (jpeg,bmp,png, ico)):TGraphic
*)

{ TFileVolBinded }

constructor TFileVolBinded.create(fn: String);
begin
  FFullPath:=fn;
  FUNCPath:=ExpandUNCFileName(FFullPath);
  FileAge(FFullPath, FDate, True);
  FVolumeInfo := myUtils.getHDDVolumeInfo(FFullPath);
end;

function TFileVolBinded.GetDiskType: DWORD;
begin
  Result:=FVolumeInfo.diskType;
end;

function TFileVolBinded.GetDrive: string;
begin
  Result:=ExtractFileDrive(FFullPath);
end;

function TFileVolBinded.GetDriveTypeName: string;
begin
  Result:=DriveTypeNames[FVolumeInfo.diskType];
end;

function TFileVolBinded.GetExt: string;
begin
  Result:=ExtractFileExt(FFullPath);
end;

function TFileVolBinded.GetFilename: string;
begin
  Result:=TPath.GetFileNameWithoutExtension(FFullPath);
end;

function TFileVolBinded.GetFileSystem: string;
begin
  Result:=FVolumeInfo.fileSysName;
end;

function TFileVolBinded.GetPath: string;
begin
  Result:=ExtractFilePath(FFullPath)
end;

function TFileVolBinded.GetSerialNum: DWORD;
begin
  Result:=FVolumeInfo.serialNum;
end;

function TFileVolBinded.GetVolLabel: string;
begin
  Result:=FVolumeInfo.VolLabel;
end;

procedure ScanDir(StartDir: string; Mask: string; List: TStrings);
var
  SearchRec: TSearchRec;
begin
  //if Mask = '' then
    Mask := '*.*';
  if StartDir[Length(StartDir)] <> '\' then
    StartDir := StartDir + '\';
  if FindFirst(StartDir + Mask, faAnyFile+faDirectory, SearchRec) = 0 then
  begin
    repeat
      //Application.ProcessMessages;
      if (SearchRec.Attr and faDirectory) <> faDirectory then
        List.Add(StartDir + SearchRec.Name)
      else if (SearchRec.Name <> '..') and (SearchRec.Name <> '.') then
      begin
        List.Add(StartDir + SearchRec.Name + '\');
        ScanDir(StartDir + SearchRec.Name + '\', Mask, List);
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

procedure btTdirectoryClick(const StartDir: string; const Mask: string; List: TStrings);
var
  I: Integer;
  LList: TStringDynArray;
  LSearchOption: TSearchOption;
  exxx: TStringlist;
begin
  { Select the search option }
  // if cbDoRecursive.Checked then
  LSearchOption := TSearchOption.soAllDirectories;
  try // if Mask <> '' then begin
    exxx := TStringlist.Create;
    exxx.DelimitedText := mask;
    // end;

    try
      { For all entries use GetFileSystemEntries method }
      //LList := TDirectory.GetFileSystemEntries(StartDir, LSearchOption, nil);
      LList := TDirectory.GetFileSystemEntries(StartDir, LSearchOption,
        function(const Path: string; const SearchRec: TSearchRec): Boolean
        begin
          if exxx.IndexOf(ExtractFileExt(SearchRec.Name)) <> -1 then
          result:=True
          else Result:=False;
        end);
    except
      { Catch the possible exceptions }
      // MessageDlg('Incorrect path or search mask', mtError, [mbOK], 0);
      Exit;
    end;

    { Populate the memo with the results }
    for I := 0 to Length(LList) - 1 do
      List.Add(LList[I]);
  finally
    exxx.Free;
  end;
end;

end.

(*
procedure TfmDirFileList.btTdirectoryClick(Sender: TObject);
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
*)

(*
procedure TfrmMain.btLoadThumbClick(Sender: TObject);
var
  oIter: TJSONIterator;
  sIdent: String;
  oStr: TBytesStream;
  oDoc: TMongoDocument;
  oCrs: IMongoCursor;
  i: Integer;
  ng: TJPEGImage;
begin
  oCrs := FCon['Grafics']['tst_meta']
   .Find()
   ; //.Limit(5);
  i:=1;
  while oCrs.Next do
    try
      oDoc:=oCrs.Doc;
      //Memo1.Lines.Add(oDoc.AsJSON + #13+#10);
      Memo1.Lines.Add('#'+i.ToString);
      oIter := oDoc.Iterator;
      sIdent := '';
      try
        if oIter.Find('metadata.thumbnail') then
        begin
          oStr := TBytesStream.Create(oIter.AsBytes);
          ng:= TJPEGImage.Create;
          try
            ng.LoadFromStream(oStr);
            Image1.Picture.Assign(ng);
          finally
            ng.Free;
            oStr.Free;
          end;
          memo1.Lines.Add('Look at the Thumbnail');
          Image1.Repaint;
          sleep(300);
        end
        else
          memo1.Lines.Add('Thumbnail not found');
        inc(i);
      finally
        oIter.Free;
      end;

    finally
      //oDoc.Free;
    end;
    *)
