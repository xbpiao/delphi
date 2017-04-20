program BLPBrowser;

uses
  Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  AsphyreBLP in 'AsphyreBLP.pas',
  jpeg_xe2 in 'jpeg\jpeg_xe2.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
