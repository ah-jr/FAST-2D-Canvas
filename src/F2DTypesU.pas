unit F2DTypesU;

interface

uses
  Winapi.Windows,
  System.UITypes;

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

const
  c_nMaxVertices = 1024;

implementation

//==============================================================================
procedure TScreenVertex.AssignColor(a_clColor : TAlphaColor);
begin

end;

end.
