unit ExifWRTLoader;
{
Ответственность
    при создании получить "сценарий" загрузки и "схему" данных (из файлов конфигурации ??)
    сформировать запись на основе ключа для загрузки  ("знает" откуда и в каком порядке брать данные)
    Если пакетный режим - заполнить буфер до заданного размера
    записать буфер в вых поток / БД
}

interface

uses
  System.Classes, System.SysUtils, System.IniFiles,
  CCR.Exif, CCR.Exif.BaseUtils, CCR.Exif.TiffUtils, //CCR.Exif.Demos,
  System.JSON,
  System.JSON.Types,
  System.JSON.Writers,
  myUtils,
  //ExifExtractor,
  VCL.ComCtrls;

type
  TExifWriter = class
  private
    FInnerWriter: TJsonWriter;
    FMakerNoteValueMap: TCustomIniFile;
    FTmpExifData: TExifData;
    FTmpMakerNote: TExifMakerNote;
    procedure AddLoadErrorsValue(Wrt: TJsonWriter; Section: TExifSection);
    procedure AddValue(Wrt: TJsonWriter; const Name, Value: string);
    procedure SetMakerNoteValueMap(const Value: TCustomIniFile);
  public
//todo 2 : Добавить сценарии - ValueMap: TCustomIniFile, StandardMap: TCustomIniFile
    constructor Create(pWrt: TJsonWriter);
    procedure LoadKeyValues(keyInfo: TFileVolBinded);
    procedure LoadMakerNoteValues(MakerNote: TExifMakerNote; ValueMap: TCustomIniFile);
    procedure LoadStandardValues(ExifData: TExifData);
    function isSectionHere(Kind: TExifSectionKind; const Name: string): Boolean;
    function ToJSON: TJSONObject;
    //procedure LoadFromFile(const FileName: string; MakerNoteValueMap: TCustomIniFile);
    property MakerNoteValueMap: TCustomIniFile read FMakerNoteValueMap write SetMakerNoteValueMap;
  end;

implementation

uses
  //ClipBrd,
  DateUtils, StrUtils, System.Types,
  ConvertersUtils;

constructor TExifWriter.Create(pWrt: TJsonWriter);
begin
  FInnerWriter:=pWrt;
end;

function TExifWriter.isSectionHere(Kind: TExifSectionKind;  const Name: string): Boolean;
begin
  Result := (FTmpExifData[Kind].Count > 0) or (FTmpExifData[Kind].LoadErrors <> []);
end;

procedure TExifWriter.AddValue(Wrt: TJsonWriter; const Name, Value: string);
begin
  Wrt.WritePropertyName(name);
  Wrt.WriteValue(Value);
end;

procedure TExifWriter.AddLoadErrorsValue(Wrt: TJsonWriter; Section: TExifSection);
var
  Error: TExifSectionLoadError;
  S: string;
begin
  S := '';
  for Error in Section.LoadErrors do
    case Error of
      leBadOffset: S := S + ', bad IFD offset';
      leBadTagCount: S := S + ', bad tag count';
      leBadTagHeader: S := S + ', one or more bad tag headers';
    end;
  if (Section.Kind = esThumbnail) and (Section.Owner as TExifData).Thumbnail.Empty then
    S := S + ', bad image offset';
  if S = '' then
    S := 'Yes'
  else
    S := 'No:' + Copy(S, 2, MaxInt);

  //wrt.WriteComment('Loaded: '+S);
  AddValue(wrt, 'Loaded cleanly', S);
end;

procedure TExifWriter.LoadStandardValues(ExifData: TExifData);

  procedure AddValue(const Name, Value: string); overload;
  begin
    if Value <> '' then Self.AddValue(FInnerWriter, Name, Value);
  end;

  procedure AddValue(const Name, Value: string; const Args: array of const); overload;
  begin
    AddValue(Name, Format(Value, Args));
  end;

  procedure AddValue(const Name: string; const Value: Int64); overload;
  begin
    if Value <> 0 then
      AddValue(Name, IntToStr(Value));
  end;

  procedure AddValue(const Name: string; YesNoValue: Boolean); overload;
  begin
    AddValue(Name, SNoYes[YesNoValue])
  end;

  procedure AddValue(const Name: string; const DateTime: TDateTimeTagValue); overload;
  begin
    if not DateTime.MissingOrInvalid then
      AddValue(Name, DateTimeToStr(DateTime));
  end;

  procedure AddValue(const Name: string; const Fraction: TExifFraction;
    const Units: string = ''); overload;
  begin
    if not Fraction.MissingOrInvalid then
      AddValue(Name, '%g %s', [Fraction.Quotient, Units]);
  end;

  procedure AddValue(const Name: string; const Fraction: TExifSignedFraction); overload;
  begin
    if not Fraction.MissingOrInvalid then
      AddValue(Name, '%g', [Fraction.Quotient]);
  end;

  procedure AddValue(const Name: string; const Value: TSmallPoint); overload;
  begin
    if not InvalidPoint(Value) then
      AddValue(Name, '(%d, %d)', [Value.x, Value.y]);
  end;

  procedure AddValue(const Name: string; Coord: TGPSCoordinate); overload;
  var
    DirectionStr: string;
  {$IFDEF BUGGYCOMPILER}
    Degrees, Minutes, Seconds: TExifFraction; //work around D2006 compiler bug with intermediate vars
  {$ENDIF}
  begin
    if Coord.MissingOrInvalid then Exit;
    case Coord.Direction of
      'N': DirectionStr := 'north';
      'S': DirectionStr := 'south';
      'W': DirectionStr := 'west';
      'E': DirectionStr := 'east';
    else DirectionStr := '';
    end;
  {$IFDEF BUGGYCOMPILER}
    Degrees := Coord.Degrees;
    Minutes := Coord.Minutes;
    Seconds := Coord.Seconds;
    AddValue(Name, '%g°, %g minutes and %g seconds %s', [Degrees.Quotient,
      Minutes.Quotient, Seconds.Quotient, DirectionStr]);
  {$ELSE}
    AddValue(Name, '%g°, %g minutes and %g seconds %s', [Coord.Degrees.Quotient,
      Coord.Minutes.Quotient, Coord.Seconds.Quotient, DirectionStr]);
  {$ENDIF}
  end;

  procedure AddValue(const Name: string; const Direction: TExifFraction;
    Ref: TGPSDirectionRef); overload;
  begin
    if not Direction.MissingOrInvalid then
      AddValue(Name, '%g %s', [Direction.Quotient, DirectionRefToStr(Ref)]);
  end;

  procedure AddValue(const Name: string; const Distance: TExifFraction;
    Ref: TGPSDistanceRef); overload;
  begin
    if not Distance.MissingOrInvalid then
      AddValue(Name, '%g %s', [Distance.Quotient, DistanceRefToStr(Ref)]);
  end;

  procedure AddValue(const Name: string; Resolution: TCustomExifResolution); overload;
  {$IFDEF BUGGYCOMPILER}
  var
    X, Y: TExifFraction; //work around D2006 compiler bug with intermediate vars
  begin
    if Resolution.MissingOrInvalid then Exit;
    X := Resolution.X;
    Y := Resolution.Y;
    AddValue(Name, '%g x %g %s', [X.Quotient, Y.Quotient, ResolutionUnitsToStr(Resolution.Units)]);
  end;
  {$ELSE}
  begin
    if not Resolution.MissingOrInvalid then
      AddValue(Name, '%g x %g %s', [Resolution.X.Quotient, Resolution.Y.Quotient,
        ResolutionUnitsToStr(Resolution.Units)]);
  end;
  {$ENDIF}

  function DoSection(Kind: TExifSectionKind; const Name: string): Boolean;
  begin
    Result := (ExifData[Kind].Count > 0) or (ExifData[Kind].LoadErrors <> []);
    if not Result then Exit;
    FInnerWriter.WritePropertyName(Name);
    FInnerWriter.WriteStartObject;
    AddLoadErrorsValue(FInnerWriter, ExifData[Kind]);
  end;

//  function DoSectionProc(Kind: TExifSectionKind; const Name: string; scbody:TProc): Boolean;
//  begin
//    Result := (ExifData[Kind].Count > 0) or (ExifData[Kind].LoadErrors <> []);
//    if not Result then Exit;
//    FInnerWriter.WritePropertyName(Name);
//    FInnerWriter.WriteStartObject;
//    AddLoadErrorsValue(FInnerWriter, ExifData[Kind]);
//    scbody;
//  end;
//
  function EndSection: Boolean;
  begin
    Result:=True;
    FInnerWriter.WriteEndObject;
    //AddLoadErrorsValue(FInnerWriter, ExifData[Kind]);
  end;

begin
  FInnerWriter.WriteStartObject;
  FInnerWriter.WritePropertyName('Standard');
  FInnerWriter.WriteStartObject;
try
  //lsvStandard.Items.Add.Caption := SGeneral;
  AddValue(SEndiannessCaption, SEndianness[ExifData.Endianness]);
  if DoSection(esGeneral, 'Main IFD') then
  begin
    AddValue('Camera make', ExifData.CameraMake);
    AddValue('Camera model', ExifData.CameraModel);
    AddValue('Software', ExifData.Software);
    AddValue('Date/time', ExifData.DateTime);
    AddValue('Image description', ExifData.ImageDescription);
    AddValue('Copyright', ExifData.Copyright);
    AddValue('Orientation', OrientationToStr(ExifData.Orientation));
    AddValue('Resolution', ExifData.Resolution);
    AddValue('Author', ExifData.Author);
    AddValue('Comments', ExifData.Comments);
    AddValue('Keywords', ExifData.Keywords);
    AddValue('Subject', ExifData.Subject);
    AddValue('Title', ExifData.Title);
    EndSection;
  end;

  if DoSection(esDetails, 'Exif sub-IFD') then
  begin
    AddValue('Exif version', ExifData.ExifVersion.AsString);
    AddValue('Aperture value', ExifData.ApertureValue);
    AddValue('Body serial number', ExifData.BodySerialNumber);
    AddValue('Brightness value', ExifData.BrightnessValue);
    AddValue('Camera owner', ExifData.CameraOwnerName);
    AddValue('Colour space', ColorSpaceToStr(ExifData.ColorSpace));
    AddValue('Compressed bits per pixel', ExifData.CompressedBitsPerPixel);
    AddValue('Date/time original', ExifData.DateTimeOriginal);
    AddValue('Date/time digitised', ExifData.DateTimeDigitized);
    AddValue('Digital zoom ratio', ExifData.DigitalZoomRatio);
    AddValue('Exif image width', ExifData.ExifImageWidth);
    AddValue('Exif image height', ExifData.ExifImageHeight);
    AddValue('Exposure programme', ExposureProgramToStr(ExifData.ExposureProgram));
    AddValue('Exposure time', ExifData.ExposureTime, 'seconds');
    AddValue('Exposure index', ExifData.ExposureIndex);
    AddValue('Exposure bias value', ExifData.ExposureBiasValue);
    AddValue('File source', FileSourceToStr(ExifData.FileSource));
    if not ExifData.Flash.MissingOrInvalid then
    begin
      AddValue('Flash present', ExifData.Flash.Present);
      AddValue('Flash mode', FlashModeToStr(ExifData.Flash.Mode));
      AddValue('Flash fired', ExifData.Flash.Fired);
      AddValue('Flash red eye reduction', ExifData.Flash.RedEyeReduction);
      AddValue('Flash strobe energy', ExifData.Flash.StrobeEnergy);
      AddValue('Flash strobe light', StrobeLightToStr(ExifData.Flash.StrobeLight));
    end;
    AddValue('F number', ExifData.FNumber);
    AddValue('Focal length', ExifData.FocalLength);
    AddValue('Focal length in 35mm film', ExifData.FocalLengthIn35mmFilm);
    AddValue('Focal plane resolution', ExifData.FocalPlaneResolution);
    AddValue('Gain control', GainControlToStr(ExifData.GainControl));
    AddValue('Image unique ID', ExifData.ImageUniqueID);
    if not ExifData.ISOSpeedRatings.MissingOrInvalid then
      AddValue('ISO speed rating(s)', ExifData.ISOSpeedRatings.AsString);
    AddValue('Lens make', ExifData.LensMake);
    AddValue('Lens model', ExifData.LensModel);
    AddValue('Lens serial number', ExifData.LensSerialNumber);
    AddValue('Light source', LightSourceToStr(ExifData.LightSource));
    AddValue('MakerNote data offset', ExifData.OffsetSchema);
    AddValue('Max aperture value', ExifData.MaxApertureValue);
    AddValue('Metering mode', MeteringModeToStr(ExifData.MeteringMode));
    AddValue('Related sound file', ExifData.RelatedSoundFile);
    AddValue('Rendering', RenderingToStr(ExifData.Rendering));
    AddValue('Scene capture type', SceneCaptureTypeToStr(ExifData.SceneCaptureType));
    AddValue('Scene type', SceneTypeToStr(ExifData.SceneType));
    AddValue('Sensing method', SensingMethodToStr(ExifData.SensingMethod));
    if ExifData.ShutterSpeedInMSecs <> 0 then
      AddValue('Shutter speed', '%.4g milliseconds', [ExifData.ShutterSpeedInMSecs]);
    AddValue('Subject distance', ExifData.SubjectDistance);
    AddValue('Spectral sensitivity', ExifData.SpectralSensitivity);
    AddValue('Subject distance', ExifData.SubjectDistance);
    AddValue('Subject distance range', SubjectDistanceRangeToStr(ExifData.SubjectDistanceRange));
    AddValue('Subject location', ExifData.SubjectLocation);
    AddValue('White balance mode', WhiteBalanceModeToStr(ExifData.WhiteBalanceMode));
    { don't do sub sec tags as their values are rolled into the date/times by the
      latters' property getters }
    EndSection;
  end;
  if DoSection(esInterop, 'Interoperability sub-IFD') then
  begin
    AddValue('Interoperability type', ExifData.InteropTypeName);
    AddValue('Interoperability version', ExifData.InteropVersion.AsString);
    EndSection;
  end;
  if DoSection(esGPS, 'GPS sub-IFD') then
  begin
    AddValue('GPS version', ExifData.GPSVersion.AsString);
    AddValue('GPS date/time (UTC)', ExifData.GPSDateTimeUTC);
    AddValue('GPS latitude', ExifData.GPSLatitude);
    AddValue('GPS longitude', ExifData.GPSLongitude);
    AddValue('GPS altitude', ExifData.GPSAltitude, 'metres ' +
      GPSAltitudeRefToStr(ExifData.GPSAltitudeRef));
    AddValue('GPS satellites', ExifData.GPSSatellites);
    AddValue('GPS status', GPSStatusToStr(ExifData.GPSStatus));
    AddValue('GPS measure mode', GPSMeasureModeToStr(ExifData.GPSMeasureMode));
    AddValue('GPS DOP', ExifData.GPSDOP);
    AddValue('GPS speed', ExifData.GPSSpeed, GPSSpeedRefToStr(ExifData.GPSSpeedRef));
    AddValue('GPS track', ExifData.GPSTrack, ExifData.GPSTrackRef);
    AddValue('GPS image direction', ExifData.GPSImgDirection,
      ExifData.GPSImgDirectionRef);
    AddValue('GPS map datum', ExifData.GPSMapDatum);
    AddValue('GPS destination latitude', ExifData.GPSDestLatitude);
    AddValue('GPS destination longitude', ExifData.GPSDestLongitude);
    AddValue('GPS destination bearing', ExifData.GPSDestBearing,
      ExifData.GPSDestBearingRef);
    AddValue('GPS destination distance', ExifData.GPSDestDistance,
      ExifData.GPSDestDistanceRef);
    AddValue('GPS differential', GPSDifferentialToStr(ExifData.GPSDifferential));
    EndSection;
  end;
  if DoSection(esThumbnail, 'Thumbnail IFD') then
  begin
    AddValue('Thumbnail orientation', OrientationToStr(ExifData.ThumbnailOrientation));
    AddValue('Thumbnail resolution', ExifData.ThumbnailResolution);
    {todo 1: write Thumbnail -
    if not ExifData.Thumbnail.Empty then imgThumbnail.Picture.Assign(ExifData.Thumbnail); }
    EndSection;
  end;
finally
  FInnerWriter.WriteEndObject;
  FInnerWriter.WriteEnd;
end;
end;

procedure TExifWriter.SetMakerNoteValueMap(const Value: TCustomIniFile);
begin
  FMakerNoteValueMap := Value;
end;

function TExifWriter.ToJSON: TJSONObject;
begin
//if FInnerWriter is TJsonObjectWriter then
    Result := TJSONObject(TJSONObjectWriter(FInnerWriter).JSON.Clone);
end;

procedure TExifWriter.LoadKeyValues(keyInfo: TFileVolBinded);
begin
  //
end;

procedure TExifWriter.LoadMakerNoteValues(MakerNote: TExifMakerNote; ValueMap: TCustomIniFile);

  procedure LoadValue(const Section, Ident, DefDescription, DefValue: string);
  begin
    AddValue(FInnerWriter, ValueMap.ReadString(Section, 'TagDescription',
      DefDescription), ValueMap.ReadString(Section, Ident, DefValue));
  end;
var
  I: Integer;
  S, Section, TypeName, ValueStr: string;
  Tag: TExifTag;
begin
  FInnerWriter.WriteStartObject;
  FInnerWriter.WritePropertyName('Tags');
  FInnerWriter.WriteStartObject;
  try
    if MakerNote is TUnrecognizedMakerNote then
    begin
      AddValue(FInnerWriter, 'Error', 'Unrecognised format');
      Exit;
    end;
    AddLoadErrorsValue(FInnerWriter, MakerNote.Tags);
//+test Демо-версия
AddValue(FInnerWriter, 'availability', 'Недоступно при демонстрации');
exit;
//-test
    TypeName := ValueMap.ReadString(MakerNote.ClassName, 'UseTagsFrom', '');
    if TypeName = '' then
      TypeName := MakerNote.ClassName;
    for Tag in MakerNote.Tags do
    begin
      FmtStr(Section, '%s.$%.4x', [TypeName, Tag.ID]);
      if Tag.WellFormed and ValueMap.ReadBool(Section, 'TreatAsTagGroup', False)
      then
        for I := 0 to Tag.ElementCount - 1 do
        begin
          S := ValueMap.ReadString(Section, 'TagDescription', '');
          if S <> '' then
            S := Format('%s (%d)', [S, I])
          else
            S := Format('Unknown ($%.4x, %d)', [Tag.ID, I]);
          ValueStr := Tag.ElementAsString[I];
          LoadValue(Format('%s(%d)', [Section, I]), ValueStr, S, ValueStr);
        end
      else
      begin
        if not Tag.WellFormed then
          ValueStr := '[Badly formed tag header]'
        else if Tag.DataType = tdUndefined then
          if Tag.ElementCount > 50 then
            ValueStr := Format('{%s...}', [Copy(Tag.AsString, 1, 100)])
          else
            ValueStr := Format('{%s}', [Tag.AsString])
            // else if (Tag.ID = ttPanasonicTimeSincePowerOn) and (ExifData.MakerNoteType = TPanasonicMakerNote) then
            // ValueStr := SecsToStr(Tag.ReadLongWord(0, 0) div 100)
        else
          ValueStr := Tag.AsString;
        LoadValue(Section, Tag.AsString, Format('Unknown ($%.4x)', [Tag.ID]), ValueStr);
      end;
    end;
  finally
    AddValue(FInnerWriter, SEndiannessCaption, SEndianness[MakerNote.Endianness]);
    TypeName := MakerNote.ClassName;
    AddValue(FInnerWriter, 'Type', Copy(TypeName, 2, Length(TypeName) - 10));
    //lsvMakerNote.Items.Insert(0).Caption := SGeneral;
    FInnerWriter.WriteEndObject;
    FInnerWriter.WriteEnd;
  end;
end;

(*procedure TExifWRTLoader.LoadFromFile(const FileName: string; MakerNoteValueMap: TCustomIniFile);
var
  ExifData: TExifData;
begin
  grpThumbnail.Hide;
  imgThumbnail.Picture.Assign(nil);
  ExifData := nil;
  lsvStandard.Items.BeginUpdate;
  lsvMakerNote.Items.BeginUpdate;
  try
    lsvStandard.Items.Clear;
    lsvMakerNote.Items.Clear;
    ExifData := TExifData.Create;
    ExifData.EnsureEnumsInRange := False; //as we use case statements rather than array constants, no need to keep this property set to True
    ExifData.LoadFromGraphic(FileName);
    if ExifData.Empty then
      lsvStandard.Items.Add.Caption := 'No Exif metadata found'
    else
      LoadStandardValues(ExifData);
    if ExifData.HasMakerNote then
      LoadMakerNoteValues(ExifData.MakerNote, MakerNoteValueMap)
    else
      lsvMakerNote.Items.Add.Caption := 'No MakerNote found';
  finally
    lsvStandard.Items.EndUpdate;
    lsvMakerNote.Items.EndUpdate;
    ExifData.Free;
  end;
  if imgThumbnail.Picture.Graphic <> nil then
  begin
    grpThumbnail.Width := (grpThumbnail.Width - imgThumbnail.Width) +
      imgThumbnail.Picture.Width;
    grpThumbnail.Visible := True;
  end;
end;
*)

end.
