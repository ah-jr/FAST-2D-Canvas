unit F2DMathU;

interface

uses
  Winapi.Windows,
  Winapi.D3D11,
  System.Types,
  Classes;

type
  TXMVECTOR = record
    constructor Create(x, y, z, w: single);

    case integer of
      0: (f32: array [0..3] of single);
      1: (u32: array [0..3] of uint32);
      2: (i32: array [0..3] of int32);
  end;

  PXMVECTOR = ^TXMVECTOR;
  TXMVECTORArray = array of TXMVECTOR;


  TXMMATRIX = record
    case integer of
      0: (r: array [0..3] of TXMVECTOR);
      1: (_11, _12, _13, _14: single;
          _21, _22, _23, _24: single;
          _31, _32, _33, _34: single;
          _41, _42, _43, _44: single;
      );
      2: (m: array[0..3, 0..3] of single);
      3: (n: array [0..15] of single);
      4: (u: array [0..15] of UINT32);
      5: (r0, r1, r2, r3: TXMVECTOR);
  end;

  function XMMatrixOrthographicOffCenterLH(ViewLeft: single; ViewRight: single; ViewBottom: single; ViewTop: single;
    NearZ: single; FarZ: single): TXMMATRIX;

  function XMScalarNearEqual(S1: single; S2: single; Epsilon: single): boolean;

  function D3DColor4f(a_dRed, a_dGreen, a_dBlue, a_dAlpha: Single): TFourSingleArray; inline;
  function D3DColor4fARGB(a_ARGB: Cardinal): TFourSingleArray; inline;

  function Sign(a_pntA, a_pntB, a_pntC : TPointF) : Double;
  function PointInTriangle(a_pntP, a_pntA, a_pntB, a_pntC : TPointF) : Boolean;
  function GetVectorsAngle(a_pntRef, a_pntA, a_pntB : TPointF) : Double;

implementation

uses
  Math;

//==============================================================================
constructor TXMVECTOR.Create(x, y, z, w: single);
begin
    f32[0] := x;
    f32[1] := y;
    f32[2] := z;
    f32[3] := w;
end;

//==============================================================================
function XMScalarNearEqual(S1: single; S2: single; Epsilon: single): boolean;
var
    Delta: single;
begin
    Delta := S1 - S2;
    Result := (abs(Delta) <= Epsilon);
end;

//==============================================================================
function XMMatrixOrthographicOffCenterLH(ViewLeft: single; ViewRight: single; ViewBottom: single; ViewTop: single; NearZ: single; FarZ: single): TXMMATRIX;
var
    ReciprocalWidth, ReciprocalHeight, fRange: single;
begin
    assert(not XMScalarNearEqual(ViewRight, ViewLeft, 0.00001));
    assert(not XMScalarNearEqual(ViewTop, ViewBottom, 0.00001));
    assert(not XMScalarNearEqual(FarZ, NearZ, 0.00001));

    ReciprocalWidth := 1.0 / (ViewRight - ViewLeft);
    ReciprocalHeight := 1.0 / (ViewTop - ViewBottom);
    fRange := 1.0 / (FarZ - NearZ);


    Result.m[0, 0] := ReciprocalWidth + ReciprocalWidth;
    Result.m[0, 1] := 0.0;
    Result.m[0, 2] := 0.0;
    Result.m[0, 3] := 0.0;

    Result.m[1, 0] := 0.0;
    Result.m[1, 1] := ReciprocalHeight + ReciprocalHeight;
    Result.m[1, 2] := 0.0;
    Result.m[1, 3] := 0.0;

    Result.m[2, 0] := 0.0;
    Result.m[2, 1] := 0.0;
    Result.m[2, 2] := fRange;
    Result.m[2, 3] := 0.0;

    Result.m[3, 0] := -(ViewLeft + ViewRight) * ReciprocalWidth;
    Result.m[3, 1] := -(ViewTop + ViewBottom) * ReciprocalHeight;
    Result.m[3, 2] := -fRange * NearZ;
    Result.m[3, 3] := 1.0;
end;

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
function Sign(a_pntA, a_pntB, a_pntC : TPointF) : Double;
begin
  Result := (a_pntA.x - a_pntC.x) * (a_pntB.y - a_pntC.y) - (a_pntB.x - a_pntC.x) * (a_pntA.y - a_pntC.y);
end;

//==============================================================================
function PointInTriangle(a_pntP, a_pntA, a_pntB, a_pntC : TPointF) : Boolean;
var
  dA : Double;
  dB : Double;
  dC : Double;
  bNeg : Boolean;
  bPos : Boolean;
begin
  dA := Sign(a_pntP, a_pntA, a_pntB);
  dB := Sign(a_pntP, a_pntB, a_pntC);
  dC := Sign(a_pntP, a_pntC, a_pntA);

  bNeg := (dA < 0) or (dB < 0) or (dC < 0);
  bPos := (dA > 0) or (dB > 0) or (dC > 0);

  Result := not(bNeg and bPos);
end;

//==============================================================================
function GetVectorsAngle(a_pntRef, a_pntA, a_pntB : TPointF) : Double;
var
  dDotProd     : Double;
  dDeterminant : Double;
begin
  a_pntA.X := a_pntA.X - a_pntRef.X;
  a_pntA.Y := a_pntA.Y - a_pntRef.Y;
  a_pntB.X := a_pntB.X - a_pntRef.X;
  a_pntB.Y := a_pntB.Y - a_pntRef.Y;

  dDotProd     := a_pntA.X * a_pntB.X + a_pntA.Y * a_pntB.Y;
  dDeterminant := a_pntA.X * a_pntB.Y - a_pntA.Y * a_pntB.X;

  Result := Arctan2(dDeterminant, dDotProd);
end;

end.
