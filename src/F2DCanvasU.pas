unit F2DCanvasU;

interface

uses

  Windows,
  DXTypes,
  SysUtils,
  UITypes,
  Types,
  Math,
  Direct3D,
  D3D11,
  DXGI,
  D3DCommon,
  D3DX10,
  D3D10,
  DxgiFormat,
  DxgiType,
  D3DCompiler,
  F2DRendererU,
  F2DMathU,
  F2DTypesU;

type
  TF2DCanvas = class
  private
    m_f2dRenderer : TF2DRenderer;

    m_pVertexShader : ID3D11VertexShader;
    m_pPixelShader  : ID3D11PixelShader;
    m_pInputLayout  : ID3D11InputLayout;
    m_pVertexBuffer : ID3D11Buffer;
    m_pScreenBuffer : ID3D11Buffer;

    m_pBlendDesc : ID3D11BlendState;

    m_matProj : TXMMATRIX;

  public
    constructor Create(a_cpProp : TF2DCanvasProperties); reintroduce;
    destructor Destroy; Override;


    procedure InitRenderer;

    procedure BeginDraw;
    procedure EndDraw;

    ////////////////////////////////////////////////////////////////////////////
    ///  Drawing functions:
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
  RASTERIZER_DESC: TD3D11_Rasterizer_Desc;
  ppRasterizerState: ID3D11RasterizerState;

  pVSBuffer : ID3DBlob;
  pPSBuffer : ID3DBlob;
  d3dLinkage : ID3D11ClassLinkage;
  shaderInputLayout : array[0..1] of TD3D11_Input_Element_Desc;

  bufferDesc : TD3D11_Buffer_Desc;
  viewport : D3D11_VIEWPORT;
  numViewports : UINT;
  mappedResource : D3D11_MAPPED_SUBRESOURCE;


  blendDesc: TD3D11_Blend_Desc;
  resourceData : TD3D11_SUBRESOURCE_DATA;
const
  c_numLayoutElements = 2;
begin
  RASTERIZER_DESC := TD3D11_Rasterizer_Desc.Create(True);
  RASTERIZER_DESC.CullMode := D3D11_CULL_NONE;
  m_f2dRenderer.Device.CreateRasterizerState(D3D11_RASTERIZER_DESC(RASTERIZER_DESC), ppRasterizerState);
  m_f2dRenderer.DeviceContext.RSSetState(ppRasterizerState);


  m_f2dRenderer.CompileShader('ScreenCoordinates.fx', 'VS_Main', 'vs_4_0', pVSBuffer);
  m_f2dRenderer.CompileShader('ScreenCoordinates.fx', 'PS_Main', 'ps_4_0', pPSBuffer);

  m_f2dRenderer.Device.CreateVertexShader(pVSBuffer.GetBufferPointer, pVSBuffer.GetBufferSize, d3dLinkage, @m_pVertexShader);
  m_f2dRenderer.Device.CreatePixelShader(pPSBuffer.GetBufferPointer, pPSBuffer.GetBufferSize, d3dLinkage, m_pPixelShader);

  shaderInputLayout[0].SemanticName := 'POSITION';
  shaderInputLayout[0].SemanticIndex := 0;
  shaderInputLayout[0].Format := DXGI_FORMAT_R32G32B32_FLOAT;
  shaderInputLayout[0].InputSlot := 0;
  shaderInputLayout[0].AlignedByteOffset := 0;
  shaderInputLayout[0].InputSlotClass := D3D11_INPUT_PER_VERTEX_DATA;
  shaderInputLayout[0].InstanceDataStepRate := 0;

  shaderInputLayout[1].SemanticName := 'COLOR';
  shaderInputLayout[1].SemanticIndex := 0;
  shaderInputLayout[1].Format := DXGI_FORMAT_R32G32B32A32_FLOAT;
  shaderInputLayout[1].InputSlot := 0;
  shaderInputLayout[1].AlignedByteOffset := 16;
  shaderInputLayout[1].InputSlotClass := D3D11_INPUT_PER_VERTEX_DATA;
  shaderInputLayout[1].InstanceDataStepRate := 0;

  m_f2dRenderer.Device.CreateInputLayout(@shaderInputLayout, c_numLayoutElements, pVSBuffer.GetBufferPointer, pVSBuffer.GetBufferSize, m_pInputLayout);

  pVSBuffer := nil;
  pPSBuffer := nil;

  //////////////////////////////////////////////////////////////////////////////
  ///  Blend
  blendDesc := TD3D11_Blend_Desc.Create(True);

  blendDesc.RenderTarget[0].BlendEnable := True;
	blendDesc.RenderTarget[0].SrcBlend := D3D11_BLEND_SRC_ALPHA;
	blendDesc.RenderTarget[0].DestBlend := D3D11_BLEND_INV_SRC_ALPHA;
	blendDesc.RenderTarget[0].SrcBlendAlpha := D3D11_BLEND_ONE;
	blendDesc.RenderTarget[0].DestBlendAlpha := D3D11_BLEND_ZERO;
	blendDesc.RenderTarget[0].BlendOp := D3D11_BLEND_OP_ADD;
	blendDesc.RenderTarget[0].BlendOpAlpha := D3D11_BLEND_OP_ADD;
	blendDesc.RenderTarget[0].RenderTargetWriteMask := UINT8(D3D11_COLOR_WRITE_ENABLE_ALL);

  m_f2dRenderer.Device.CreateBlendState(blendDesc, m_pBlendDesc);

  //////////////////////////////////////////////////////////////////////////////
  ///  Vertex Buffer
  ZeroMemory(@bufferDesc, Sizeof(bufferDesc));

	bufferDesc.Usage := D3D11_USAGE_DYNAMIC;
	bufferDesc.ByteWidth := Sizeof(TScreenVertex) * 3;
	bufferDesc.BindFlags := D3D11_BIND_VERTEX_BUFFER;
	bufferDesc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE;
	bufferDesc.MiscFlags := 0;

  m_f2dRenderer.Device.CreateBuffer(bufferDesc, nil, m_pVertexBuffer);

  //////////////////////////////////////////////////////////////////////////////
  ///  Screen Buffer
  ZeroMemory(@bufferDesc, Sizeof(bufferDesc));

	bufferDesc.Usage := D3D11_USAGE_DYNAMIC;
	bufferDesc.ByteWidth := Sizeof(TXMMATRIX);
	bufferDesc.BindFlags := D3D11_BIND_CONSTANT_BUFFER;
	bufferDesc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE;
	bufferDesc.MiscFlags := 0;

  m_f2dRenderer.Device.CreateBuffer(bufferDesc, nil, m_pScreenBuffer);

  //////////////////////////////////////////////////////////////////////////////
  ///  View Port
 	numViewports := 1;

	m_f2dRenderer.DeviceContext.RSGetViewports(numViewports, @viewport);

	m_matProj := XMMatrixOrthographicOffCenterLH(viewport.TopLeftX, viewport.Width, viewport.Height, viewport.TopLeftY,
		viewport.MinDepth, viewport.MaxDepth);

  m_f2dRenderer.DeviceContext.Map(m_pScreenBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, mappedResource);
  CopyMemory(mappedResource.pData, @m_matProj, SizeOf(TXMMATRIX));
  m_f2dRenderer.DeviceContext.Unmap(m_pScreenBuffer, 0);
end;

//==============================================================================
procedure TF2DCanvas.BeginDraw;
var
  stride, offset : UINT;
begin
	m_f2dRenderer.DeviceContext.VSSetShader(m_pVertexShader, nil, 0);
	m_f2dRenderer.DeviceContext.PSSetShader(m_pPixelShader, nil, 0);

	m_f2dRenderer.DeviceContext.OMSetBlendState(m_pBlendDesc, D3DColor4f(1.0, 1.0, 1.0, 1.0), $ffffffff);

	m_f2dRenderer.DeviceContext.VSSetConstantBuffers(0, 1, m_pScreenBuffer);

	m_f2dRenderer.DeviceContext.IASetInputLayout(m_pInputLayout);

	stride := SizeOf(TScreenVertex);
	offset := 0;
	m_f2dRenderer.DeviceContext.IASetVertexBuffers(0, 1, &m_pVertexBuffer, @stride, @offset);

  m_f2dRenderer.Clear(D3DColor4f(0.0, 0.0, 0.0, 1.0));

	//fontWrapper->DrawString(m_f2dRenderer.DeviceContext, L"", 0.0f, 0.0f, 0.0f, 0xff000000, FW1_RESTORESTATE | FW1_NOFLUSH);
end;

//==============================================================================
procedure TF2DCanvas.EndDraw;
begin
  //
end;

//==============================================================================
procedure TF2DCanvas.DrawLine(a_pntA : TPointF; a_pntB : TPointF; a_clColor : TAlphaColor; a_nWidth : Single);
var
  mappedResource : D3D11_MAPPED_SUBRESOURCE;
  arrVertices : array[0..1] of TScreenVertex;
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

  m_f2dRenderer.DeviceContext.Map(m_pVertexBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, mappedResource);
  CopyMemory(mappedResource.pData, @arrVertices[0], SizeOf(arrVertices));
  m_f2dRenderer.DeviceContext.Unmap(m_pVertexBuffer, 0);

  m_f2dRenderer.DeviceContext.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_LINELIST);
  m_f2dRenderer.DeviceContext.Draw(3, 0);
  m_f2dRenderer.Paint;
end;

//==============================================================================
end.
