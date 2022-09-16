unit MainFormU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Types,
  System.UITypes,
  Vcl.Graphics,
  Vcl.ExtCtrls,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  F2DTypesU,
  F2DCanvasU;

type
  TMainForm = class(TForm)
    pnlD3dCanvas: TPanel;

    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);

  private
    m_f2dCanvas : TF2DCanvas;

  end;

var
  MainForm : TMainForm;

implementation

{$R *.dfm}

//==============================================================================
procedure TMainForm.FormCreate(Sender: TObject);
var
  f2dProp : TF2DCanvasProperties;
begin
  with f2dProp do
  begin
    Hwnd   := pnlD3dCanvas.Handle;
    Width  := pnlD3dCanvas.Width;
    Height := pnlD3dCanvas.Height;
    MSAA   := 8;
  end;

  //////////////////////////////////////////////////////////////////////////////
  ///  Create canvas
  m_f2dCanvas := TF2DCanvas.Create(f2dProp);
end;

//==============================================================================
procedure TMainForm.FormPaint(Sender: TObject);
begin
  m_f2dCanvas.BeginDraw;

  m_f2dCanvas.Clear($FF000000);

  // Write 'Lines' with lines
  m_f2dCanvas.DrawLine(PointF(50, 50), PointF(50, 200), $FFFF0000, 1);
  m_f2dCanvas.DrawLine(PointF(50, 200), PointF(150, 200), $FFFF0000, 1);

  m_f2dCanvas.DrawLine(PointF(200, 80), PointF(200, 200), $FF00FF00, 1);

  m_f2dCanvas.DrawLine(PointF(250, 80), PointF(250, 200), $FF0000FF, 1);
  m_f2dCanvas.DrawLine(PointF(250, 80), PointF(350, 200), $FF0000FF, 1);
  m_f2dCanvas.DrawLine(PointF(350, 80), PointF(350, 200), $FF0000FF, 1);

  m_f2dCanvas.DrawLine(PointF(400, 80), PointF(400, 200), $FFFFFF00, 1);
  m_f2dCanvas.DrawLine(PointF(400, 80), PointF(500, 80), $FFFFFF00, 1);
  m_f2dCanvas.DrawLine(PointF(400, 140), PointF(500, 140), $FFFFFF00, 1);
  m_f2dCanvas.DrawLine(PointF(400, 200), PointF(500, 200), $FFFFFF00, 1);

  m_f2dCanvas.DrawLine(PointF(550, 80), PointF(650, 80), $FF00FFFF, 1);
  m_f2dCanvas.DrawLine(PointF(550, 140), PointF(650, 140), $FF00FFFF, 1);
  m_f2dCanvas.DrawLine(PointF(550, 200), PointF(650, 200), $FF00FFFF, 1);
  m_f2dCanvas.DrawLine(PointF(550, 80), PointF(550, 140), $FF00FFFF, 1);
  m_f2dCanvas.DrawLine(PointF(650, 140), PointF(650, 200), $FF00FFFF, 1);

  // Draw Rectangles:
  m_f2dCanvas.DrawRect(PointF(50, 450), PointF(100, 500), $AFFF2050, 1);
  m_f2dCanvas.DrawRect(PointF(80, 480), PointF(130, 530), $8F50FF50, 1);


  m_f2dCanvas.EndDraw;
end;

//==============================================================================
end.
