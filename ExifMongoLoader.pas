unit ExifMongoLoader;

interface

uses
  System.Classes, System.SysUtils, System.IniFiles,
 {$IFDEF VCL} Vcl.Graphics, Jpeg,{$ENDIF}{$IFDEF FMX}FMX.Types,{$ENDIF}
  CCR.Exif, CCR.Exif.BaseUtils, CCR.Exif.TiffUtils,
  Firedac.Comp.Client, FireDAC.Phys.MongoDBWrapper,

  System.JSON,
  System.JSON.Types,
  System.JSON.Writers,
  myUtils;

const
  DefaultDBName = 'Grafics';
  DefaultCollection = 'tst_meta';

type
  { Process Loader}
  // опции: { части: [std, Thumb, MkNotes], insert:false, batch:false }
  // доп.опции: Log_in_memo
  //            single : db, collection
  //            coupled: db, collection1, collection2

  TExifMongoWriter = class
  private
    // specific to MongoDB
    FEnv: TMongoEnv;
    FCon: TMongoConnection;
    FwithThumbN,
    FInsertMode,
    FBatchMode: boolean;
    FDBName: string;
    FCollection: string;
    iDoc: TMongoDocument;
    oDoc,  sDoc, mkDoc: TMongoDocument;
  public
  // Как вариант, TExifMongoWriter.Create(FDConnection1,inimap);
  //  или один из TExifMongoSinleLdr.Create(FDConnection1,inimap);
  //  и TExifMongoCoupledLdr.Create(FDConnection1,inimap);
    constructor Create; overload;
    constructor Create(mongoConnect: TFDConnection); overload;
    constructor Create(StdScript,MakerNoteValueMap: TCustomIniFile); overload;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadKey(FileKeyinfo:TFileVolBinded);
    procedure LoadMakerNoteValues(MakerNote: TExifMakerNote; ValueMap: TCustomIniFile);
    procedure LoadStandardValues(iExifData: TExifData);
    procedure LoadGraphics(img: TPicture);
    procedure SetScripts(StdScript,MakerNoteValueMap: TCustomIniFile);
    function isSectionHere(Kind: TExifSectionKind; const Name: string; ExifData:TExifData): boolean;

    // specific to MongoDB
    procedure SetConnectionParams(mongoConnect: TFDConnection; const dbname: string; collection: string; const insert, batch: boolean);
//todo 1 : добавить в Loader методы, чтобы делать так:
//LdrResult:=Loader.ToMongoAsSingle(it {keyinfo},FDConnection1,DBname, colName,
//                                 cbInsert.Checked,cbBatch.Checked)
//LdrResult:=Loader.ToMongoAsCoupled(it {keyinfo},FDConnection1,DBname, colName1,
//                                 colName2, cbInsert.Checked,cbBatch.Checked)
// вместо строк внизу
    function ToMongoDB(mongoConnect: TFDConnection; const insert, batch:boolean): string;
  end;

implementation

uses
  //ClipBrd,
  DateUtils, StrUtils, System.Types,
  ExifMongoHelper,
  ConvertersUtils;

constructor TExifMongoWriter.Create;
begin
  inherited;
  FEnv:=nil;
  FCon:=nil;
  iDoc:=nil;
  oDoc:=nil;
  sDoc:=nil;
  mkDoc:=nil;
  FwithThumbN:=False;
  FInsertMode:=False;
  FBatchMode:=False;
  FDBName:= DefaultDBName;          //'Grafics';
  FCollection:= DefaultCollection;  //'tst_meta';
end;

procedure TExifMongoWriter.Clear;
begin
  oDoc.Clear;
  iDoc.Clear;
  sDoc.Clear;
  mkDoc.Clear;
end;

constructor TExifMongoWriter.Create(StdScript,MakerNoteValueMap: TCustomIniFile);
begin
  Create;
  SetScripts(StdScript,MakerNoteValueMap);
end;

constructor TExifMongoWriter.Create(mongoConnect: TFDConnection);
begin
  Create;
  SetConnectionParams(mongoConnect, 'Grafics', 'tst_meta',false,false);
end;

destructor TExifMongoWriter.Destroy;
begin
  oDoc.Free;
  iDoc.Free;
  sDoc.Free;
  mkDoc.Free;
  inherited;
end;

function TExifMongoWriter.isSectionHere(Kind: TExifSectionKind;
  const Name: string; ExifData: TExifData): boolean;
begin
  Result := not ( not (ExifData[Kind].Count > 0) or (ExifData[Kind].LoadErrors <> []));
end;

procedure TExifMongoWriter.SetScripts(StdScript,MakerNoteValueMap: TCustomIniFile);
begin
  //todo 2 : Разработка добавления гибкого сценария
end;

procedure TExifMongoWriter.LoadGraphics(img: TPicture);
begin
  // выдача миниатюры
  if img.Graphic = nil then
    exit;
  iDoc.Clear.Add('thumbnail',ImageToBytes(img.Graphic), TJsonBinaryType.UserDefined);
end;

procedure TExifMongoWriter.LoadKey(FileKeyinfo: TFileVolBinded);
begin
    oDoc.Clear
      // ключ документа
      .addValue('upath', FileKeyinfo.UNCPath)
      .beginObject('file')
        .addValue('filedate',FileKeyinfo.Filedate)
        .addValue('filename',FileKeyinfo.Filename)
        .addValue('ext', FileKeyinfo.Ext)
        .addValue('path', FileKeyinfo.Path)
        .addValue('drive', FileKeyinfo.Drive)
        .addValue('driveTypeName',FileKeyinfo.DriveTypeName)
        .addValue('diskType',FileKeyinfo.DiskType)
        .addValue('filesystem',FileKeyinfo.Filesystem)
        .addValue('volSerialNum',FileKeyinfo.VolSerialNum.ToHexString)
        .addValue('volLable',FileKeyinfo.VolLabel)
      .EndObject
end;

procedure TExifMongoWriter.LoadMakerNoteValues(MakerNote: TExifMakerNote; ValueMap: TCustomIniFile);
var
  I: Integer;
  S, Section, TypeName, ValueStr: string;
  _s,_i,_de,_df:string;
  _n, _v: string;
  t, tagDoc: TMongoDocument;
  Tag: TExifTag;
begin
  if MakerNote = nil then
      exit;

  t := FEnv.NewDoc;
  tagDoc := FEnv.NewDoc;
  try
    if MakerNote is TUnrecognizedMakerNote then
    begin
      mkDoc.Clear
        .beginObject('MakerNotes')
          .addValue('Error','Unrecognised format')
        .EndObject;
      // exit;
    end
    else begin
      TypeName := ValueMap.ReadString(MakerNote.ClassName, 'UseTagsFrom', '');
      if TypeName = '' then
        TypeName := MakerNote.ClassName;

      for Tag in MakerNote.Tags do
      begin
        t.Clear;
        FmtStr(Section, '%s.$%.4x', [TypeName, Tag.ID]);
        if Tag.WellFormed and ValueMap.ReadBool(Section, 'TreatAsTagGroup', False) then
          for I := 0 to Tag.ElementCount - 1 do
          begin
            S := ValueMap.ReadString(Section, 'TagDescription', '');
            if S <> '' then
              S := Format('%s (%d)', [S, I])
            else
              S := Format('Unknown (%.4x, %d)', [Tag.ID, I]);
            ValueStr := Trim(Tag.ElementAsString[I]);
//            // procedure LoadValue(const Section, Ident, DefDescription, DefValue: string);
//            _s:=Format('%s(%d)', [Section, I]);
//            _i:=ValueStr;
//            _de:=S;
//            _df:=ValueStr;
            _n:=ValueMap.ReadString(_s,'TagDescription',_de);  //todo 1 : remove $ and .
//            _v:=ValueMap.ReadString(_s,_i, _df);
            t.addValue(ValueMap.ReadString(Format('%s(%d)',[Section, I]),'TagDescription', S),
                       ValueMap.ReadString(Format('%s(%d)',[Section, I]), ValueStr, ValueStr));
          end
        else begin
          if not Tag.WellFormed then
            ValueStr := '[Badly formed tag header]'
          else if Tag.DataType = tdUndefined then
            if Tag.ElementCount > 50 then
              ValueStr := Format('{%s...}', [Copy(Trim(Tag.AsString), 1, 100)])
            else
              ValueStr := Format('{%s}', [Trim(Tag.AsString)])
              // else if (Tag.ID = ttPanasonicTimeSincePowerOn) and (ExifData.MakerNoteType = TPanasonicMakerNote) then
              // ValueStr := SecsToStr(Tag.ReadLongWord(0, 0) div 100)
          else
            ValueStr := Trim(Tag.AsString);
//            _s:=section;
//            _i:=Trim(Tag.AsString);
//            _de:=Format('Unknown ($%.4x)', [Tag.ID]);
//            _df:=ValueStr;
            _n:=ValueMap.ReadString(_s,'TagDescription',Format('Unknown (%.4x)', [Tag.ID]));   //todo 1 : remove $ and .
//            _v:=ValueMap.ReadString(_s,_i, _df);
            t.addValue(ValueMap.ReadString(Section,'TagDescription',Format('Unknown (%.4x)', [Tag.ID])), ValueMap.ReadString(Section,
            Trim(Tag.AsString), ValueStr));
        end;
        tagDoc.Append(t);
      end;
      TypeName := MakerNote.ClassName;
      // загрузка MakerNotes
      mkDoc.Clear
        .beginObject('MakerNotes')
        //----------------------------------------- .add('available','Not in demo version')
          .beginObject('General')
            .addValue('Type',Copy(TypeName, 2, Length(TypeName) - 10))
            .addValue(SEndiannessCaption,SEndianness[MakerNote.Endianness])
            .AddLoadErrorsValue(MakerNote.Tags)
        .EndObject
        .beginObject('Tags')
          .Append(tagDoc)
        .EndObject;
    end;
  finally
    tagDoc.Free;
    t.Free;
  end;
end;

procedure TExifMongoWriter.LoadStandardValues(iExifData: TExifData);
var
  s1,s2,s3,s4,s5,s6,s7,s8: TMongoDocument;
begin
  s1 := FEnv.NewDoc;
  s2 := FEnv.NewDoc;
  s3 := FEnv.NewDoc;
  s4 := FEnv.NewDoc;
  s5 := FEnv.NewDoc;

  try
   if iExifData.Empty then
     exit;
//-------------------------------
      // Стандартные параметры EXIF
    if isSectionHere(esGeneral, 'Main IFD',iExifData) then
      s1.Clear
        .DoSection(esGeneral, 'Main IFD',iExifData)
          .AddValue('Camera make', iExifData.CameraMake)
          .AddValue('Camera model', iExifData.CameraModel)
          .AddValue('Software', iExifData.Software)
          .AddValue('Date/time', iExifData.DateTime)
          .AddValue('Image description', iExifData.ImageDescription)
          .AddValue('Copyright', iExifData.Copyright)
          .AddValue('Orientation', OrientationToStr(iExifData.Orientation))
          .AddValue('Resolution', iExifData.Resolution)
          .AddValue('Author', iExifData.Author)
          .AddValue('Comments', iExifData.Comments)
          .AddValue('Keywords', iExifData.Keywords)
          .AddValue('Subject', iExifData.Subject)
          .AddValue('Title', iExifData.Title)
        .EndSection;
    if isSectionHere(esDetails, 'Exif sub-IFD',iExifData) then
      s2.Clear
        .DoSection(esDetails, 'Exif sub-IFD',iExifData)
          .AddValue('Exif version', iExifData.ExifVersion.AsString)
          .AddValue('Aperture value', iExifData.ApertureValue)
          .AddValue('Body serial number', iExifData.BodySerialNumber)
          .AddValue('Brightness value', iExifData.BrightnessValue)
          .AddValue('Camera owner', iExifData.CameraOwnerName)
          .AddValue('Colour space', ColorSpaceToStr(iExifData.ColorSpace))
          .AddValue('Compressed bits per pixel', iExifData.CompressedBitsPerPixel)
          .AddValue('Date/time original', iExifData.DateTimeOriginal)
          .AddValue('Date/time digitised', iExifData.DateTimeDigitized)
          .AddValue('Digital zoom ratio', iExifData.DigitalZoomRatio)
          .AddValue('Exif image width', iExifData.ExifImageWidth)
          .AddValue('Exif image height', iExifData.ExifImageHeight)
          .AddValue('Exposure programme', ExposureProgramToStr(iExifData.ExposureProgram))
          .AddValue('Exposure time', iExifData.ExposureTime, 'seconds')
          .AddValue('Exposure index', iExifData.ExposureIndex)
          .AddValue('Exposure bias value', iExifData.ExposureBiasValue)
          .AddValue('File source', FileSourceToStr(iExifData.FileSource))
//          if not iExifData.Flash.MissingOrInvalid then
//          begin
            .AddValue('Flash present', iExifData.Flash.Present)
            .AddValue('Flash mode', FlashModeToStr(iExifData.Flash.Mode))
            .AddValue('Flash fired', iExifData.Flash.Fired)
            .AddValue('Flash red eye reduction', iExifData.Flash.RedEyeReduction)
            .AddValue('Flash strobe energy', iExifData.Flash.StrobeEnergy)
            .AddValue('Flash strobe light', StrobeLightToStr(iExifData.Flash.StrobeLight))
      //    end
          .AddValue('F number', iExifData.FNumber)
          .AddValue('Focal length', iExifData.FocalLength)
          .AddValue('Focal length in 35mm film', iExifData.FocalLengthIn35mmFilm)
          .AddValue('Focal plane resolution', iExifData.FocalPlaneResolution)
          .AddValue('Gain control', GainControlToStr(iExifData.GainControl))
          .AddValue('Image unique ID', iExifData.ImageUniqueID)
      //    if not iExifData.ISOSpeedRatings.MissingOrInvalid then
            .AddValue('ISO speed rating(s)', iExifData.ISOSpeedRatings.AsString)
          .AddValue('Lens make', iExifData.LensMake)
          .AddValue('Lens model', iExifData.LensModel)
          .AddValue('Lens serial number', iExifData.LensSerialNumber)
          .AddValue('Light source', LightSourceToStr(iExifData.LightSource))
          .AddValue('MakerNote data offset', iExifData.OffsetSchema)
          .AddValue('Max aperture value', iExifData.MaxApertureValue)
          .AddValue('Metering mode', MeteringModeToStr(iExifData.MeteringMode))
          .AddValue('Related sound file', iExifData.RelatedSoundFile)
          .AddValue('Rendering', RenderingToStr(iExifData.Rendering))
          .AddValue('Scene capture type', SceneCaptureTypeToStr(iExifData.SceneCaptureType))
          .AddValue('Scene type', SceneTypeToStr(iExifData.SceneType))
          .AddValue('Sensing method', SensingMethodToStr(iExifData.SensingMethod))
      //    if iExifData.ShutterSpeedInMSecs <> 0 then
            .AddValue('Shutter speed', '%.4g milliseconds', [iExifData.ShutterSpeedInMSecs])
          .AddValue('Subject distance', iExifData.SubjectDistance)
          .AddValue('Spectral sensitivity', iExifData.SpectralSensitivity)
          .AddValue('Subject distance', iExifData.SubjectDistance)
          .AddValue('Subject distance range', SubjectDistanceRangeToStr(iExifData.SubjectDistanceRange))
          .AddValue('Subject location', iExifData.SubjectLocation)
          .AddValue('White balance mode', WhiteBalanceModeToStr(iExifData.WhiteBalanceMode))
          { don't do sub sec tags as their values are rolled into the date/times by the
            latters' property getters }
        .EndSection;
    if isSectionHere(esInterop, 'Interoperability sub-IFD',iExifData) then
      s3.Clear
        .DoSection(esInterop, 'Interoperability sub-IFD',iExifData)
          .AddValue('Interoperability type', iExifData.InteropTypeName)
          .AddValue('Interoperability version', iExifData.InteropVersion.AsString)
        .EndSection
        ;
    if isSectionHere(esGPS, 'GPS sub-IFD',iExifData) then
      s4.Clear
        .DoSection(esGPS, 'GPS sub-IFD',iExifData)
          .AddValue('GPS version', iExifData.GPSVersion.AsString)
          .AddValue('GPS date/time (UTC)', iExifData.GPSDateTimeUTC)
          .AddValue('GPS latitude', iExifData.GPSLatitude)
          .AddValue('GPS longitude', iExifData.GPSLongitude)
          .AddValue('GPS altitude', iExifData.GPSAltitude, 'metres ' +
            GPSAltitudeRefToStr(iExifData.GPSAltitudeRef))
          .AddValue('GPS satellites', iExifData.GPSSatellites)
          .AddValue('GPS status', GPSStatusToStr(iExifData.GPSStatus))
          .AddValue('GPS measure mode', GPSMeasureModeToStr(iExifData.GPSMeasureMode))
          .AddValue('GPS DOP', iExifData.GPSDOP)
          .AddValue('GPS speed', iExifData.GPSSpeed, GPSSpeedRefToStr(iExifData.GPSSpeedRef))
          .AddValue('GPS track', iExifData.GPSTrack, iExifData.GPSTrackRef)
          .AddValue('GPS image direction', iExifData.GPSImgDirection,
            iExifData.GPSImgDirectionRef)
          .AddValue('GPS map datum', iExifData.GPSMapDatum)
          .AddValue('GPS destination latitude', iExifData.GPSDestLatitude)
          .AddValue('GPS destination longitude', iExifData.GPSDestLongitude)
          .AddValue('GPS destination bearing', iExifData.GPSDestBearing,
            iExifData.GPSDestBearingRef)
          .AddValue('GPS destination distance', iExifData.GPSDestDistance,
            iExifData.GPSDestDistanceRef)
          .AddValue('GPS differential', GPSDifferentialToStr(iExifData.GPSDifferential))
        .EndSection
        ;
    if isSectionHere(esThumbnail, 'Thumbnail IFD',iExifData) then
      s5.Clear
        .DoSection(esThumbnail, 'Thumbnail IFD',iExifData)
          .AddValue('Thumbnail orientation', OrientationToStr(iExifData.ThumbnailOrientation))
          .AddValue('Thumbnail resolution', iExifData.ThumbnailResolution)
        .EndSection
        ;

     sDoc.Clear
      .BeginObject('standard')
        .Append(s1)
        .Append(s2)
        .Append(s3)
        .Append(s4)
        .Append(s5)
      .EndObject;
  finally
    s1.Free;
    s2.Free;
    s3.Free;
    s4.Free;
    s5.Free;
  end;
    // Создание полного документа из составных частей
end;

// Specific to MongoDB

procedure TExifMongoWriter.SetConnectionParams(mongoConnect: TFDConnection; const dbname: string; collection: string; const insert, batch: boolean);
begin
  mongoConnect.Connected := True;
  FCon := TMongoConnection(mongoConnect.CliObj);
  FEnv := FCon.Env;
{ oDoc.Free;
  iDoc.Free;
  sDoc.Free;
  mkDoc.Free; }
  if oDoc = nil then oDoc:=FEnv.NewDoc;
  if iDoc = nil then iDoc:=FEnv.NewDoc;
  if sDoc = nil then sDoc:=FEnv.NewDoc;
  if mkDoc = nil then mkDoc:=FEnv.NewDoc;
  FInsertMode:= insert;
  FBatchMode:=batch;
  if dbname <> '' then FDBname:=dbname;
  if collection <> '' then FCollection:=collection;
end;

function TExifMongoWriter.toMongoDB(mongoConnect: TFDConnection; const insert,batch:boolean):string;
var
  outDoc: TMongoDocument;
begin
  if not mongoConnect.Connected then
    mongoConnect.Connected := True;
  // вызов процедур заполнения документов-составных частей идет снаружи загрузчика
  outDoc:= TMongoDocument.Create(FEnv);
  try
    outDoc.Clear
      // ключ документа
      .Append(oDoc)
      .BeginObject('metadata')
        // стандартный EXIF
        .Append(sDoc)
        // миниатюра
        .Append(iDoc)
        // MakerNotes
        .Append(mkDoc)
      .endObject;

    Result:=outDoc.AsJSON;  // демонстрация резульата
    if insert then begin
      //FCon['Grafics']['tst_meta'].Insert(oDoc);
      FCon[FDBname][FCollection].Insert(outDoc);
    end;
  finally
    outDoc.Free;
  end;
end;


{$region 'templates'}
 (*

 procedure TForm2.Button1Click(Sender: TObject);
var
  objID: TMongoOID;
begin
  objID:=TMongoOID.Create(FEnv, nil);
  objID.Init;
  memo1.Lines.Add(format('DT: %s',[DatetimetoStr(objID.AsDateTime)]));
  memo1.Lines.Add(format('str: %s',[objID.AsString]));
  memo1.Lines.Add(format('Xstr: %s',[objID.AsOid.AsString]));
end;


 var
  oDoc: TMongoDocument;
  oCrs: IMongoCursor;
  imgbytes: TBytes;
begin
  // For details see:
  // http://docs.mongodb.org/manual/reference/operator/query/
  // http://docs.mongodb.org/manual/reference/operator/query-modifier/
  oDoc := FEnv.NewDoc;
  try
    //FCon['test']['perf_test'].RemoveAll;
//    imgbytes:= _ImageToBytes(Image1.Picture.Graphic);
//    oDoc.Clear
//      .Add('upath','C:\Users\asovtsov\Downloads\1\0908d400-0422-75-76.jpg')
//      .BeginObject('file')
//      .Add('filedate', StrToDatetime('14.08.2010 18:12:12'))
//      .Add('filename', '0908d400-0422-75-76')
//      .Add('ext', '.jpg')
//      .Add('path', 'C:\Users\asovtsov\Downloads\1\')
//      .Add('drive', 'C:')
//      .Add('driveTypeName', 'DRIVE_FIXED')
//      .Add('diskType', 3)
//      .Add('filesystem', 'NTFS').Add('volSerialNum', '940B7FD7')
//      .Add('volLable', 'OS')
//      .Add('thumbnail',_ImageToBytes(Image1.Picture.Graphic), TJsonBinaryType.Generic)
//    .EndObject;
//
//    FCon['Grafics']['tst_meta'].Insert(oDoc);

    oCrs := FCon['Grafics']['tst_meta']
      .Find()
{      .Match
        .BeginObject('f1')
          .Add('$gt', 5)
        .EndObject
      .&End

      .Sort
        .Field('f1', False)
        .Field('f2', True)
      .&End }
      .Limit(5);

    while oCrs.Next do
      Memo1.Text := Memo1.Text + #13#10 + #13#10 + oCrs.Doc.AsJSON;
//
  finally
    oDoc.Free;
  end;
end;
*)
{$endregion}

end.
