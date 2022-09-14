unit F2DCanvasU;

interface

uses
  Windows,
  DXTypes,
  SysUtils,
  UITypes,
  Types,
  D3D11,
  D3DCommon,
  DxgiFormat,
  F2DRendererU,
  F2DMathU,
  F2DTypesU;

type
  TF2DCanvas = class
  private
    m_f2dRenderer   : TF2DRenderer;

    m_pVertexShader : ID3D11VertexShader;
    m_pPixelShader  : ID3D11PixelShader;
    m_pInputLayout  : ID3D11InputLayout;
    m_pVertexBuffer : ID3D11Buffer;
    m_pScreenBuffer : ID3D11Buffer;

    m_pBlendDesc    : ID3D11BlendState;
    m_matProj       : TXMMATRIX;

  public
    constructor Create(a_cpProp : TF2DCanvasProperties); reintroduce;
    destructor Destroy; Override;

    procedure InitRenderer;

    procedure BeginDraw;
    procedure EndDraw;

    ////////////////////////////////////////////////////////////////////////////
    ///  Drawing functions:
    procedure Clear(a_clColor : TAlphaColor);
    procedure DrawLine(a_pntA : TPointF; a_pntB : TPointF; a_clColor : TAlphaColor; a_nWidth : Single);

  end;

implementation

//==============================================================================
constructor TF2DCanvas.Create(a_cpProp : TF2DCanvasProperties);
begin
  m_f2dRenderer := TF2DRenderer.Create(a_cpProp);

  InitRenderer;
end;

//==============================================================================
destructor TF2DCanvas.Destroy;
begin
  m_pVertexShader := nil;
  m_pPixelShader  := nil;
  m_pInputLayout  := nil;
  m_pVertexBuffer := nil;
  m_pScreenBuffer := nil;
end;

//==============================================================================
procedure TF2DCanvas.InitRenderer;
var
  d3dInputDesc     : array[0..1] of TD3D11_Input_Element_Desc;
  d3dRastDesc      : TD3D11_Rasterizer_Desc;
  d3dMappedRes     : TD3D11_Mapped_Subresource;
  d3dBufferDesc    : TD3D11_Buffer_Desc;
  d3dBlendDesc     : TD3D11_Blend_Desc;
  d3dViewport      : TD3D11_Viewport;
  pRasterizerState : ID3D11RasterizerState;
  pVSBuffer        : ID3DBlob;
  pPSBuffer        : ID3DBlob;
  pLinkage         : ID3D11ClassLinkage;
  nViewportCount   : UINT;
const
  c_nLayoutElementCount = 2;
begin
  //////////////////////////////////////////////////////////////////////////////
  ///  Rasterizer
  d3dRastDesc := TD3D11_Rasterizer_Desc.Create(True);
  d3dRastDesc.CullMode := D3D11_CULL_NONE;
  m_f2dRenderer.Device.CreateRasterizerState(D3D11_RASTERIZER_DESC(d3dRastDesc), pRasterizerState);
  m_f2dRenderer.DeviceContext.RSSetState(pRasterizerState);

  //////////////////////////////////////////////////////////////////////////////
  ///  Shaders and Input layout
  m_f2dRenderer.CompileShader('ScreenCoordinates.fx', 'VS_Main', 'vs_4_0', pVSBuffer);
  m_f2dRenderer.CompileShader('ScreenCoordinates.fx', 'PS_Main', 'ps_4_0', pPSBuffer);

  m_f2dRenderer.Device.CreateVertexShader(pVSBuffer.GetBufferPointer, pVSBuffer.GetBufferSize, pLinkage, @m_pVertexShader);
  m_f2dRenderer.Device.CreatePixelShader(pPSBuffer.GetBufferPointer, pPSBuffer.GetBufferSize, pLinkage, m_pPixelShader);

  d3dInputDesc[0].SemanticName         := 'POSITION';
  d3dInputDesc[0].SemanticIndex        := 0;
  d3dInputDesc[0].Format               := DXGI_FORMAT_R32G32B32_FLOAT;
  d3dInputDesc[0].InputSlot            := 0;
  d3dInputDesc[0].AlignedByteOffset    := 0;
  d3dInputDesc[0].InputSlotClass       := D3D11_INPUT_PER_VERTEX_DATA;
  d3dInputDesc[0].InstanceDataStepRate := 0;

  d3dInputDesc[1].SemanticName         := 'COLOR';
  d3dInputDesc[1].SemanticIndex        := 0;
  d3dInputDesc[1].Format               := DXGI_FORMAT_R32G32B32A32_FLOAT;
  d3dInputDesc[1].InputSlot            := 0;
  d3dInputDesc[1].AlignedByteOffset    := 16;
  d3dInputDesc[1].InputSlotClass       := D3D11_INPUT_PER_VERTEX_DATA;
  d3dInputDesc[1].InstanceDataStepRate := 0;

  m_f2dRenderer.Device.CreateInputLayout(@d3dInputDesc, c_nLayoutElementCount, pVSBuffer.GetBufferPointer, pVSBuffer.GetBufferSize, m_pInputLayout);

  pVSBuffer := nil;
  pPSBuffer := nil;

  //////////////////////////////////////////////////////////////////////////////
  ///  Blend
  d3dBlendDesc := TD3D11_Blend_Desc.Create(True);

  d3dBlendDesc.RenderTarget[0].BlendEnable           := True;
	d3dBlendDesc.RenderTarget[0].SrcBlend              := D3D11_BLEND_SRC_ALPHA;
	d3dBlendDesc.RenderTarget[0].DestBlend             := D3D11_BLEND_INV_SRC_ALPHA;
	d3dBlendDesc.RenderTarget[0].SrcBlendAlpha         := D3D11_BLEND_ONE;
	d3dBlendDesc.RenderTarget[0].DestBlendAlpha        := D3D11_BLEND_ZERO;
	d3dBlendDesc.RenderTarget[0].BlendOp               := D3D11_BLEND_OP_ADD;
	d3dBlendDesc.RenderTarget[0].BlendOpAlpha          := D3D11_BLEND_OP_ADD;
	d3dBlendDesc.RenderTarget[0].RenderTargetWriteMask := UINT8(D3D11_COLOR_WRITE_ENABLE_ALL);

  m_f2dRenderer.Device.CreateBlendState(d3dBlendDesc, m_pBlendDesc);

  //////////////////////////////////////////////////////////////////////////////
  ///  Vertex Buffer
  ZeroMemory(@d3dBufferDesc, Sizeof(d3dBufferDesc));

	d3dBufferDesc.Usage          := D3D11_USAGE_DYNAMIC;
	d3dBufferDesc.ByteWidth      := Sizeof(TScreenVertex) * 3;
	d3dBufferDesc.BindFlags      := D3D11_BIND_VERTEX_BUFFER;
	d3dBufferDesc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE;
	d3dBufferDesc.MiscFlags      := 0;

  m_f2dRenderer.Device.CreateBuffer(d3dBufferDesc, nil, m_pVertexBuffer);

  //////////////////////////////////////////////////////////////////////////////
  ///  Screen Buffer
  ZeroMemory(@d3dBufferDesc, Sizeof(d3dBufferDesc));

	d3dBufferDesc.Usage          := D3D11_USAGE_DYNAMIC;
	d3dBufferDesc.ByteWidth      := Sizeof(TXMMATRIX);
	d3dBufferDesc.BindFlags      := D3D11_BIND_CONSTANT_BUFFER;
	d3dBufferDesc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE;
	d3dBufferDesc.MiscFlags      := 0;

  m_f2dRenderer.Device.CreateBuffer(d3dBufferDesc, nil, m_pScreenBuffer);

  //////////////////////////////////////////////////////////////////////////////
  ///  View Port
  nViewportCount := 1;
	m_f2dRenderer.DeviceContext.RSGetViewports(nViewportCount, @d3dViewport);

  //////////////////////////////////////////////////////////////////////////////
  ///  Projection
	m_matProj := XMMatrixOrthographicOffCenterLH(d3dViewport.TopLeftX, d3dViewport.Width, d3dViewport.Height, d3dViewport.TopLeftY,
		d3dViewport.MinDepth, d3dViewport.MaxDepth);

  m_f2dRenderer.DeviceContext.Map(m_pScreenBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, d3dMappedRes);
  CopyMemory(d3dMappedRes.pData, @m_matProj, SizeOf(TXMMATRIX));
  m_f2dRenderer.DeviceContext.Unmap(m_pScreenBuffer, 0);
end;

//==============================================================================
procedure TF2DCanvas.BeginDraw;
var
  nStride : UINT;
  nOffset : UINT;
begin
	m_f2dRenderer.DeviceContext.VSSetShader(m_pVertexShader, nil, 0);
	m_f2dRenderer.DeviceContext.PSSetShader(m_pPixelShader, nil, 0);

	m_f2dRenderer.DeviceContext.OMSetBlendState(m_pBlendDesc, D3DColor4f(1.0, 1.0, 1.0, 1.0), $FFFFFFFF);
	m_f2dRenderer.DeviceContext.VSSetConstantBuffers(0, 1, m_pScreenBuffer);
	m_f2dRenderer.DeviceContext.IASetInputLayout(m_pInputLayout);

	nStride := SizeOf(TScreenVertex);
	nOffset := 0;
	m_f2dRenderer.DeviceContext.IASetVertexBuffers(0, 1, &m_pVertexBuffer, @nStride, @nOffset);
end;

//==============================================================================
procedure TF2DCanvas.EndDraw;
begin
  //
end;

//==============================================================================
procedure TF2DCanvas.Clear(a_clColor : TAlphaColor);
begin
  m_f2dRenderer.Clear(D3DColor4fARGB(a_clColor));
end;

//==============================================================================
procedure TF2DCanvas.DrawLine(a_pntA : TPointF; a_pntB : TPointF; a_clColor : TAlphaColor; a_nWidth : Single);
var
  d3dMappedRes : TD3D11_Mapped_Subresource;
  arrVertices  : array[0..1] of TScreenVertex;
begin
  arrVertices[0].pos[0] := a_pntA.X;
  arrVertices[0].pos[1] := a_pntA.Y;
  arrVertices[0].pos[2] := 0;

  arrVertices[1].pos[0] := a_pntB.X;
  arrVertices[1].pos[1] := a_pntB.Y;
  arrVertices[1].pos[2] := 0;

  arrVertices[0].color[0] := a_clColor and $00FF0000;
  arrVertices[0].color[1] := a_clColor and $0000FF00;
  arrVertices[0].color[2] := a_clColor and $000000FF;
  arrVertices[0].color[3] := a_clColor and $FF000000;

  arrVertices[1].color[0] := a_clColor and $00FF0000;
  arrVertices[1].color[1] := a_clColor and $0000FF00;
  arrVertices[1].color[2] := a_clColor and $000000FF;
  arrVertices[1].color[3] := a_clColor and $FF000000;

  m_f2dRenderer.DeviceContext.Map(m_pVertexBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, d3dMappedRes);
  CopyMemory(d3dMappedRes.pData, @arrVertices[0], SizeOf(arrVertices));
  m_f2dRenderer.DeviceContext.Unmap(m_pVertexBuffer, 0);

  m_f2dRenderer.DeviceContext.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_LINELIST);
  m_f2dRenderer.DeviceContext.Draw(3, 0);
  m_f2dRenderer.Paint;
end;

//==============================================================================
end.