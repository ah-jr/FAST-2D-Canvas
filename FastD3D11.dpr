program FastD3D11;

uses
  Vcl.Forms,
  MainFormU  in 'src/MainFormU.pas',
  D3DCanvasU in 'src/D3DCanvasU.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
