unit D3DCanvasU;

interface

uses

  Windows,
  Winapi.DXTypes,
  SysUtils,
  Math,
  Direct3D,
  D3D11,
  DXGI,
  D3DCommon,
  D3DX10,
  D3D10,
  DxgiFormat,
  DxgiType;


type
  TD3DCanvasProperties = record
    Hwnd        : HWND;
    Width       : Integer;
    Height      : Integer;
    MSAA        : Integer;
  end;

  TD3DVertexA = record
    x, y: Single;
    color: TFourSingleArray;
  end;

  PD3DVertexA = ^TD3DVertexA;

  TD3DCanvas = class
  private
    m_cpProp : TD3DCanvasProperties;
  
    m_Device: ID3D11Device;
    m_DeviceContext: ID3D11DeviceContext;
    m_CurrentFeatureLevel: TD3D_FEATURE_LEVEL;
    m_Swapchain: IDXGISwapChain;
    m_RenderTargetView: ID3D11RenderTargetView;

    m_Viewport: TD3D11_VIEWPORT;
  
    m_bInitialized : Boolean;

    procedure Init;
    procedure Reset;

  public
    constructor Create(a_cpProp : TD3DCanvasProperties);
    destructor Destroy; override;

    procedure Clear(a_clColor: TFourSingleArray);
    procedure Paint;

    property Device        : ID3D11Device        read m_Device        write m_Device;
    property DeviceContext : ID3D11DeviceContext read m_DeviceContext write m_DeviceContext;

  end;

  function D3DColor4f(a_dRed, a_dGreen, a_dBlue, a_dAlpha: Single): TFourSingleArray; inline;
  function D3DColor4fARGB(a_ARGB: Cardinal): TFourSingleArray; inline;

implementation

//==============================================================================
function D3DColor4f(a_dRed, a_dGreen, a_dBlue, a_dAlpha: Single): TFourSingleArray;
begin
  Result[0] := a_dRed;
  Result[1] := a_dGreen;
  Result[2] := a_dBlue;
  Result[3] := a_dAlpha;
end;

//==============================================================================
function D3DColor4fARGB(a_ARGB: Cardinal): TFourSingleArray;
begin
  Result[0] := Byte(a_ARGB shr 16) / 255;
  Result[1] := Byte(a_ARGB shr 8) / 255;
  Result[2] := Byte(a_ARGB) / 255;
  Result[3] := Byte(a_ARGB shr 24) / 255;
end;

//==============================================================================
constructor TD3DCanvas.Create(a_cpProp : TD3DCanvasProperties);
begin
  m_cpProp.Hwnd   := a_cpProp.Hwnd;
  m_cpProp.Width  := a_cpProp.Width;
  m_cpProp.Height := a_cpProp.Height;
  m_cpProp.MSAA   := a_cpProp.MSAA;

  m_bInitialized  := False;

  Init;
end;

//==============================================================================
destructor TD3DCanvas.Destroy;
begin
  Reset;
  Inherited;
end;

//==============================================================================
procedure TD3DCanvas.Clear(a_clColor: TFourSingleArray);
begin
  m_DeviceContext.ClearRenderTargetView(m_RenderTargetView, a_clColor);
end;

//==============================================================================
procedure TD3DCanvas.Paint;
begin
  m_Swapchain.Present(0, 0);
end;

//==============================================================================
procedure TD3DCanvas.Reset;
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
procedure TD3DCanvas.Init;
var
  arrFeatureLevel : Array[0..0] of TD3D_FEATURE_LEVEL;
  Backbuffer      : ID3D11Texture2D;
  SwapchainDesc   : DXGI_SWAP_CHAIN_DESC;
begin
  if m_bInitialized then
    Reset;

  {$HINTS off}
  FillChar(SwapchainDesc, SizeOf(DXGI_SWAP_CHAIN_DESC), 0);
  {$HINTS on}
  with SwapchainDesc do
  begin
    BufferCount := 1;

    BufferDesc.Width := m_cpProp.Width;
    BufferDesc.Height := m_cpProp.Height;
    BufferDesc.Format := DXGI_FORMAT_R8G8B8A8_UNORM;
    BufferDesc.RefreshRate.Numerator := 0;
    BufferDesc.RefreshRate.Denominator := 1;
    BufferDesc.ScanlineOrdering := DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED;
    BufferDesc.Scaling := DXGI_MODE_SCALING_STRETCHED;

    BufferUsage := DXGI_USAGE_RENDER_TARGET_OUTPUT;
    OutputWindow := m_cpProp.HWND;
    SampleDesc.Count := m_cpProp.MSAA;
    SampleDesc.Quality := D3D11_STANDARD_MULTISAMPLE_PATTERN;
    Windowed := True;

    SwapEffect := DXGI_SWAP_EFFECT_DISCARD;
    Flags := 0;
  end;

  arrFeatureLevel[0] := D3D_FEATURE_LEVEL_11_0;

  try
    D3D11CreateDeviceAndSwapChain(
      nil,
      D3D_DRIVER_TYPE_HARDWARE,
      0,
      0,
      @arrFeatureLevel[0],
      1,
      D3D11_SDK_VERSION,
      @SwapchainDesc,
      m_Swapchain,
      m_Device,
      m_CurrentFeatureLevel,
      m_DeviceContext);

    m_Swapchain.GetBuffer(0, ID3D11Texture2D, Backbuffer);
    m_Device.CreateRenderTargetView(Backbuffer, nil, m_RenderTargetView);

    Backbuffer := nil;

    {$HINTS off}
    FillChar(m_Viewport, SizeOf(m_Viewport), 0);
    {$HINTS on}
    with m_Viewport do 
    begin
      Width := m_cpProp.Width;
      Height := m_cpProp.Height;
      MinDepth := 0;
      MaxDepth := 1;
      TopLeftX := 0;
      TopLeftY := 0;
    end;

    m_DeviceContext.RSSetViewports(1, @m_Viewport);

  finally
    m_bInitialized := True;
  end;
end;


//==============================================================================
end.
