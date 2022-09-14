unit F2DTypesU;

interface

uses
  Winapi.Windows;

type
  TD3DCanvasProperties = record
    Hwnd        : HWND;
    Width       : Integer;
    Height      : Integer;
    MSAA        : Integer;
  end;

  T3DSingleArray = array [0..2] of Single;
  T4DSingleArray = array [0..3] of Single;

  TSimpleVertex = record
    pos : T4DSingleArray;
    color: T4DSingleArray;
  end;

  PSimpleVertex = ^TSimpleVertex;

implementation

end.
