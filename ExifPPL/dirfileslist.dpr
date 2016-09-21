program dirfileslist;

uses
  Vcl.Forms,
  uDirFileListPPL in 'uDirFileListPPL.pas' {fmDirFileList},
  CCR.Exif in '..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.pas',
  CCR.Exif.Consts in '..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.Consts.pas',
  CCR.Exif.XMPUtils in '..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.XMPUtils.pas',
  CCR.Exif.TiffUtils in '..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.TiffUtils.pas',
  CCR.Exif.TagIDs in '..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.TagIDs.pas',
  CCR.Exif.StreamHelper in '..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.StreamHelper.pas',
  CCR.Exif.IPTC in '..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.IPTC.pas',
  CCR.Exif.BaseUtils in '..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.BaseUtils.pas',
  CCR.Exif.JpegUtils in '..\CCR Exif v1.5.1\CCR Exif v1.5.1\CCR.Exif.JpegUtils.pas',
  myUtils in 'myUtils.pas',
  ConvertersUtils in 'ConvertersUtils.pas',
  CCR.Exif.Demos in '..\CCR Exif v1.5.1\CCR Exif v1.5.1\VCL Demos\CCR.Exif.Demos.pas',
  myTaskQueue in 'myTaskQueue.pas',
  ExifMemoContainer in 'ExifMemoContainer.pas',
  ExifMongoHelper in 'ExifMongoHelper.pas',
  ExifMongoLoaderTypesPPL in 'ExifMongoLoaderTypesPPL.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10');
  Application.CreateForm(TfmDirFileList, fmDirFileList);
  Application.Run;
end.
