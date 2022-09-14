# WIP:  FAST-2D-Canvas

# Disclaimer

This library is NOT ready to be used, there are still many things to be implemented/tested.
Contributions are welcome.

# About

This is a library that wraps D3D11 to provide functions for creating 2D graphics.  
It is extremely useful in situations in which hardware processing is needed, such as drawing very fast real-time graphics, with a large number of lines and polygons. In those occasions, it should outperform Direct2D considerably.  

# Implemented functions so far

- DrawLine - Creates a colored line:
```
procedure DrawLine(a_pntA : TPointF; a_pntB : TPointF; a_clColor : TAlphaColor; a_nWidth : Single);
```

# Usage

In order to initialize the canvas, you must pass as paramter a TF2DCanvasProperties struct, containing the dimensions and HWND of the parent:  

```
(...)

uses
  F2DTypesU,
  F2DCanvasU; 
  
(...)

procedure InitializeCanvas;
var
  f2dProp : TF2DCanvasProperties;
begin
  with f2dProp do
  begin
    Hwnd   := Handle;
    Width  := ClientWidth;
    Height := ClientHeight;
    MSAA   := 4;
  end;

  //////////////////////////////////////////////////////////////////////////////
  ///  Create canvas
  m_f2dCanvas := TF2DCanvas.Create(f2dProp
  
end;
```

For drawing, use BeginDraw and EndDraw calls:  

```
  m_f2dCanvas.BeginDraw;

  // Clear background
  m_f2dCanvas.Clear($FF000000);

  // Write 'Lines' with lines
  m_f2dCanvas.DrawLine(PointF(10, 10), PointF(200, 200), $FFFF0000, 1);

  m_f2dCanvas.EndDraw;
```
