unit F2DCanvasU;

interface

uses
  Windows,
  Generics.Collections,
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
    m_arrVertices   : array of TScreenVertex;
    m_lstRender     : TList<TRenderQueueItem>;

    m_clDraw        : TAlphaColor;
    m_clFill        : TAlphaColor;
    m_lcLineCap     : TF2DLineCap;
    m_sLineWidth    : Single;

    procedure GetWidth(var a_sWidth : Single);

  public
    constructor Create(a_cpProp : TF2DCanvasProperties); reintroduce;
    destructor Destroy; Override;

    procedure InitRenderer;
    procedure ChangeSize(a_nWidth : Integer; a_nHeight : Integer);

    procedure BeginDraw;
    procedure EndDraw;

    ////////////////////////////////////////////////////////////////////////////
    ///  Drawing functions:
    procedure Clear(a_clColor : TAlphaColor);
    procedure DrawLine(a_pntA : TPointF; a_pntB : TPointF; a_nWidth : Single = -1);
    procedure DrawRect(a_pntA : TPointF; a_pntB : TPointF; a_nWidth : Single = -1);
    procedure DrawArc(a_pntCenter : TPointF; a_nRadiusX : Double; a_nRadiusY : Double; a_dStartAngle : Single; a_dSizeRatio : Double; a_nWidth : Single = -1);

    property DrawColor : TAlphaColor   read m_clDraw      write m_clDraw;
    property FillColor : TAlphaColor   read m_clFill      write m_clFill;
    property LineCap   : TF2DLineCap   read m_lcLineCap   write m_lcLineCap;
    property LineWidth : Single        read m_sLineWidth  write m_sLineWidth;

  end;

implementation

uses
  Math;

//==============================================================================
constructor TF2DCanvas.Create(a_cpProp : TF2DCanvasProperties);
begin
  m_f2dRenderer := TF2DRenderer.Create(a_cpProp);

  m_lstRender := TList<TRenderQueueItem>.Create;

  m_sLineWidth := 1;
  m_clDraw     := c_clBlack;
  m_clFill     := c_clBlack;
  m_lcLineCap  := lcMitter;

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

  FreeAndNil(m_lstRender);
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
  nIndex           : Integer;
const
  c_nLayoutElementCount = 2;
begin
  //////////////////////////////////////////////////////////////////////////////
  ///  Rasterizer
  d3dRastDesc := TD3D11_Rasterizer_Desc.Create(True);

  d3dRastDesc.AntialiasedLineEnable := True;
  d3dRastDesc.CullMode              := D3D11_CULL_BACK;
  d3dRastDesc.DepthBias             := 0;
  d3dRastDesc.DepthBiasClamp        := 0;
  d3dRastDesc.DepthClipEnable       := True;
  d3dRastDesc.FillMode              := D3D11_FILL_SOLID;
  d3dRastDesc.FrontCounterClockwise := False;
  d3dRastDesc.MultisampleEnable     := True;
  d3dRastDesc.ScissorEnable         := False;
  d3dRastDesc.SlopeScaledDepthBias  := 0;

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

  for nIndex := 0 to Length(d3dBlendDesc.RenderTarget) - 1 do
  begin
    d3dBlendDesc.RenderTarget[nIndex].BlendEnable           := True;
    d3dBlendDesc.RenderTarget[nIndex].SrcBlend              := D3D11_BLEND_SRC_ALPHA;
    d3dBlendDesc.RenderTarget[nIndex].DestBlend             := D3D11_BLEND_INV_SRC_ALPHA;
    d3dBlendDesc.RenderTarget[nIndex].SrcBlendAlpha         := D3D11_BLEND_ONE;
    d3dBlendDesc.RenderTarget[nIndex].DestBlendAlpha        := D3D11_BLEND_ZERO;
    d3dBlendDesc.RenderTarget[nIndex].BlendOp               := D3D11_BLEND_OP_ADD;
    d3dBlendDesc.RenderTarget[nIndex].BlendOpAlpha          := D3D11_BLEND_OP_ADD;
    d3dBlendDesc.RenderTarget[nIndex].RenderTargetWriteMask := UInt8(D3D11_COLOR_WRITE_ENABLE_ALL);
  end;

  m_f2dRenderer.Device.CreateBlendState(d3dBlendDesc, m_pBlendDesc);

  //////////////////////////////////////////////////////////////////////////////
  ///  Vertex Buffer
  ZeroMemory(@d3dBufferDesc, Sizeof(d3dBufferDesc));

	d3dBufferDesc.Usage          := D3D11_USAGE_DYNAMIC;
	d3dBufferDesc.ByteWidth      := Sizeof(TScreenVertex) * c_nMaxVertices;
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
procedure TF2DCanvas.ChangeSize(a_nWidth : Integer; a_nHeight : Integer);
begin
  m_f2dRenderer.Resize(a_nWidth, a_nHeight);
end;

//==============================================================================
procedure TF2DCanvas.BeginDraw;
var
  nStride : UINT;
  nOffset : UINT;
begin
	m_f2dRenderer.DeviceContext.VSSetShader(m_pVertexShader, nil, 0);
	m_f2dRenderer.DeviceContext.PSSetShader(m_pPixelShader, nil, 0);

	m_f2dRenderer.DeviceContext.OMSetBlendState(m_pBlendDesc, D3DColor4f(0.0, 0.0, 0.0, 0.0), $FFFFFFFF);
	m_f2dRenderer.DeviceContext.VSSetConstantBuffers(0, 1, m_pScreenBuffer);
	m_f2dRenderer.DeviceContext.IASetInputLayout(m_pInputLayout);

	nStride := SizeOf(TScreenVertex);
	nOffset := 0;
	m_f2dRenderer.DeviceContext.IASetVertexBuffers(0, 1, &m_pVertexBuffer, @nStride, @nOffset);
end;

//==============================================================================
procedure TF2DCanvas.EndDraw;
var
  d3dMappedRes : TD3D11_Mapped_Subresource;
  nIndex       : Integer;
  nPos         : Integer;
begin
  m_f2dRenderer.DeviceContext.Map(m_pVertexBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, d3dMappedRes);
  CopyMemory(d3dMappedRes.pData, @m_arrVertices[0], SizeOf(TScreenVertex) * Length(m_arrVertices));
  m_f2dRenderer.DeviceContext.Unmap(m_pVertexBuffer, 0);

  nPos := 0;

  for nIndex := 0 to m_lstRender.Count - 1 do
  begin
    m_f2dRenderer.DeviceContext.IASetPrimitiveTopology(m_lstRender.Items[nIndex].Topology);
    m_f2dRenderer.DeviceContext.Draw(m_lstRender.Items[nIndex].Count, nPos);
    nPos := nPos + m_lstRender.Items[nIndex].Count;
  end;

  m_f2dRenderer.Paint;
  SetLength(m_arrVertices, 0);
  m_lstRender.Clear;
end;

//==============================================================================
procedure TF2DCanvas.Clear(a_clColor : TAlphaColor);
begin
  m_f2dRenderer.Clear(D3DColor4fARGB(a_clColor));
end;

//==============================================================================
procedure TF2DCanvas.DrawLine(a_pntA : TPointF; a_pntB : TPointF; a_nWidth : Single = -1);
var
  nIndex       : Integer;
  dSin         : Double;
  dCos         : Double;
  dAngle       : Double;
  nVertexCount : Integer;
  RenderItem   : TRenderQueueItem;
const
  c_nVerticesNum = 4;
begin
  GetWidth(a_nWidth);

  nVertexCount := Length(m_arrVertices);
  SetLength(m_arrVertices, nVertexCount + c_nVerticesNum);

  dAngle := ArcTan2(a_pntB.Y - a_pntA.Y, a_pntB.X - a_pntA.X);
  dSin   := Sin(dAngle);
  dCos   := Cos(dAngle);

  m_arrVertices[nVertexCount + 0].pos[0] := a_pntA.X + (a_nWidth / 2) * dSin;
  m_arrVertices[nVertexCount + 0].pos[1] := a_pntA.Y - (a_nWidth / 2) * dCos;
  m_arrVertices[nVertexCount + 0].pos[2] := 0;

  m_arrVertices[nVertexCount + 1].pos[0] := a_pntB.X + (a_nWidth / 2) * dSin;
  m_arrVertices[nVertexCount + 1].pos[1] := a_pntB.Y - (a_nWidth / 2) * dCos;
  m_arrVertices[nVertexCount + 1].pos[2] := 0;

  m_arrVertices[nVertexCount + 2].pos[0] := a_pntA.X - (a_nWidth / 2) * dSin;
  m_arrVertices[nVertexCount + 2].pos[1] := a_pntA.Y + (a_nWidth / 2) * dCos;
  m_arrVertices[nVertexCount + 2].pos[2] := 0;

  m_arrVertices[nVertexCount + 3].pos[0] := a_pntB.X - (a_nWidth / 2) * dSin;
  m_arrVertices[nVertexCount + 3].pos[1] := a_pntB.Y + (a_nWidth / 2) * dCos;
  m_arrVertices[nVertexCount + 3].pos[2] := 0;

  for nIndex := 0 to c_nVerticesNum - 1 do
    m_arrVertices[nVertexCount + nIndex].AssignColor(m_clDraw);

  RenderItem.Count    := c_nVerticesNum;
  RenderItem.Topology := D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP;
  m_lstRender.Add(RenderItem);

  if m_lcLineCap = lcRound then
  begin
    dAngle := dAngle / (2 * Pi);
    DrawArc(a_pntA, a_nWidth/2, a_nWidth/2, 0.5 - dAngle, 0.5, a_nWidth);
    DrawArc(a_pntB, a_nWidth/2, a_nWidth/2, -dAngle, 0.5, a_nWidth);
  end;
end;

//==============================================================================
procedure TF2DCanvas.DrawRect(a_pntA : TPointF; a_pntB : TPointF; a_nWidth : Single = -1);
var
  nIndex       : Integer;
  nVertexCount : Integer;
  RenderItem   : TRenderQueueItem;
const
  c_nVerticesNum = 4;
begin
  GetWidth(a_nWidth);

  nVertexCount := Length(m_arrVertices);
  SetLength(m_arrVertices, nVertexCount + c_nVerticesNum);

  m_arrVertices[nVertexCount + 0].pos[0] := a_pntB.X;
  m_arrVertices[nVertexCount + 0].pos[1] := a_pntA.Y;
  m_arrVertices[nVertexCount + 0].pos[2] := 0;

  m_arrVertices[nVertexCount + 1].pos[0] := a_pntB.X;
  m_arrVertices[nVertexCount + 1].pos[1] := a_pntB.Y;
  m_arrVertices[nVertexCount + 1].pos[2] := 0;

  m_arrVertices[nVertexCount + 2].pos[0] := a_pntA.X;
  m_arrVertices[nVertexCount + 2].pos[1] := a_pntA.Y;
  m_arrVertices[nVertexCount + 2].pos[2] := 0;

  m_arrVertices[nVertexCount + 3].pos[0] := a_pntA.X;
  m_arrVertices[nVertexCount + 3].pos[1] := a_pntB.Y;
  m_arrVertices[nVertexCount + 3].pos[2] := 0;

  for nIndex := 0 to c_nVerticesNum - 1 do
    m_arrVertices[nVertexCount + nIndex].AssignColor(m_clDraw);

  RenderItem.Count    := c_nVerticesNum;
  RenderItem.Topology := D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP;

  m_lstRender.Add(RenderItem);
end;

//==============================================================================
procedure TF2DCanvas.DrawArc(a_pntCenter : TPointF; a_nRadiusX : Double; a_nRadiusY : Double; a_dStartAngle : Single; a_dSizeRatio : Double; a_nWidth : Single = -1);
var
  nIndex        : Integer;
  nVertexCount  : Integer;
  RenderItem    : TRenderQueueItem;
  dAngle        : Double;
const
  c_nVerticesNum = 1024;
begin
  GetWidth(a_nWidth);

  nVertexCount := Length(m_arrVertices);
  SetLength(m_arrVertices, nVertexCount + c_nVerticesNum);

  for nIndex := 0 to (c_nVerticesNum div 2) - 1 do
  begin
    dAngle := a_dSizeRatio * (nIndex / ((c_nVerticesNum div 2) - 1)) + a_dStartAngle;

    m_arrVertices[nVertexCount + 2 * nIndex].pos[0] := a_pntCenter.X + Sin(dAngle * 2 * Pi) * a_nRadiusX;
    m_arrVertices[nVertexCount + 2 * nIndex].pos[1] := a_pntCenter.Y + Cos(dAngle * 2 * Pi) * a_nRadiusY;
    m_arrVertices[nVertexCount + 2 * nIndex].pos[2] := 0;

    m_arrVertices[nVertexCount + 2 * nIndex + 1].pos[0] := a_pntCenter.X;
    m_arrVertices[nVertexCount + 2 * nIndex + 1].pos[1] := a_pntCenter.Y;
    m_arrVertices[nVertexCount + 2 * nIndex + 1].pos[2] := 0;
  end;

  for nIndex := 0 to c_nVerticesNum - 1 do
    m_arrVertices[nVertexCount + nIndex].AssignColor(m_clDraw);

  RenderItem.Count    := c_nVerticesNum;
  RenderItem.Topology := D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP;

  m_lstRender.Add(RenderItem);
end;

//==============================================================================
procedure TF2DCanvas.GetWidth(var a_sWidth : Single);
begin
  if a_sWidth < 0 then
    a_sWidth := m_sLineWidth;
end;

//==============================================================================
end.
