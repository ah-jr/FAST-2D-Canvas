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
  TContainer = class(TPanel)
    private
      procedure WMPaint(var Msg : TWMPaint); message WM_PAINT;
      procedure WMEraseBkgnd(var Msg : TMessage); message WM_ERASEBKGND;
  end;

  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);

  private
    m_pnlD3dCanvas : TContainer;

    m_f2dCanvas : TF2DCanvas;
    m_tmrRender : TTimer;
    m_nAngleDif : Integer;

    procedure RenderScreen(Sender: TObject);

  end;

var
  MainForm : TMainForm;

implementation

uses
  Math;

{$R *.dfm}

//==============================================================================
procedure TContainer.WMPaint(var Msg : TWMPaint);
var
  PS: TPaintStruct;
begin
  BeginPaint(Handle, PS);
  EndPaint(Handle, PS);
end;

//==============================================================================
procedure TContainer.WMEraseBkgnd(var Msg : TMessage);
begin
  //
end;

//==============================================================================
procedure TMainForm.FormCreate(Sender: TObject);
var
  f2dProp : TF2DCanvasProperties;
begin
  m_pnlD3dCanvas := TContainer.Create(Self);
  m_pnlD3dCanvas.Parent := Self;
  m_pnlD3dCanvas.Align  := alClient;


  with f2dProp do
  begin
    Hwnd   := m_pnlD3dCanvas.Handle;
    Width  := m_pnlD3dCanvas.Width;
    Height := m_pnlD3dCanvas.Height;
    MSAA   := 8;
  end;

  //////////////////////////////////////////////////////////////////////////////
  ///  Create canvas
  m_f2dCanvas := TF2DCanvas.Create(f2dProp);

  //////////////////////////////////////////////////////////////////////////////
  ///  Set up render Timer
  m_tmrRender := TTImer.Create(Self);
  m_tmrRender.OnTimer  := RenderScreen;
  m_tmrRender.Interval := 10;
  m_tmrRender.Enabled  := True;

  //////////////////////////////////////////////////////////////////////////////
  ///  Variables
  m_nAngleDif := 0;
end;

//==============================================================================
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  m_tmrRender.Enabled := False;
  FreeAndNil(m_tmrRender);
end;

//==============================================================================
procedure TMainForm.FormResize(Sender: TObject);
begin
  m_f2dCanvas.ChangeSize(ClientWidth, ClientHeight);

  RenderScreen(nil);
end;

//==============================================================================
procedure TMainForm.RenderScreen(Sender: TObject);
var
  pntRotate : TPointF;           i : Integer;
const
  c_nRotatorLength = 100;
  c_nRotatePeriod  = 50;
begin
  m_f2dCanvas.BeginDraw;
  m_f2dCanvas.Clear($FF000000);

  // Write rounded rectangle in the back
  m_f2dCanvas.DrawColor := $6F202FFF;
  m_f2dCanvas.DrawRoundRect(PointF(20, 20), PointF(ClientWidth - 20, ClientHeight - 20), 10);

  // Write 'Lines' with lines
  m_f2dCanvas.LineWidth := 10;
  m_f2dCanvas.LineCap   := lcRound;
  m_f2dCanvas.DrawColor := $FFFF1F1F;

  m_f2dCanvas.DrawLine(PointF(50, 50), PointF(50, 200));
  m_f2dCanvas.DrawLine(PointF(50, 200), PointF(150, 200));

  m_f2dCanvas.DrawLine(PointF(200, 80), PointF(200, 200));

  m_f2dCanvas.DrawLine(PointF(250, 80), PointF(250, 200));
  m_f2dCanvas.DrawLine(PointF(250, 80), PointF(350, 200));
  m_f2dCanvas.DrawLine(PointF(350, 80), PointF(350, 200));

  m_f2dCanvas.DrawLine(PointF(400, 80), PointF(400, 200));
  m_f2dCanvas.DrawLine(PointF(400, 80), PointF(500, 80));
  m_f2dCanvas.DrawLine(PointF(400, 140), PointF(500, 140));
  m_f2dCanvas.DrawLine(PointF(400, 200), PointF(500, 200));

  m_f2dCanvas.DrawLine(PointF(550, 80), PointF(650, 80));
  m_f2dCanvas.DrawLine(PointF(550, 140), PointF(650, 140));
  m_f2dCanvas.DrawLine(PointF(550, 200), PointF(650, 200));
  m_f2dCanvas.DrawLine(PointF(550, 80), PointF(550, 140));
  m_f2dCanvas.DrawLine(PointF(650, 140), PointF(650, 200));

  m_f2dCanvas.LineWidth := 20;
  m_f2dCanvas.LineCap   := lcMitter;
  m_f2dCanvas.DrawColor := $FF00FFFF;
  m_f2dCanvas.DrawLine(PointF(50, 260), PointF(240, 360));
  m_f2dCanvas.LineWidth := 10;
  m_f2dCanvas.DrawLine(PointF(50, 290), PointF(240, 390));
  m_f2dCanvas.LineWidth := 5;
  m_f2dCanvas.DrawLine(PointF(50, 320), PointF(240, 420));
  m_f2dCanvas.LineWidth := 2;
  m_f2dCanvas.DrawLine(PointF(50, 350), PointF(240, 450));

  m_f2dCanvas.DrawColor := $FFBBBBBB;
  m_f2dCanvas.LineWidth := 2;
  for i := 0 to 100 do
    m_f2dCanvas.DrawLine(50 + 6*i, 225, 50 + 6*(i+1), 235);


  // Draw rectangles
  m_f2dCanvas.DrawColor := $AF505FFF;
  m_f2dCanvas.DrawRect(PointF(50, 450), PointF(100, 500));
  m_f2dCanvas.DrawColor := $AFF0AF1F;
  m_f2dCanvas.DrawRect(PointF(80, 480), PointF(130, 530));

  // Draw arcs
  m_f2dCanvas.DrawColor := $FF1F1F1F;
  m_f2dCanvas.DrawArc(PointF(400, 400), c_nRotatorLength, c_nRotatorLength, 0, 0.75);
  m_f2dCanvas.DrawColor := $FF0F0F0F;
  m_f2dCanvas.DrawArc(PointF(400, 400), c_nRotatorLength, c_nRotatorLength, 0.75, 0.25);

  m_f2dCanvas.DrawColor := $FF1ACA90;
  m_f2dCanvas.DrawArc(PointF(600, 400), 60, 90, 0, 1);

  // Draw rotating line
  pntRotate.X := 400 + c_nRotatorLength * Sin(-2 * Pi * (m_nAngleDif/c_nRotatePeriod));
  pntRotate.Y := 400 + c_nRotatorLength * Cos(-2 * Pi * (m_nAngleDif/c_nRotatePeriod));

  m_f2dCanvas.DrawColor := $FFFFFFFF;
  m_f2dCanvas.LineWidth := 5;
  m_f2dCanvas.DrawLine(PointF(400, 400), pntRotate);

  Inc(m_nAngleDif);
  if m_nAngleDif >= c_nRotatePeriod then
    m_nAngleDif := 0;

  m_f2dCanvas.EndDraw;
end;

//==============================================================================
end.
