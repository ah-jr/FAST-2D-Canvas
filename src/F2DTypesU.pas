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
  color[0] := ((a_clColor and $00FF0000) shr (2 * 8)) / 255;
  color[1] := ((a_clColor and $0000FF00) shr (1 * 8)) / 255;
  color[2] := ((a_clColor and $000000FF) shr (0 * 8)) / 255;
  color[3] := ((a_clColor and $FF000000) shr (3 * 8)) / 255;
end;

end.
