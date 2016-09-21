unit ExifMemoContainer;
{
Ответственность:
      считать EXIF элемента в память
      подготовить ключ (PK)
}

interface

uses

 Vcl.Graphics, Jpeg,
 {$IFDEF VCL}
 {$ENDIF}
 {$IFDEF FMX}FMX.Types,{$ENDIF}
  System.JSON,System.JSON.Types,System.JSON.Writers,System.JSON.Builders,System.JSON.BSON,
  CCR.Exif,
  FireDAC.Comp.Client, FireDAC.Phys.MongoDBWrapper,
  myUtils;

type
//TExifCustomWriter = class
//  fok:integer;
//end;

TExifXtractor = class
  FFileVolBinded: TFileVolBinded;
  FExifData:TExifData;
  //FExitMakerNotes:TExifMakerNote;
  FThumbnail: TPicture;
private
  function GetThumbnail: TPicture;
  function GetIsActive: boolean;
public
  constructor Create; overload;
  constructor Create(const fullFileName: string); overload;
  constructor Create(const fullFileName: string; volInfoRec: TFileVolBinded); overload;
  destructor Destroy; override;
  function AsString: string;

  procedure ReadExtract(const fullFileName: string);
  function FileKeyinfo:TFileVolBinded;
  function MemExifData:TExifData;
  function MemMakerNotes:TExifMakerNote;
  property IsActive: boolean read GetisActive;
  property Thumbnail:TPicture read GetThumbnail;
end;

implementation

uses
  System.SysUtils;

{ TExifExtractor }

function TExifXtractor.AsString: string;
begin
  Result:=format('path:"%s",Disk Type:%s(%d),File system:%s,Vol Serial number:%s,Vol label:%s',
    [ FFileVolBinded.FFullPath,DriveTypeNames[FFileVolBinded.diskType],
      FFileVolBinded.diskType, FFileVolBinded.Filesystem,
      FFileVolBinded.VolSerialNum.ToHexString,FFileVolBinded.VolLabel ]);
  if isActive then Result:=Result+',Active' else  Result:=Result+',notActive';
end;

constructor TExifXtractor.Create;
begin
  inherited;
  //FFileVolBinded:=nil;
  FThumbnail:=TPicture.Create;
  FThumbnail.Assign(nil);
  FExifData:=nil;
  FExifData := TExifData.Create;
  FExifData.EnsureEnumsInRange := False; //as we use case statements rather than array constants, no need to keep this property set to True
end;

constructor TExifXtractor.Create(const fullFileName: string;
                                      volInfoRec: TFileVolBinded);
begin
  Create(fullFileName);
  FFileVolBinded:=volInfoRec;
end;

constructor TExifXtractor.Create(const fullFileName: string);
begin
  Create;
  ReadExtract(fullFileName);
end;

destructor TExifXtractor.Destroy;
begin
  FThumbnail.Free;
  FExifData.Free;
  inherited;
end;

function TExifXtractor.FileKeyinfo: TFileVolBinded;
begin
  Result:=FFileVolBinded;
end;

function TExifXtractor.GetisActive: boolean;
begin
  Result:=not FExifData.Empty;
end;

function TExifXtractor.GetThumbnail: TPicture;
begin
  FThumbnail.Assign(nil);
  Result := FThumbnail;
  if not FExifData.Thumbnail.Empty then FThumbnail.Assign(FExifData.Thumbnail);
end;

function TExifXtractor.MemExifData: TExifData;
begin
  Result:= FExifData;
end;

function TExifXtractor.MemMakerNotes: TExifMakerNote;
begin
  Result:=nil;
  if FExifData.HasMakerNote then
    Result:=FExifData.MakerNote
//  else
//    raise Exception.Create('No MakerNote')
  ;
end;

procedure TExifXtractor.ReadExtract(const fullFileName: string);
var
  VolumeInfo : TFileVolBinded;
begin
  VolumeInfo:=TFileVolBinded.Create(fullFileName);
  FFileVolBinded:=VolumeInfo;
  FExifData.EnsureEnumsInRange := False; //as we use case statements rather than array constants, no need to keep this property set to True
  FExifData.LoadFromGraphic(fullFileName); //get ExifData from FullFileName;
end;

end.

