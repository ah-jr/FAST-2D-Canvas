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
      procedure WMPaint     (var Msg : TWMPaint); message WM_PAINT;
      procedure WMEraseBkgnd(var Msg : TMessage); message WM_ERASEBKGND;
  end;

  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);

  private
    m_pnlF2dCanvas : TContainer;

    m_f2dCanvas : TF2DCanvas;
    m_tmrRender : TTimer;
    m_nAngleDif : Integer;

    procedure RenderScreen(Sender: TObject);

  end;

var
  MainForm : TMainForm;

implementation

uses
  Generics.Collections,
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
  m_pnlF2dCanvas := TContainer.Create(Self);
  m_pnlF2dCanvas.Parent := Self;
  m_pnlF2dCanvas.Align  := alClient;


  with f2dProp do
  begin
    Hwnd   := m_pnlF2dCanvas.Handle;
    Width  := m_pnlF2dCanvas.Width;
    Height := m_pnlF2dCanvas.Height;
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
  f2dPath   : TF2DPath;
const
  c_nRotatePeriod  = 50;
begin
  m_f2dCanvas.BeginDraw;

  Inc(m_nAngleDif);
  if m_nAngleDif >= c_nRotatePeriod then
    m_nAngleDif := 0;

  f2dPath := TF2DPath.Create;
  f2dPath.AddPoint(10, 10);
  f2dPath.AddPoint(20, 10);
  f2dPath.AddPoint(20, 20);
  f2dPath.AddPoint(30, 20);
  f2dPath.AddPoint(30, 40);
  f2dPath.AddPoint(12, 30);
  f2dPath.AddPoint(20, 45);
  f2dPath.AddPoint(10, 45);

  f2dPath.Scale(4 * m_nAngleDif/c_nRotatePeriod + 1, 4 * m_nAngleDif/c_nRotatePeriod + 1);

  m_f2dCanvas.FillPath(f2dPath);
  m_f2dCanvas.LineCap := lcRound;
  m_f2dCanvas.DrawColor := $FFFFFFFF;
  m_f2dCanvas.DrawPath(f2dPath);

  m_f2dCanvas.EndDraw;
end;

//==============================================================================
end.
