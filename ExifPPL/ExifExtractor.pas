unit ExifExtractor;
{
Ответственность:
      считать EXIF элемента в память
      подготовить ключ (PK)
      запустить загрузку- вызвать Loader, передав ему ExifData
      транслировать результат обратно
}

interface

uses
 {$IFDEF VCL} Vcl.Graphics, Jpeg,{$ENDIF}{$IFDEF FMX}FMX.Types,{$ENDIF}
  System.JSON,System.JSON.Types,System.JSON.Writers,System.JSON.Builders,System.JSON.BSON,
  CCR.Exif,
  FireDAC.Comp.Client, FireDAC.Phys.MongoDBWrapper,
  myUtils,
  //ExifWRTLoader,
  ExifMongoHelper;

type
TExifCustomWriter = class
  fok:integer;
end;

TExifXtractor = class
  FFileVolBinded: TFileVolBinded;
  FExifData:TExifData;
  FwithThumbN: boolean;
  FThumbnail: TPicture;
private
  procedure SetwithThumbN(const Value: boolean);
  function GetThumbnail: TPicture;
  function GetisActive: boolean;
public
  constructor Create(const fullFileName: string); overload;
  constructor Create(const fullFileName: string; volInfoRec: TFileVolBinded); overload;
  destructor Destroy; override;

  function AsString: string;
  function toJSON(wrt: TExifCustomWriter): TJSONObject; //TJSONAncestor
  function toMongoDB(mongoConnect:TFDConnection; const insert,batch:boolean):string;
  // function toString(wrt: TJsonObjectWriter): string;
  // function toBSON(wrt: TBSONWriter): TJSONObject; //TJSONAncestor
  // function toStream(stm: TStream): boolean;

  property isActive: boolean read GetisActive;
  property thumbnail:TPicture read GetThumbnail;
  property withThumbN: boolean read FwithThumbN write SetwithThumbN;
end;

implementation

uses
  ConvertersUtils,
  System.SysUtils, System.IOUtils;

var
  FEnv: TMongoEnv;
  FCon: TMongoConnection;

{ TExifExtractor }

function TExifXtractor.AsString: string;
begin
  Result:=format('path:"%s",Disk Type:%s(%d),File system:%s,Vol Serial number:%s,Vol label:%s',
    [ FFileVolBinded.FFullPath,DriveTypeNames[FFileVolBinded.diskType],
      FFileVolBinded.diskType, FFileVolBinded.Filesystem,
      FFileVolBinded.VolSerialNum.ToHexString,FFileVolBinded.VolLabel ]);
  if isActive then Result:=Result+',Active' else  Result:=Result+',notActive';
  if FwithThumbN then Result:=Result+',+Th' else Result:=Result+',-Th';
end;

constructor TExifXtractor.Create(const fullFileName: string;
                                      volInfoRec: TFileVolBinded);
begin
  FFileVolBinded:=volInfoRec;
  FThumbnail:=TPicture.Create;
  FThumbnail.Assign(nil);
  FwithThumbN:=False;

  FExifData:=nil;
  FExifData := TExifData.Create;
  FExifData.EnsureEnumsInRange := False; //as we use case statements rather than array constants, no need to keep this property set to True
  FExifData.LoadFromGraphic(fullFileName); //get ExifData from FullFileName;
 end;

constructor TExifXtractor.Create(const fullFileName: string);
var
  VolumeInfo : TFileVolBinded;
begin
  VolumeInfo:=TFileVolBinded.Create(fullFileName);
  Create(fullFileName,VolumeInfo);
end;

destructor TExifXtractor.Destroy;
begin
  FThumbnail.Free;
  FExifData.Free;
  inherited;
end;

function TExifXtractor.GetisActive: boolean;
begin
  Result:=not FExifData.Empty;
end;

function TExifXtractor.GetThumbnail: TPicture;
begin
  Result := FThumbnail;
  if not FExifData.Thumbnail.Empty then FThumbnail.Assign(FExifData.Thumbnail);
end;

procedure TExifXtractor.SetwithThumbN(const Value: boolean);
begin
  FwithThumbN := Value;
end;

function TExifXtractor.toJSON(wrt: TExifCustomWriter): TJSONObject;
var
  jv, md,fd: TJSONObject;
begin
(*  jv:=TJSONObject.Create; {  : startObject, write filekey }
  Result := jv;
    jv.AddPair('upath', CheckScapeString( ExpandUNCFileName(FFullPath)));
  try
    fd:=TJSONObject.Create;
    fd.AddPair('filedate',ConvertersUtils.DateTimeToStr(FDate));
    fd.AddPair('filename',TPath.GetFileNameWithoutExtension(FFullPath));
    fd.AddPair('ext', ExtractFileExt(FFullPath));
    fd.AddPair('path', CheckScapeString( ExtractFilePath(FFullPath)));
    fd.AddPair('drive', ExtractFileDrive(FFullPath));
    fd.AddPair('driveTypeName',DriveTypeNames[FVolumeInfo.diskType]);
    fd.AddPair('diskType',FVolumeInfo.diskType.ToString);
    fd.AddPair('filesystem',FVolumeInfo.fileSysName);
    fd.AddPair('volSerialNum',FVolumeInfo.serialNum.ToHexString);
    fd.AddPair('volLable',FVolumeInfo.VolLabel);

    jv.AddPair('file',fd);

    if isActive then
    begin
      wrt.LoadStandardValues(FExifData);
      if FExifData.HasMakerNote then
        wrt.LoadMakerNoteValues(FExifData.MakerNote, MakerNoteValueMap);
    end;
    md := wrt.toJSON;
    jv.AddPair('metadata',md); { todo 1 : Close envelope object }
  finally
  end;
*)
end;

function TExifXtractor.toMongoDB(mongoConnect: TFDConnection; const insert,batch :boolean):string;
var
  jv, md,fd: TJSONObject;
begin
(*  jv:=TJSONObject.Create; {  : startObject, write filekey }
  Result := jv;
    jv.AddPair('upath', CheckScapeString( ExpandUNCFileName(FFullPath)));
  try
    fd:=TJSONObject.Create;
    fd.AddPair('filedate',ConvertersUtils.DateTimeToStr(FDate));
    fd.AddPair('filename',TPath.GetFileNameWithoutExtension(FFullPath));
    fd.AddPair('ext', ExtractFileExt(FFullPath));
    fd.AddPair('path', CheckScapeString( ExtractFilePath(FFullPath)));
    fd.AddPair('drive', ExtractFileDrive(FFullPath));
    fd.AddPair('driveTypeName',DriveTypeNames[FVolumeInfo.diskType]);
    fd.AddPair('diskType',FVolumeInfo.diskType.ToString);
    fd.AddPair('filesystem',FVolumeInfo.fileSysName);
    fd.AddPair('volSerialNum',FVolumeInfo.serialNum.ToHexString);
    fd.AddPair('volLable',FVolumeInfo.VolLabel);

    jv.AddPair('file',fd);

    if isActive then
    begin
      wrt.LoadStandardValues(FExifData);
      if FExifData.HasMakerNote then
        wrt.LoadMakerNoteValues(FExifData.MakerNote, MakerNoteValueMap);
    end;
    md := wrt.toJSON;
    jv.AddPair('metadata',md); { todo 1 : Close envelope object }
  finally
  end;
*)
end;

end.
