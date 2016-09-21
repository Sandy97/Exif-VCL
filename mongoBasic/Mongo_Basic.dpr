//---------------------------------------------------------------------------

// This software is Copyright (c) 2015 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

program Mongo_Basic;

uses
  Vcl.Forms,
  fMain in 'fMain.pas' {frmMain},
  ExifMongoHelper in '..\ExifMongoHelper.pas',
  CCR.Exif in '..\..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.pas',
  CCR.Exif.Consts in '..\..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.Consts.pas',
  CCR.Exif.XMPUtils in '..\..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.XMPUtils.pas',
  CCR.Exif.TiffUtils in '..\..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.TiffUtils.pas',
  CCR.Exif.TagIDs in '..\..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.TagIDs.pas',
  CCR.Exif.StreamHelper in '..\..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.StreamHelper.pas',
  CCR.Exif.IPTC in '..\..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.IPTC.pas',
  CCR.Exif.BaseUtils in '..\..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.BaseUtils.pas',
  CCR.Exif.JpegUtils in '..\..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.JpegUtils.pas',
  ConvertersUtils in '..\ConvertersUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
