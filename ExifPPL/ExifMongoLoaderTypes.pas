unit ExifMongoLoaderTypes;

interface

uses
  System.Classes, System.SysUtils, System.IniFiles,
  Vcl.Graphics, Jpeg,
 {$IFDEF VCL}{$ENDIF}{$IFDEF FMX}FMX.Types,{$ENDIF}
  CCR.Exif, CCR.Exif.BaseUtils, CCR.Exif.TiffUtils,
  Firedac.Comp.Client, FireDAC.Phys.MongoDBWrapper,

  System.JSON,
  System.JSON.Types,
  System.JSON.Writers,
  myUtils;

const
  DefColNm = 0;
  ScolNm = 0;
  McolNm = 1;
  DefaultDBName = 'Grafics';
  DefaultCollection = 'tst_meta';
  DefaultMkNotesCollection = 'mknotes';
  DefaultMainCollection = 'standard_e';
type
  TPartOpt = (poStd, poThumb, poMkNotes, poBatch);
  TPartOptSet = set of TPartOpt;

  { Process Loader }
  // опции: { части: [std, Thumb, MkNotes,poBatch], insert:false }
  // доп.опции: Log_in_memo
  // Параметры
  // single : keyinfo, db, [collection]
  // coupled: keyinfo, db, [collection1, collection2]

{ // For Far Future 2 : Разработка добавления гибкого сценария и работы по нему
  constructor Create(StdScript, MakerNoteValueMap: TCustomIniFile); overload;
  procedure SetScripts(StdScript, MakerNoteValueMap: TCustomIniFile); }

  IMyExifLoader = interface
      ['{80302C8B-0AF4-44C9-B11C-341866AF7EB0}']
      procedure Clear;
      procedure LoadKey(FileKeyinfo: TFileVolBinded);
      procedure LoadMakerNoteValues(MakerNote: TExifMakerNote; ValueMap: TCustomIniFile);
      procedure LoadStandardValues(iExifData: TExifData);
      procedure LoadGraphics(img: TPicture);
  end;

  TExifCustomLoader = class(TInterfacedObject)
    // FPartOptions: TPartOptSet;  constructor Create(PartOptions: TPartOptSet);
    // property PartOptions: TPartOptSet;
  end;

  TExifMongoLoader = class(TExifCustomLoader, IMyExifLoader)
  private
    LConn: TFDConnection;
    FPartOptions: TPartOptSet;
    FInsertMode, FBatchMode: boolean;
    // specific to MongoDB
    FEnv: TMongoEnv;
    FCon: TMongoConnection;
    FDBName: string;
    FCollections: array of string;
    FBCol: TMongoCollection;
    oDoc, iDoc, sDoc, mkDoc: TMongoDocument;
    function isSectionHere(Kind: TExifSectionKind; const Name: string;
      ExifData: TExifData): boolean;
    procedure SetPartOptions(const Value: TPartOptSet);
  public
    constructor Create; overload;
    constructor Create(Connect: TFDConnection; const PartOptions: TPartOptSet); overload;
    constructor Create(ConnectDefName: string; const PartOptions: TPartOptSet); overload;
    destructor Destroy; override;
    property PartOptions: TPartOptSet read FPartOptions write SetPartOptions;
    // интерфейс
    procedure Clear;
    procedure LoadKey(FileKeyinfo: TFileVolBinded);
    procedure LoadMakerNoteValues(MakerNote: TExifMakerNote;
      ValueMap: TCustomIniFile);
    procedure LoadStandardValues(iExifData: TExifData);
    procedure LoadGraphics(img: TPicture);
    // specific to MongoDB
    procedure SetConnectionParams(Connect: TFDConnection; const dbname: string;
      collections: array of string; const insert, batch: boolean);
    function StoreDefaultDB(const keynfo: TFileVolBinded;
      const insert: boolean): string;
  end;
  // вариант 1 : добавить в Loader методы, чтобы делать так:
    // LdrResult:=Loader.ToMongoAsSingle(it {keyinfo},FDConnection1,DBname, colName,
    //                                   cbInsert.Checked,cbBatch.Checked)
    // LdrResult:=Loader.ToMongoAsCoupled(it {keyinfo},FDConnection1,DBname, colName1,
    //                                    colName2, cbInsert.Checked,cbBatch.Checked)
    // вместо потомков внизу
  // Как вариант один из
  //   TExifMongoSinleLdr.Create(FDConnection1,inimap);
  // и TExifMongoCoupledLdr.Create(FDConnection1,inimap);

    TExifCoupledLoader = class(TExifMongoLoader)
      function StoreToDB(const keynfo: TFileVolBinded; Connect: TFDConnection;
        const db: string; colnames: array of string;
        const insert: boolean): string;
    end;

    TExifSingleLoader = class(TExifMongoLoader)
      function StoreToDB(const keynfo: TFileVolBinded; Connect: TFDConnection;
        const db: string; colnames: array of string; const insert: boolean)
        : string; overload;
    end;

    implementation

uses
  // ClipBrd,
  DateUtils, StrUtils, System.Types,
  ExifMongoHelper,
  ConvertersUtils;

constructor TExifMongoLoader.Create;
begin
  inherited;
  FEnv:=nil;
  FCon:=nil;
  FBCol:=nil;
  iDoc:=nil;
  oDoc:=nil;
  sDoc:=nil;
  mkDoc:=nil;
  FPartOptions:=[];
  FInsertMode:=False;
  FBatchMode:=False;
  FDBName:= DefaultDBName;          //'Grafics';
  FCollections := [DefaultCollection,'--'];  //'tst_meta';
  LConn:=TFDConnection.Create(nil);
end;

procedure TExifMongoLoader.Clear;
begin
  oDoc.Clear;
  iDoc.Clear;
  sDoc.Clear;
  mkDoc.Clear;
end;

constructor TExifMongoLoader.Create(Connect: TFDConnection; const PartOptions: TPartOptSet);
begin
  Create;
  SetConnectionParams(Connect,DefaultDBName,[DefaultCollection],false,(poBatch in PartOptions));
  FPartOptions:=PartOptions;
  if FBatchMode and (FBCol <> nil) then
    FBCol.BeginBulk(False);
end;

constructor TExifMongoLoader.Create(ConnectDefName: string; const PartOptions: TPartOptSet);
begin
  Create;
  FPartOptions:=PartOptions;
  LConn.Connected:=False;
  LConn.ConnectionDefName:=ConnectDefName;
  LConn.Connected:=True;
  SetConnectionParams(LConn,DefaultDBName,[DefaultCollection],false,(poBatch in PartOptions));
  if FBatchMode and (FBCol <> nil) then
    FBCol.BeginBulk(False);
end;

destructor TExifMongoLoader.Destroy;
begin
  if FBCol.IsBulk then
    FBCol.EndBulk;     //flushToDB;
  oDoc.Free;
  iDoc.Free;
  sDoc.Free;
  mkDoc.Free;
  LConn.Free;
  inherited;
end;

function TExifMongoLoader.isSectionHere(Kind: TExifSectionKind;
  const Name: string; ExifData: TExifData): boolean;
begin
  Result:=not(not(ExifData[Kind].Count > 0) or (ExifData[Kind].LoadErrors <> []));
end;

{procedure TExifMongoLoader.SetScripts(StdScript, MakerNoteValueMap: TCustomIniFile);
begin
  //todo 2 : Разработка добавления гибкого сценария
end;}

procedure TExifMongoLoader.LoadGraphics(img: TPicture);
begin
  // подготовка к загрузке миниатюры
  if img.Graphic = nil then
    exit;
  iDoc.Clear
    .Add('thumbnail',ImageToBytes(img.Graphic), TJsonBinaryType.UserDefined);
end;

procedure TExifMongoLoader.LoadKey(FileKeyinfo: TFileVolBinded);
begin
  oDoc.Clear
      // ключ документа
//      .Add('_id',objID)
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

procedure TExifMongoLoader.LoadMakerNoteValues(MakerNote: TExifMakerNote; ValueMap: TCustomIniFile);
var
  I: Integer;
  S, Section, TypeName, ValueStr: string;
  //_i,_df,
  _s,_de:string;
  //_v,
  _n: string;
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

procedure TExifMongoLoader.LoadStandardValues(iExifData: TExifData);
var
  s1,s2,s3,s4,s5: TMongoDocument;
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
          .AddValue('UserRating',Ord(iExifData.UserRating))
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

procedure TExifMongoLoader.SetConnectionParams(Connect: TFDConnection; const dbname: string;
                                               collections: array of string;
                                               const insert, batch: boolean);
var
  i: integer;
begin
  Connect.Connected := True;
  FCon := TMongoConnection(Connect.CliObj);
  FEnv := FCon.Env;
       { oDoc.Free; iDoc.Free; sDoc.Free; mkDoc.Free; }
  if oDoc = nil then oDoc:=FEnv.NewDoc;
  if iDoc = nil then iDoc:=FEnv.NewDoc;
  if sDoc = nil then sDoc:=FEnv.NewDoc;
  if mkDoc = nil then mkDoc:=FEnv.NewDoc;
  FInsertMode:= insert;
  FBatchMode:=batch;
  if dbname <> '' then FDBname:=dbname;
  if length(collections) > 0 then begin
    SetLength( FCollections,Length(collections) );
    for i := Low(collections) to High(collections) do
      FCollections[i] := collections[i];
  end;
  FBCol:=FCon[FDBname][FCollections[DefColNm]];
end;

procedure TExifMongoLoader.SetPartOptions(const Value: TPartOptSet);
begin
  FPartOptions := Value;
end;

function TExifMongoLoader.StoreDefaultDB(const keynfo: TFileVolBinded; const insert:boolean):string;
var
  outDoc: TMongoDocument;
begin
  FCon.Ping;                 //Проверка доступности сервера
  outDoc:= TMongoDocument.Create(FEnv);
  // вызов процедур заполнения документов-составных частей идет снаружи загрузчика
  try
    if keynfo.FFullPath <> '' then //Если oDoc уже был заполнен ключом, то указать keyinfo:=nil
      Loadkey(keynfo);             //иначе - заполнить oDoc
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
      FBCol.Insert(outDoc);//FCon[FDBname][FCollections[DefColNm]].Insert(outDoc);
    end;
  finally
    outDoc.Free;
  end;
end;

{ TExifSingleLoader }

function TExifCoupledLoader.StoreToDB
  (const keynfo: TFileVolBinded; Connect: TFDConnection; const db: string;
  colnames: array of string; const insert: boolean): string;
var
  // keyDoc,
  mainDoc, cplDoc: TMongoDocument;
  objID: TMongoOID;
  mknPresent: boolean;
  name1, name2: string;
begin
  mainDoc := FEnv.NewDoc;
  cplDoc := FEnv.NewDoc;
  objID := TMongoOID.Create(FEnv, nil);
  try
    objID.Init;
    LoadKey(keynfo);
    mainDoc.Clear
    // ключ документа
      .Add('_id', objID).Append(oDoc).beginObject('metadata')
    // стандартный EXIF
      .Append(sDoc)
    // миниатюра
      .Append(iDoc).EndObject;
    Result := mainDoc.AsJSON; // демонстрация резульата
    mknPresent := not(mkDoc.AsJSON = '{}');
    if mknPresent then
    begin
      cplDoc.Clear
      // ключ документа
        .Add('main_id', objID).Append(oDoc)
      // MakerNotes
        .Append(mkDoc);
      Result := Result + cplDoc.AsJSON; // демонстрация резульата
    end;
    if insert then
    begin
      if Assigned(Connect) then
        if not Connect.Connected then
          Connect.Connected := True;
      name1 := colnames[ScolNm];
      FCon[db][name1].insert(mainDoc);
      name2 := colnames[McolNm];
      if mknPresent then
        FCon[db][name2].insert(cplDoc);
    end;
  finally
    objID.Free;
    mainDoc.Free;
    cplDoc.Free;
  end;
end;

function TExifSingleLoader.StoreToDB
  (const keynfo: TFileVolBinded; Connect: TFDConnection; const db: string;
  colnames: array of string; const insert: boolean): string;
var
  outDoc: TMongoDocument;
  name_: string;
begin
  // вызов процедур заполнения документов-составных частей идет снаружи загрузчика
  outDoc := TMongoDocument.Create(FEnv);
  try
    LoadKey(keynfo);
    outDoc.Clear
    // ключ документа
      .Append(oDoc).beginObject('metadata')
    // стандартный EXIF
      .Append(sDoc)
    // миниатюра
      .Append(iDoc)
    // MakerNotes
      .Append(mkDoc).EndObject;
    Result := outDoc.AsJSON; // демонстрация результата
    if insert then
    begin
      if Assigned(Connect) then
        if not Connect.Connected then
          Connect.Connected := True;
      name_ := colnames[DefColNm];
      // FCon['Grafics']['tst_meta'].Insert(oDoc);
      FCon[db][name_].insert(outDoc);
    end;
  finally
    outDoc.Free;
  end;
end;
{ TExifCoupledLoader }
{$region 'templates'}
 (*
//batch snipet

   oCol := FCon['test']['testbulk'];
    oCol.RemoveAll;

    try
      oCol.BeginBulk(False);
      for i := 1 to 10 do begin
        oDoc
          .Clear
          .Add('_id', i div 2)
          .Add('name', 'rec' + IntToStr(i));
        oCol.Insert(oDoc);
      end;
      oCol.EndBulk;
    except
      ApplicationHandleException(nil);
    end;

// end batch

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
