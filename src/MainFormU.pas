unit MainFormU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  D3DCanvasU,
  Vcl.ExtCtrls;

type
  TMainForm = class(TForm)
    pnlD3dCanvas: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
  private
    m_d3dCanvas : TD3DCanvas;
  public
  end;

var
  MainForm : TMainForm;

implementation

{$R *.dfm}
//==============================================================================
procedure TMainForm.FormCreate(Sender: TObject);
var
  d3dProp : TD3DCanvasProperties;
begin
  with d3dProp do
  begin
    Hwnd := pnlD3dCanvas.Handle;
    Width := pnlD3dCanvas.Width;
    Height := pnlD3dCanvas.Height;
    MSAA := 4;
  end;

  m_d3dCanvas := TD3DCanvas.Create(d3dProp);
end;

//==============================================================================
procedure TMainForm.FormPaint(Sender: TObject);
begin
  //
end;

end.
