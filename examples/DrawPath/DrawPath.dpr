program DrawPath;

uses
  Vcl.Forms,
  MainFormU in 'MainFormU.pas' {$R *.res};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
