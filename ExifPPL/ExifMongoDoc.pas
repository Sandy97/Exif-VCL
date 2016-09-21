unit ExifMongoDoc;

interface

uses
  System.Classes, System.SysUtils, //System.IniFiles,
  CCR.Exif, CCR.Exif.BaseUtils, CCR.Exif.TiffUtils,
  DateUtils, StrUtils, System.Types,
  ConvertersUtils,
  FireDAC.Phys.MongoDBWrapper;

type
  TExifMongoDoc = class (TMongoDocument)
  private
  public
    function BeginObject(const name: string):TexifMongoDoc;
    function EndObject:TexifMongoDoc;
    function BeginArray(const name: string):TexifMongoDoc;
    function EndArray:TexifMongoDoc;
    function Append(const ADoc: TExifMongoDoc): TExifMongoDoc; overload;
    function Append(const AJSON: String): TExifMongoDoc; overload;
    function Append(const AItems: array of const): TExifMongoDoc; overload;

    function AddValue(const Name: string; const DateTime: TDateTimeTagValue): TExifMongoDoc; overload;
    function AddValue(const Name: string; const Fraction: TExifFraction; const Units: string = ''): TExifMongoDoc; overload;
    function AddValue(const Name: string; const Fraction: TExifSignedFraction): TExifMongoDoc; overload;
    function AddValue(const Name, Value: string; const Args: array of const): TExifMongoDoc; overload;
    function AddValue(const name: string; const value: Int64): TExifMongoDoc; overload;
    function AddValue(const Name: string; YesNoValue: Boolean): TExifMongoDoc; overload;
    function AddValue(const Name: string; const Distance: TExifFraction; Ref: TGPSDistanceRef): TExifMongoDoc; overload;
    function AddValue(const Name: string; Resolution: TCustomExifResolution): TExifMongoDoc; overload;
    function AddValue(const name, value: string): TExifMongoDoc; overload;
    function AddValue(const Name: string; const Value: TSmallPoint): TExifMongoDoc; overload;
    function AddValue(const Name: string; Coord: TGPSCoordinate): TExifMongoDoc; overload;
    function AddValue(const Name: string; const Direction: TExifFraction; Ref: TGPSDirectionRef): TExifMongoDoc; overload;

    function AddLoadErrorsValue(Section: TExifSection): TExifMongoDoc;
    function DoSection(Kind: TExifSectionKind; const Name: string; ExifData: TExifData): TExifMongoDoc;
    function EndSection: TExifMongoDoc;
  end;

implementation

function TExifMongoDoc.AddValue(const Name, Value: string; const Args: array of const): TExifMongoDoc;
begin
  result := TExifMongoDoc(Add(Name, Format(value, Args)));
end;

function TExifMongoDoc.AddValue(const name: string; const value: Int64): TExifMongoDoc;
begin
  //if value <> 0 then
    result := TExifMongoDoc(Add(Name, IntToStr(value)));
end;

function TExifMongoDoc.AddValue(const Name: string; YesNoValue: Boolean): TExifMongoDoc;
begin
  result := TExifMongoDoc(Add(Name, SNoYes[YesNoValue]));
end;

function TExifMongoDoc.AddValue(const Name: string; const DateTime: TDateTimeTagValue): TExifMongoDoc;
begin
  result:=Self;
  if not DateTime.MissingOrInvalid then
    result := TExifMongoDoc(Add(Name, DateTimeToStr(DateTime)));
end;

function TExifMongoDoc.AddValue(const Name: string; const Fraction: TExifFraction; const Units: string = ''): TExifMongoDoc;
begin
  result:=Self;
  if not Fraction.MissingOrInvalid then
    result := AddValue(Name, '%g %s', [Fraction.Quotient, Units]);
end;

function TExifMongoDoc.AddValue(const Name: string; const Fraction: TExifSignedFraction): TExifMongoDoc;
begin
  result:=Self;
  if not Fraction.MissingOrInvalid then
    result := AddValue(Name, '%g', [Fraction.Quotient]);
end;

function TExifMongoDoc.AddValue(const Name: string; const Value: TSmallPoint): TExifMongoDoc;
begin
  result:=Self;
  if not InvalidPoint(Value) then
    result := AddValue(Name, '(%d, %d)', [Value.x, Value.y]);
end;

function TExifMongoDoc.AddValue(const Name: string; Coord: TGPSCoordinate): TExifMongoDoc;
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

function TExifMongoDoc.AddValue(const Name: string; const Direction: TExifFraction; Ref: TGPSDirectionRef): TExifMongoDoc;
begin
  result:=Self;
  if not Direction.MissingOrInvalid then
    result := AddValue(Name, '%g %s', [Direction.Quotient, DirectionRefToStr(Ref)]);
end;

function TExifMongoDoc.Append(const AJSON: String): TExifMongoDoc;
begin
  result := TExifMongoDoc(inherited Append(AJSON));
end;

function TExifMongoDoc.Append(const ADoc: TExifMongoDoc): TExifMongoDoc;
begin
  result := TExifMongoDoc(inherited Append(ADoc));
end;

function TExifMongoDoc.Append(const AItems: array of const): TExifMongoDoc;
begin
  result := TExifMongoDoc(inherited Append(AItems));
end;

function TExifMongoDoc.BeginArray(const name: string): TexifMongoDoc;
begin
  result := TExifMongoDoc(inherited BeginArray(name));
end;

function TExifMongoDoc.BeginObject(const name: string): TexifMongoDoc;
begin
  result := TExifMongoDoc(inherited BeginObject(name));
end;

function TExifMongoDoc.AddValue(const Name: string; const Distance: TExifFraction;
  Ref: TGPSDistanceRef): TExifMongoDoc;
begin
  result:=Self;
  if not Distance.MissingOrInvalid then
    result := AddValue(Name, '%g %s', [Distance.Quotient, DistanceRefToStr(Ref)]);
end;

function TExifMongoDoc.AddValue(const Name: string; Resolution: TCustomExifResolution): TExifMongoDoc;
begin
  result:=Self;
  if not Resolution.MissingOrInvalid then
    result := AddValue(Name, '%g x %g %s', [Resolution.X.Quotient, Resolution.Y.Quotient,
      ResolutionUnitsToStr(Resolution.Units)]);
end;

function TExifMongoDoc.AddValue(const name, value: string): TExifMongoDoc;
begin
  result := TExifMongoDoc(Add(name, value));
end;

function TExifMongoDoc.AddLoadErrorsValue(Section: TExifSection): TExifMongoDoc;
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

  result := TExifMongoDoc(Add('Loaded cleanly', S));
end;

function TExifMongoDoc.DoSection(Kind: TExifSectionKind; const Name: string; ExifData:TExifData): TExifMongoDoc;
begin
  Result := Self;
  if not (ExifData[Kind].Count > 0) or (ExifData[Kind].LoadErrors <> []) then exit;
  Result:= TExifMongoDoc(BeginObject(Name));
  AddLoadErrorsValue(ExifData[Kind]);
end;

function TExifMongoDoc.EndArray: TExifMongoDoc;
begin
  result := TExifMongoDoc(inherited EndArray);
end;

function TExifMongoDoc.EndObject: TexifMongoDoc;
begin
  result := TExifMongoDoc(inherited EndObject);
end;

function TExifMongoDoc.EndSection: TExifMongoDoc;
begin
  Result:=EndObject;
end;

end.
