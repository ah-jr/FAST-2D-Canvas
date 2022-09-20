unit F2DTypesU;

interface

uses
  Winapi.Windows,
  System.Generics.Collections,
  System.UITypes,
  System.Types,
  D3D11;

type
  TF2DPath = class
    public
      Points : TList<TPointF>;

      constructor Create;
      destructor  Destroy; override;

      procedure AddPoint(a_pntNew : TPointF); overload;
      procedure AddPoint(a_dX, a_dY : Double); overload;
      procedure RemovePoint(a_pntDel : TPointF);
      procedure Scale(a_dX, a_dY : Double);
      procedure Offset(a_dX, a_dY : Double);
  end;

  TF2DCanvasProperties = record
    Hwnd        : HWND;
    Width       : Integer;
    Height      : Integer;
    MSAA        : Integer;
  end;

  T3DSingleArray = array [0..2] of Single;
  T4DSingleArray = array [0..3] of Single;

  TScreenVertex = record
    pos   : T4DSingleArray;
    color : T4DSingleArray;
    procedure AssignColor(a_clColor : TAlphaColor);
  end;
  PScreenVertex = ^TScreenVertex;

  TRenderQueueItem = record
    Count : Integer;
    Topology : D3D11_PRIMITIVE_TOPOLOGY;
  end;

  TF2DLineCap = (lcRound, lcMitter);

const
  //////////////////////////////////////////////////////////////////////////////
  ///  Constants:
  c_nMaxVertices = 1000000;

  //////////////////////////////////////////////////////////////////////////////
  ///  Colors:
  c_clBlack = $FF000000;


implementation

//==============================================================================
procedure TScreenVertex.AssignColor(a_clColor : TAlphaColor);
begin
  color[0] := ((a_clColor and $00FF0000) shr (2 * 8)) / 255;
  color[1] := ((a_clColor and $0000FF00) shr (1 * 8)) / 255;
  color[2] := ((a_clColor and $000000FF) shr (0 * 8)) / 255;
  color[3] := ((a_clColor and $FF000000) shr (3 * 8)) / 255;
end;

//==============================================================================
constructor TF2DPath.Create;
begin
  Points := TList<TPointF>.Create;
end;

//==============================================================================
destructor  TF2DPath.Destroy;
begin
  Points.Free;
end;

//==============================================================================
procedure TF2DPath.AddPoint(a_pntNew : TPointF);
begin
  Points.Add(a_pntNew);
end;

//==============================================================================
procedure TF2DPath.AddPoint(a_dX, a_dY : Double);
begin
  Points.Add(PointF(a_dX, a_dY));
end;


//==============================================================================
procedure TF2DPath.RemovePoint(a_pntDel : TPointF);
begin
  Points.Remove(a_pntDel);
end;

//==============================================================================
procedure TF2DPath.Scale(a_dX, a_dY : Double);
var
  nIndex : Integer;
  pntNew : TPointF;
begin
  for nIndex := 0 to Points.Count - 1 do
  begin
    pntNew.X := Points.Items[nIndex].X * a_dX;
    pntNew.Y := Points.Items[nIndex].Y * a_dY;

    Points.Items[nIndex] := pntNew;
  end;
end;

//==============================================================================
procedure TF2DPath.Offset(a_dX, a_dY : Double);
var
  nIndex : Integer;
  pntNew : TPointF;
begin
  for nIndex := 0 to Points.Count - 1 do
  begin
    pntNew.X := Points.Items[nIndex].X + a_dX;
    pntNew.Y := Points.Items[nIndex].Y + a_dY;

    Points.Items[nIndex] := pntNew;
  end;
end;

//==============================================================================
end.
