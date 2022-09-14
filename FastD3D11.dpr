program FastD3D11;

uses
  Vcl.Forms,
  MainFormU in 'src\MainFormU.pas',
  F2DCanvasU in 'src\F2DCanvasU.pas',
  F2DMathU in 'src\F2DMathU.pas',
  F2DRendererU in 'src\F2DRendererU.pas',
  F2DTypesU in 'src\F2DTypesU.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
