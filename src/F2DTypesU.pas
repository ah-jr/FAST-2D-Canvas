unit F2DTypesU;

interface

uses
  Winapi.Windows,
  System.Generics.Collections,
  System.UITypes,
  System.Types,
  D3D11;

type
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
  TVertexArray  = array of TScreenVertex;

  TRenderQueueItem = record
    Count : Integer;
    Topology : D3D11_PRIMITIVE_TOPOLOGY;
  end;

  TF2DLineCap = (lcRound, lcMitter);

  TF2DPath = class
    private
      m_arrVertices : TVertexArray;
      m_lstPoints   : TList<TPointF>;
      m_bCompiled   : Boolean;

    public
      constructor Create;
      destructor  Destroy; override;

      procedure AddPoint(a_pntNew : TPointF); overload;
      procedure AddPoint(a_dX, a_dY : Double); overload;
      procedure RemovePoint(a_pntDel : TPointF); overload;
      procedure RemovePoint(a_dX, a_dY : Double); overload;
      procedure Scale (a_dX, a_dY : Double);
      procedure Offset(a_dX, a_dY : Double);
      procedure Rotate(a_pntRef : TPointF; a_dRatio : Double);
      procedure FlipX;
      procedure FlipY;

      procedure Compile;

      property Points   : TList<TPointF> read m_lstPoints;
      property Compiled : Boolean        read m_bCompiled;
      property Vertices : TVertexArray   read m_arrVertices;
  end;

const
  //////////////////////////////////////////////////////////////////////////////
  ///  Constants:
  c_nMaxVertices = 1000000;

  //////////////////////////////////////////////////////////////////////////////
  ///  Colors:
  c_clBlack = $FF000000;


implementation
uses
  Math,
  F2DMathU;

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
  m_lstPoints := TList<TPointF>.Create;
  m_bCompiled := False;
end;

//==============================================================================
destructor  TF2DPath.Destroy;
begin
  m_lstPoints.Free;
  SetLength(m_arrVertices, 0);
end;

//==============================================================================
procedure TF2DPath.AddPoint(a_pntNew : TPointF);
begin
  m_lstPoints.Add(a_pntNew);
  m_bCompiled := False;
end;

//==============================================================================
procedure TF2DPath.AddPoint(a_dX, a_dY : Double);
begin
  m_lstPoints.Add(PointF(a_dX, a_dY));
  m_bCompiled := False;
end;

//==============================================================================
procedure TF2DPath.RemovePoint(a_pntDel : TPointF);
begin
  m_lstPoints.Remove(a_pntDel);
  m_bCompiled := False;
end;

//==============================================================================
procedure TF2DPath.RemovePoint(a_dX, a_dY : Double);
begin
  m_lstPoints.Remove(PointF(a_dX, a_dY));
  m_bCompiled := False;
end;

//==============================================================================
procedure TF2DPath.Scale(a_dX, a_dY : Double);
var
  nIndex : Integer;
  pntNew : TPointF;
begin
  m_bCompiled := False;

  for nIndex := 0 to m_lstPoints.Count - 1 do
  begin
    pntNew.X := m_lstPoints.Items[nIndex].X * a_dX;
    pntNew.Y := m_lstPoints.Items[nIndex].Y * a_dY;

    m_lstPoints.Items[nIndex] := pntNew;
  end;
end;

//==============================================================================
procedure TF2DPath.Offset(a_dX, a_dY : Double);
var
  nIndex : Integer;
  pntNew : TPointF;
begin
  m_bCompiled := False;

  for nIndex := 0 to m_lstPoints.Count - 1 do
  begin
    pntNew.X := m_lstPoints.Items[nIndex].X + a_dX;
    pntNew.Y := m_lstPoints.Items[nIndex].Y + a_dY;

    m_lstPoints.Items[nIndex] := pntNew;
  end;
end;

//==============================================================================
procedure TF2DPath.Rotate(a_pntRef : TPointF; a_dRatio : Double);
var
  nIndex : Integer;
  pntAux : TPointF;
  pntNew : TPointF;
  dSin   : Double;
  dCos   : Double;
begin
  dSin := Sin(a_dRatio * 2 * Pi);
  dCos := Cos(a_dRatio * 2 * Pi);

  for nIndex := 0 to m_lstPoints.Count - 1 do
  begin
    pntAux.X := m_lstPoints.Items[nIndex].X;
    pntAux.Y := m_lstPoints.Items[nIndex].Y;

    pntAux.X := pntAux.X - a_pntRef.X;
    pntAux.Y := pntAux.Y - a_pntRef.Y;

    pntNew.X := pntAux.X * dCos - pntAux.Y * dSin + a_pntRef.X;
    pntNew.Y := pntAux.X * dSin + pntAux.Y * dCos + a_pntRef.Y;

    m_lstPoints.Items[nIndex] := pntNew;
  end;
end;

//==============================================================================
procedure TF2DPath.FlipX;
var
  nIndex : Integer;
  pntNew : TPointF;
begin
  for nIndex := 0 to m_lstPoints.Count - 1 do
  begin
    pntNew.X := -m_lstPoints.Items[nIndex].X;
    pntNew.Y := m_lstPoints.Items[nIndex].Y;

    m_lstPoints.Items[nIndex] := pntNew;
  end;
end;

//==============================================================================
procedure TF2DPath.FlipY;
var
  nIndex : Integer;
  pntNew : TPointF;
begin
  for nIndex := 0 to m_lstPoints.Count - 1 do
  begin
    pntNew.X := m_lstPoints.Items[nIndex].X;
    pntNew.Y := -m_lstPoints.Items[nIndex].Y;

    m_lstPoints.Items[nIndex] := pntNew;
  end;
end;

//==============================================================================
procedure TF2DPath.Compile;
var
  a_lstRemaining : TList<TPointF>;
  nPntIdx        : Integer;
  nAuxIdx        : Integer;
  nNextIdx       : Integer;
  nLastIdx       : Integer;
  pntCurr        : TPointF;
  pntNext        : TPointF;
  pntLast        : TPointF;
  bContains      : Boolean;
  nVertexCount   : Integer;
  dAngle         : Double;
const
  c_nVerticesNum = 3;
begin
  if (m_lstPoints.Count < c_nVerticesNum) then
    Exit;

  a_lstRemaining := TList<TPointF>.Create;
  SetLength(m_arrVertices, 0);

  for nPntIdx := 0 to m_lstPoints.Count - 1 do
    a_lstRemaining.Add(m_lstPoints.Items[nPntIdx]);

  nPntIdx   := 0;

  while a_lstRemaining.Count > c_nVerticesNum do
  begin
    if nPntIdx = a_lstRemaining.Count - 1
      then nNextIdx := 0
      else nNextIdx := nPntIdx + 1;

    if nPntIdx = 0
      then nLastIdx := a_lstRemaining.Count - 1
      else nLastIdx := nPntIdx - 1;

    pntCurr := a_lstRemaining.Items[nPntIdx];
    pntLast := a_lstRemaining.Items[nLastIdx];
    pntNext := a_lstRemaining.Items[nNextIdx];
    dAngle  := GetVectorsAngle(pntCurr, pntNext, pntLast);

    if (dAngle > 0) then
    begin
      nAuxIdx := 0;
      bContains := False;

      while (nAuxIdx < a_lstRemaining.Count) and (not bContains) do
      begin
        if not (nAuxIdx in [nPntIdx, nNextIdx, nLastIdx]) then
          bContains := PointInTriangle(a_lstRemaining.Items[nAuxIdx], pntLast, pntCurr, pntNext);

        Inc(nAuxIdx);
      end;

      if not bContains then
      begin
        nVertexCount := Length(m_arrVertices);
        SetLength(m_arrVertices, nVertexCount + c_nVerticesNum);

        m_arrVertices[nVertexCount + 0].pos[0] := pntLast.X;
        m_arrVertices[nVertexCount + 0].pos[1] := pntLast.Y;
        m_arrVertices[nVertexCount + 0].pos[2] := 0;

        m_arrVertices[nVertexCount + 1].pos[0] := pntCurr.X;
        m_arrVertices[nVertexCount + 1].pos[1] := pntCurr.Y;
        m_arrVertices[nVertexCount + 1].pos[2] := 0;

        m_arrVertices[nVertexCount + 2].pos[0] := pntNext.X;
        m_arrVertices[nVertexCount + 2].pos[1] := pntNext.Y;
        m_arrVertices[nVertexCount + 2].pos[2] := 0;

        a_lstRemaining.Remove(pntCurr);
        nPntIdx := -1;
      end
    end;

    Inc(nPntIdx);
  end;

  //////////////////////////////////////////////////////////////////////////////
  ///  Connect last 3 points
  nVertexCount := Length(m_arrVertices);
  SetLength(m_arrVertices, nVertexCount + c_nVerticesNum);

  m_arrVertices[nVertexCount + 0].pos[0] := a_lstRemaining.Items[0].X;
  m_arrVertices[nVertexCount + 0].pos[1] := a_lstRemaining.Items[0].Y;
  m_arrVertices[nVertexCount + 0].pos[2] := 0;

  m_arrVertices[nVertexCount + 1].pos[0] := a_lstRemaining.Items[1].X;
  m_arrVertices[nVertexCount + 1].pos[1] := a_lstRemaining.Items[1].Y;
  m_arrVertices[nVertexCount + 1].pos[2] := 0;

  m_arrVertices[nVertexCount + 2].pos[0] := a_lstRemaining.Items[2].X;
  m_arrVertices[nVertexCount + 2].pos[1] := a_lstRemaining.Items[2].Y;
  m_arrVertices[nVertexCount + 2].pos[2] := 0;

  a_lstRemaining.Free;
  m_bCompiled := True;
end;


//==============================================================================
end.
