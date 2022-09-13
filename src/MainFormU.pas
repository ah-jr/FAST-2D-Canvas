unit MainFormU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.DXTypes,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  D3DCanvasU,
  Vcl.ExtCtrls,
  D3DX11_JSB,
  D3D11_JSB,
  DXTypes_JSB,
  DXGI_JSB,
  D3DCommon_JSB;

type
  TMainForm = class(TForm)
    pnlD3dCanvas: TPanel;

    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure pnlD3dCanvasMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    m_d3dCanvas : TD3DCanvas;

    m_pVertexShader : ID3D11VertexShader;
    m_pPixelShader  : ID3D11PixelShader;
    m_pInputLayout  : ID3D11InputLayout;
    m_pVertexBuffer : ID3D11Buffer;



    procedure LoadContent;
    procedure Render;

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
  RASTERIZER_DESC: D3D11_RASTERIZER_DESC;
  ppRasterizerState: ID3D11RasterizerState;
begin
  with d3dProp do
  begin
    Hwnd   := pnlD3dCanvas.Handle;
    Width  := pnlD3dCanvas.Width;
    Height := pnlD3dCanvas.Height;
    MSAA   := 4;
  end;

  m_d3dCanvas := TD3DCanvas.Create(d3dProp);

  //RASTERIZER_DESC := D3D11_RasterizerDesc.Create(True);
  RASTERIZER_DESC.CullMode := D3D11_CULL_NONE;
  m_d3dCanvas.Device.CreateRasterizerState(RASTERIZER_DESC, ppRasterizerState);
  m_d3dCanvas.DeviceContext.RSSetState(ppRasterizerState);

  LoadContent;
end;

//==============================================================================
procedure TMainForm.FormPaint(Sender: TObject);
begin
  //
end;


//==============================================================================
procedure TMainForm.LoadContent;
var
  pVSBuffer : ID3DBlob;
  d3dLinkage : ID3D11ClassLinkage;
  shaderInputLayout : array of D3D11_INPUT_ELEMENT_DESC;
const
  c_numLayoutElements = 1;
begin
  m_d3dCanvas.CompileShader('ShaderGreenColor.fx', 'VS_Main', 'vs_4_0', pVSBuffer);

  m_d3dCanvas.Device.CreateVertexShader(pVSBuffer.GetBufferPointer, pVSBuffer.GetBufferSize, d3dLinkage, m_pVertexShader);

  SetLength(shaderInputLayout, c_numLayoutElements);

  shaderInputLayout[0].SemanticName := 'Position';
  shaderInputLayout[0].SemanticIndex := 0;
  shaderInputLayout[0].Format := DXGI_FORMAT_R32G32B32_FLOAT;
  shaderInputLayout[0].InputSlot := 0;
  shaderInputLayout[0].AlignedByteOffset := 0;
  shaderInputLayout[0].InputSlotClass := D3D11_INPUT_PER_VERTEX_DATA;
  shaderInputLayout[0].InstanceDataStepRate := 0;

  m_d3dCanvas.Device.CreateInputLayout(@shaderInputLayout, c_numLayoutElements, pVSBuffer.GetBufferPointer, pVSBuffer.GetBufferSize, m_pInputLayout);

  pVSBuffer._Release;



end;

//==============================================================================
procedure TMainForm.Render;
var
  BLEND_DESC: D3D11_BLEND_DESC;
  ppBlendState: ID3D11BlendState;
begin
  //BLEND_DESC := D3D11_BLEND_DESC.Create(True);

  m_d3dCanvas.Clear(D3DColor4f(0.0, 1.0, 0.0, 1.0));
  m_d3dCanvas.Device.CreateBlendState(BLEND_DESC, ppBlendState);
  m_d3dCanvas.DeviceContext.OMSetBlendState(ppBlendState, D3DColor4f(1.0, 1.0, 1.0, 1.0), $ffffffff);

  m_d3dCanvas.Paint;
end;

//==============================================================================
procedure TMainForm.pnlD3dCanvasMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  Render;
end;

end.
