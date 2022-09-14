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
  D3D11,
  D3D11_JSB,
  DXTypes_JSB,
  DXGI_JSB,
  D3DCommon_JSB,
  D3DCommon;

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
  RASTERIZER_DESC: Winapi.D3D11.D3D11_RASTERIZER_DESC;
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

//  RASTERIZER_DESC := Winapi.D3D11.D3D11_Rasterizer_Desc.Create(True);
//  RASTERIZER_DESC.CullMode := Winapi.D3D11.D3D11_CULL_NONE;
//  m_d3dCanvas.Device.CreateRasterizerState(D3D11_RASTERIZER_DESC(RASTERIZER_DESC), ppRasterizerState);
//  m_d3dCanvas.DeviceContext.RSSetState(ppRasterizerState);

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
  pVSBuffer : Winapi.D3DCommon.ID3DBlob;
  pPSBuffer : Winapi.D3DCommon.ID3DBlob;
  d3dLinkage : ID3D11ClassLinkage;
  shaderInputLayout : TD3D11_InputElementDesc;

  vertices : array of TSimpleVertex;

  vertexDesc : D3D11_BUFFER_DESC;

  resourceData : D3D11_SUBRESOURCE_DATA;
const
  c_numLayoutElements = 1;
begin
  m_d3dCanvas.CompileShader('ShaderGreenColor.fx', 'VS_Main', 'vs_4_0', pVSBuffer);
  m_d3dCanvas.Device.CreateVertexShader(pVSBuffer.GetBufferPointer, pVSBuffer.GetBufferSize, d3dLinkage, m_pVertexShader);

  //SetLength(shaderInputLayout, c_numLayoutElements);

  shaderInputLayout.SemanticName := 'Position';
  shaderInputLayout.SemanticIndex := 0;
  shaderInputLayout.Format := DXGI_FORMAT_R32G32B32_FLOAT;
  shaderInputLayout.InputSlot := 0;
  shaderInputLayout.AlignedByteOffset := 0;
  shaderInputLayout.InputSlotClass := D3D11_INPUT_PER_VERTEX_DATA;
  shaderInputLayout.InstanceDataStepRate := 0;

  m_d3dCanvas.Device.CreateInputLayout(@shaderInputLayout, c_numLayoutElements, pVSBuffer.GetBufferPointer, pVSBuffer.GetBufferSize, m_pInputLayout);

  pVSBuffer := nil;

  m_d3dCanvas.CompileShader('ShaderGreenColor.fx', 'PS_Main', 'ps_4_0', pPSBuffer);
  m_d3dCanvas.Device.CreatePixelShader(pPSBuffer.GetBufferPointer, pPSBuffer.GetBufferSize, d3dLinkage, m_pPixelShader);

  pPSBuffer := nil;

  SetLength(vertices, 3);

  vertices[0].pos[0] := 0;
  vertices[0].pos[1] := 0.5;
  vertices[0].pos[2] := 0.5;

  vertices[1].pos[0] := 0.5;
  vertices[1].pos[1] := -0.5;
  vertices[1].pos[2] := 0.5;

  vertices[2].pos[0] := -0.5;
  vertices[2].pos[1] := -0.5;
  vertices[2].pos[2] := 0.5;

  ZeroMemory(@vertexDesc, sizeof(vertexDesc));

  vertexDesc.Usage := D3D11_USAGE_DEFAULT;
  vertexDesc.BindFlags := Cardinal(D3D11_BIND_VERTEX_BUFFER);
  vertexDesc.ByteWidth := sizeof(TSimpleVertex) * 3 ;

  ZeroMemory(@resourceData, sizeof(resourceData));
  resourceData.pSysMem := vertices;

  m_d3dCanvas.Device.CreateBuffer(vertexDesc, @resourceData, m_pVertexBuffer);
end;

//==============================================================================
procedure TMainForm.Render;
var
  BLEND_DESC: D3D11.D3D11_BLEND_DESC;
  ppBlendState: ID3D11BlendState;
  stride, offset : UINT;
begin
  //BLEND_DESC := D3D11.D3D11_BLEND_DESC.Create(True);

  m_d3dCanvas.Clear(D3DColor4f(0.0, 1.0, 0.0, 1.0));
  //m_d3dCanvas.Device.CreateBlendState(TD3D11_BlendDesc(BLEND_DESC), ppBlendState);
  //m_d3dCanvas.DeviceContext.OMSetBlendState(ppBlendState, D3DColor4f(1.0, 1.0, 1.0, 1.0), $ffffffff);

  stride := sizeof(TSimpleVertex);
  offset := 0;

  m_d3dCanvas.DeviceContext.IASetInputLayout(m_pInputLayout);
  m_d3dCanvas.DeviceContext.IASetVertexBuffers(0, 1, @m_pVertexBuffer, @stride, @offset);
  m_d3dCanvas.DeviceContext.IASetPrimitiveTopology(TD3D11_PrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_LINESTRIP));

  m_d3dCanvas.DeviceContext.VSSetShader(m_pVertexShader, 0, 0);
  m_d3dCanvas.DeviceContext.PSSetShader(m_pPixelShader, 0, 0);

  m_d3dCanvas.DeviceContext.Draw(3, 0);


  m_d3dCanvas.Paint;
end;

//==============================================================================
procedure TMainForm.pnlD3dCanvasMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  Render;
end;

end.
