unit F2DRendererU;

interface

uses

  Windows,
  DXTypes,
  SysUtils,
  Math,
  D3D11,
  DXGI,
  D3DCommon,
  DxgiFormat,
  DxgiType,
  F2DTypesU,
  D3DCompiler;

type
  TF2DRenderer = class
  private
    m_cpProp              : TF2DCanvasProperties;

    m_Device              : ID3D11Device;
    m_DeviceContext       : ID3D11DeviceContext;
    m_CurrentFeatureLevel : TD3D_Feature_Level;
    m_Swapchain           : IDXGISwapChain;
    m_RenderTargetView    : ID3D11RenderTargetView;
    m_Viewport            : TD3D11_VIEWPORT;

    m_bInitialized        : Boolean;

    procedure Init;
    procedure Reset;

  public
    constructor Create(a_cpProp : TF2DCanvasProperties);
    destructor Destroy; override;

    procedure CompileShader(szFilePath : LPCWSTR; szFunc : LPCSTR; szShaderModel : LPCSTR; out pBuffer : ID3DBlob);

    procedure Resize(a_nWidth : Integer; a_nHeight : Integer);
    procedure Clear(a_clColor: TFourSingleArray);
    procedure Paint;

    property Device           : ID3D11Device           read m_Device               write m_Device;
    property DeviceContext    : ID3D11DeviceContext    read m_DeviceContext        write m_DeviceContext;
    property SwapChain        : IDXGISwapChain         read m_Swapchain            write m_Swapchain;
    property RenderTargetView : ID3D11RenderTargetView read m_RenderTargetView     write m_RenderTargetView;

  end;

implementation

//==============================================================================
constructor TF2DRenderer.Create(a_cpProp : TF2DCanvasProperties);
begin
  m_cpProp.Hwnd   := a_cpProp.Hwnd;
  m_cpProp.Width  := a_cpProp.Width;
  m_cpProp.Height := a_cpProp.Height;
  m_cpProp.MSAA   := a_cpProp.MSAA;
  m_cpProp.Debug  := a_cpProp.Debug;

  m_bInitialized  := False;

  Init;
end;

//==============================================================================
destructor TF2DRenderer.Destroy;
begin
  Reset;
  Inherited;
end;

//==============================================================================
procedure TF2DRenderer.Resize(a_nWidth : Integer; a_nHeight : Integer);
var
  pBackbuffer : ID3D11Texture2D;
  nFlags      : Cardinal;
begin
  m_RenderTargetView := nil;

  try
    nFlags := 0;

    if m_cpProp.Debug then
      nFlags := Cardinal(D3D11_CREATE_DEVICE_DEBUG);

    m_SwapChain.ResizeBuffers(1, a_nWidth, a_nHeight, DXGI_FORMAT_R8G8B8A8_UNORM, nFlags);

    m_Swapchain.GetBuffer(0, ID3D11Texture2D, pBackbuffer);
    m_Device.CreateRenderTargetView(pBackbuffer, nil, m_RenderTargetView);
    m_DeviceContext.OMSetRenderTargets(1, m_RenderTargetView, nil);

    FillChar(m_Viewport, SizeOf(m_Viewport), 0);
    with m_Viewport do
    begin
      Width    := a_nWidth;
      Height   := a_nHeight;
      MinDepth := 0;
      MaxDepth := 1;
      TopLeftX := 0;
      TopLeftY := 0;
    end;

    m_DeviceContext.RSSetViewports(1, @m_Viewport);
  finally
    pBackbuffer := nil;
  end;
end;

//==============================================================================
procedure TF2DRenderer.Clear(a_clColor: TFourSingleArray);
begin
  m_DeviceContext.ClearRenderTargetView(m_RenderTargetView, a_clColor);
end;

//==============================================================================
procedure TF2DRenderer.Paint;
begin
  m_Swapchain.Present(0, 0);
end;

//==============================================================================
procedure TF2DRenderer.Reset;
begin
  if not m_bInitialized then
    Exit;

  m_DeviceContext    := nil;
  m_Device           := nil;
  m_RenderTargetView := nil;
  m_Swapchain        := nil;

  m_bInitialized     := False;
end;

//==============================================================================
procedure TF2DRenderer.Init;
var
  arrFeatureLevel   : Array[0..2] of TD3D_Feature_Level;
  pBackbuffer       : ID3D11Texture2D;
  dxgiSwapchainDesc : DXGI_SWAP_CHAIN_DESC;
  nFlags            : Cardinal;
begin
  if m_bInitialized then
    Reset;

  try
    FillChar(dxgiSwapchainDesc, SizeOf(DXGI_SWAP_CHAIN_DESC), 0);
    with dxgiSwapchainDesc do
    begin
      BufferDesc.Width                   := m_cpProp.Width;
      BufferDesc.Height                  := m_cpProp.Height;
      BufferDesc.Format                  := DXGI_FORMAT_R8G8B8A8_UNORM;
      BufferDesc.RefreshRate.Numerator   := 0;
      BufferDesc.RefreshRate.Denominator := 1;
      BufferDesc.ScanlineOrdering        := DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED;
      BufferDesc.Scaling                 := DXGI_MODE_SCALING_STRETCHED;

      BufferCount                        := 1;
      BufferUsage                        := DXGI_USAGE_RENDER_TARGET_OUTPUT;
      OutputWindow                       := m_cpProp.HWND;
      SampleDesc.Count                   := m_cpProp.MSAA;
      SampleDesc.Quality                 := Cardinal(D3D11_STANDARD_MULTISAMPLE_PATTERN);
      Windowed                           := True;
      SwapEffect                         := DXGI_SWAP_EFFECT_DISCARD;
      Flags                              := 0;
    end;

    FillChar(m_Viewport, SizeOf(m_Viewport), 0);
    with m_Viewport do
    begin
      Width    := m_cpProp.Width;
      Height   := m_cpProp.Height;
      MinDepth := 0;
      MaxDepth := 1;
      TopLeftX := 0;
      TopLeftY := 0;
    end;

    arrFeatureLevel[0] :=  D3D_FEATURE_LEVEL_11_0;
    arrFeatureLevel[1] :=  D3D_FEATURE_LEVEL_10_1;
    arrFeatureLevel[2] :=  D3D_FEATURE_LEVEL_10_0;

    nFlags := 0;

    if m_cpProp.Debug then
      nFlags := Cardinal(D3D11_CREATE_DEVICE_DEBUG);

    D3D11CreateDeviceAndSwapChain(
      nil,
      D3D_DRIVER_TYPE_HARDWARE,
      0,
      nFlags,
      @arrFeatureLevel,
      3,
      D3D11_SDK_VERSION,
      @dxgiSwapchainDesc,
      m_Swapchain,
      m_Device,
      m_CurrentFeatureLevel,
      m_DeviceContext);

    m_Swapchain.GetBuffer(0, ID3D11Texture2D, pBackbuffer);
    m_Device.CreateRenderTargetView(pBackbuffer, nil, m_RenderTargetView);
    m_DeviceContext.OMSetRenderTargets(1, m_RenderTargetView, nil);
    m_DeviceContext.RSSetViewports(1, @m_Viewport);
  finally
    pBackbuffer := nil;
    m_bInitialized := True;
  end;
end;

//==============================================================================
procedure TF2DRenderer.CompileShader(szFilePath : LPCWSTR; szFunc : LPCSTR; szShaderModel : LPCSTR; out pBuffer : ID3DBlob);
var
  wFlags     : DWORD;
  pErrBuffer : ID3DBlob;
begin
  wFlags := D3DCOMPILE_ENABLE_STRICTNESS;

  if m_cpProp.Debug then
    wFlags := wFlags or D3DCOMPILE_DEBUG;

  D3DCompileFromFile(szFilePath, nil, nil, szFunc, szShaderModel, wFlags, 0, pBuffer, Pointer(pErrBuffer));

  pErrBuffer := nil;
end;

//==============================================================================
end.
