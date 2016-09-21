program ExifMongo;

uses
  Vcl.Forms,
  mfExif in 'mfExif.pas' {fmMainUI},
  uSplitView in 'uSplitView.pas' {SplitViewForm},
  myUtils in 'myUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMainUI, fmMainUI);
  Application.CreateForm(TSplitViewForm, SplitViewForm);
  Application.Run;
end.
