program DrawLines;

uses
  Vcl.Forms,
  MainFormU in 'MainFormU.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
