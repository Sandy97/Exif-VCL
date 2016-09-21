program FileExif;

uses
  Vcl.Forms,
  mfFileExif in 'mfFileExif.pas' {fmFileExif},
  CCR.Exif in 'C:\Users\asovtsov\Downloads\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.pas',
  CCR.Exif.Consts in 'C:\Users\asovtsov\Downloads\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.Consts.pas',
  CCR.Exif.XMPUtils in 'C:\Users\asovtsov\Downloads\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.XMPUtils.pas',
  CCR.Exif.TiffUtils in 'C:\Users\asovtsov\Downloads\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.TiffUtils.pas',
  CCR.Exif.TagIDs in 'C:\Users\asovtsov\Downloads\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.TagIDs.pas',
  CCR.Exif.StreamHelper in 'C:\Users\asovtsov\Downloads\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.StreamHelper.pas',
  CCR.Exif.IPTC in 'C:\Users\asovtsov\Downloads\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.IPTC.pas',
  CCR.Exif.BaseUtils in 'C:\Users\asovtsov\Downloads\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.BaseUtils.pas',
  CCR.Exif.JpegUtils in 'C:\Users\asovtsov\Downloads\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.JpegUtils.pas',
  ExifExtractor in 'ExifExtractor.pas',
  myUtils in 'myUtils.pas',
  ExifWRTLoader in 'ExifWRTLoader.pas',
  ConvertersUtils in 'ConvertersUtils.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('TabletDark');
  Application.CreateForm(TfmFileExif, fmFileExif);
  Application.Run;
end.
