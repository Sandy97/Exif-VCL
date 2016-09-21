unit ExifMongoHelper;

interface

uses
  System.Classes, System.SysUtils, //System.IniFiles,
  CCR.Exif, CCR.Exif.BaseUtils, CCR.Exif.TiffUtils,
  DateUtils, StrUtils, System.Types,
  ConvertersUtils,
  FireDAC.Phys.MongoDBWrapper;

type
  TExifMongoHelper = class helper  for TMongoDocument
  private
  public
    function AddValue(const Name: string; const DateTime: TDateTimeTagValue): TMongoDocument; overload;
    function AddValue(const Name: string; const Fraction: TExifFraction; const Units: string = ''): TMongoDocument; overload;
    function AddValue(const Name, Value: string; const Args: array of const): TMongoDocument; overload;
    function AddValue(const name, value: string): TMongoDocument; overload;
    function AddValue(const Name: string; const Fraction: TExifSignedFraction): TMongoDocument; overload;
    function AddValue(const name: string; const value: Int64): TMongoDocument; overload;
    function AddValue(const Name: string; YesNoValue: Boolean): TMongoDocument; overload;
    function AddValue(const Name: string; const Distance: TExifFraction; Ref: TGPSDistanceRef): TMongoDocument; overload;
    function AddValue(const Name: string; Resolution: TCustomExifResolution): TMongoDocument; overload;
    function AddValue(const Name: string; const Value: TSmallPoint): TMongoDocument; overload;
    function AddValue(const Name: string; Coord: TGPSCoordinate): TMongoDocument; overload;
    function AddValue(const Name: string; const Direction: TExifFraction; Ref: TGPSDirectionRef): TMongoDocument; overload;

    function AddLoadErrorsValue(Section: TExifSection): TMongoDocument;
    function DoSection(Kind: TExifSectionKind; const Name: string; ExifData: TExifData): TMongoDocument;
    function EndSection: TMongoDocument;
    //function isSectionHere(Kind: TExifSectionKind; const Name: string; ExifData: TExifData): boolean;
  end;

implementation

function TExifMongoHelper.AddValue(const Name, Value: string; const Args: array of const): TMongoDocument;
begin
  result := Add(Name, Format(value, Args));
end;

function TExifMongoHelper.AddValue(const name: string; const value: Int64): TMongoDocument;
begin
  Result:=Self;
  if value <> 0 then
    result := Add(Name, IntToStr(value));
end;

function TExifMongoHelper.AddValue(const Name: string; YesNoValue: Boolean): TMongoDocument;
begin
  result := Add(Name, YesNoValue);
  //  result := Add(Name, SNoYes[YesNoValue]);
end;

function TExifMongoHelper.AddValue(const Name: string; const DateTime: TDateTimeTagValue): TMongoDocument;
begin
  result:=Self;
  if not DateTime.MissingOrInvalid then
    //result := Add(Name, DateTimeToStr(DateTime));
    result := Add(Name, DateTime);
end;

function TExifMongoHelper.AddValue(const Name: string; const Fraction: TExifFraction; const Units: string = ''): TMongoDocument;
begin
  result:=Self;
  if not Fraction.MissingOrInvalid then
    result := AddValue(Name, '%g %s', [Fraction.Quotient, Units]);
end;

function TExifMongoHelper.AddValue(const Name: string; const Fraction: TExifSignedFraction): TMongoDocument;
begin
  result:=Self;
  if not Fraction.MissingOrInvalid then
    result := AddValue(Name, '%g', [Fraction.Quotient]);
end;

function TExifMongoHelper.AddValue(const Name: string; const Value: TSmallPoint): TMongoDocument;
begin
  result:=Self;
  if not InvalidPoint(Value) then
    result := AddValue(Name, '(%d, %d)', [Value.x, Value.y]);
end;

function TExifMongoHelper.AddValue(const Name: string; Coord: TGPSCoordinate): TMongoDocument;
var
  DirectionStr: string;
begin
  result:=Self;
  if Coord.MissingOrInvalid then Exit;
  case Coord.Direction of
    'N': DirectionStr := 'north';
    'S': DirectionStr := 'south';
    'W': DirectionStr := 'west';
    'E': DirectionStr := 'east';
  else DirectionStr := '';
  end;
  result := AddValue(Name, '%g°, %g minutes and %g seconds %s', [Coord.Degrees.Quotient,
    Coord.Minutes.Quotient, Coord.Seconds.Quotient, DirectionStr]);
end;

function TExifMongoHelper.AddValue(const Name: string; const Direction: TExifFraction; Ref: TGPSDirectionRef): TMongoDocument;
begin
  result:=Self;
  if not Direction.MissingOrInvalid then
    result := AddValue(Name, '%g %s', [Direction.Quotient, DirectionRefToStr(Ref)]);
end;

function TExifMongoHelper.AddValue(const Name: string; const Distance: TExifFraction;
  Ref: TGPSDistanceRef): TMongoDocument;
begin
  result:=Self;
  if not Distance.MissingOrInvalid then
    result := AddValue(Name, '%g %s', [Distance.Quotient, DistanceRefToStr(Ref)]);
end;

function TExifMongoHelper.AddValue(const Name: string; Resolution: TCustomExifResolution): TMongoDocument;
begin
  result:=Self;
  if not Resolution.MissingOrInvalid then
    result := AddValue(Name, '%g x %g %s', [Resolution.X.Quotient, Resolution.Y.Quotient,
      ResolutionUnitsToStr(Resolution.Units)]);
end;

function TExifMongoHelper.AddValue(const name, value: string): TMongoDocument;
begin
  Result:=Self;
  if value <> '' then
    result := Add(name, value);
end;

function TExifMongoHelper.AddLoadErrorsValue(Section: TExifSection): TMongoDocument;
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
  result := Add('Loaded cleanly', S);
end;

function TExifMongoHelper.DoSection(Kind: TExifSectionKind; const Name: string; ExifData:TExifData): TMongoDocument;
begin
  Result := Self;
  if not (ExifData[Kind].Count > 0) or (ExifData[Kind].LoadErrors <> []) then exit;
  Result:= BeginObject(Name);
  AddLoadErrorsValue(ExifData[Kind]);
end;

function TExifMongoHelper.EndSection: TMongoDocument;
begin
  Result:=EndObject;
end;

end.
