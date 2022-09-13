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
  DXGI,
  DxgiFormat,
  DxgiType,
  Direct3D,
  D3DCommon,
  D3D10,
  D3DX10,
  D3D11;

type
  TMainForm = class(TForm)
    pnlD3dCanvas: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure pnlD3dCanvasMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    m_d3dCanvas : TD3DCanvas;



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

  RASTERIZER_DESC := D3D11_RASTERIZER_DESC.Create(True);
  RASTERIZER_DESC.CullMode := D3D11_CULL_NONE;
  m_d3dCanvas.Device.CreateRasterizerState(RASTERIZER_DESC, ppRasterizerState);
  m_d3dCanvas.DeviceContext.RSSetState(ppRasterizerState);
end;

//==============================================================================
procedure TMainForm.FormPaint(Sender: TObject);
begin
  //
end;

//==============================================================================
procedure TMainForm.pnlD3dCanvasMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  BLEND_DESC: D3D11_BLEND_DESC;
  ppBlendState: ID3D11BlendState;
  stride, offset: UINT;
  buffer : ID3D11Buffer;



  Vertexes         : array[0..1] of TD3DVertexA;
  ArrayIndex       : Integer;
  VertexBufferSize : UInt;
  vert_buffer_desc : TD3D11_BUFFER_DESC;
  vert_subresource : TD3D11_SUBRESOURCE_DATA;
  Error : HResult;
begin
  stride := SizeOf(TD3DVertexA);
  offset := 0;
  BLEND_DESC := D3D11_BLEND_DESC.Create(True);

  m_d3dCanvas.Clear(D3DColor4f(0.0, 1.0, 0.0, 1.0));
  m_d3dCanvas.Device.CreateBlendState(BLEND_DESC, ppBlendState);
  m_d3dCanvas.DeviceContext.OMSetBlendState(ppBlendState, D3DColor4f(1.0, 1.0, 1.0, 1.0), $ffffffff);










  Vertexes[0].x := 0;
  Vertexes[0].y := 0;
  Vertexes[0].z := 0;
  Vertexes[0].Color := D3DColor4f(1,0,0,1);

  Vertexes[1].x := 0;
  Vertexes[1].y := 0;
  Vertexes[1].z := 0;
  Vertexes[1].Color :=  D3DColor4f(1,0,0,1);

  VertexBufferSize := Length(Vertexes) * SizeOf(TD3DVertexA);

  with vert_buffer_desc do
  begin
    Usage               := D3D11_USAGE_DEFAULT;
    ByteWidth           := VertexBufferSize;
    BindFlags           := Ord(D3D11_BIND_VERTEX_BUFFER);
    CPUAccessFlags      := 0;
    MiscFlags           := 0;
    StructureByteStride := 0;
  end;

  with vert_subresource do
  begin
    pSysMem          := @Vertexes[0];
    SysMemPitch      := 0;
    SysMemSlicePitch := 0;
  end;

   Error:= m_d3dCanvas.Device.CreateBuffer(vert_buffer_desc, @vert_subresource, buffer);

   If Failed(Error) then
   begin
     Sleep(1);
   end;






//
//  // set matrix
//
  m_d3dCanvas.DeviceContext.IASetVertexBuffers(0, 1, buffer, @stride, @offset);
  m_d3dCanvas.DeviceContext.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_LINELIST);
  m_d3dCanvas.DeviceContext.Draw(2, 0);

  m_d3dCanvas.Paint;
end;

end.
