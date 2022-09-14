unit FastD3DMathU;

interface

uses
  Winapi.Windows,
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

implementation

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
end.
