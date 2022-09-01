program FastD3D11;

uses
  Vcl.Forms,
  MainFormU in 'src/MainFormU.pas',
  D3DeviceU in 'src/D3DeviceU.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
