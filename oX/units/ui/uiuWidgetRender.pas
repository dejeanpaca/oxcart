{
   uiuWidgetRender, widget rendering utilities
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT uiuWidgetRender;

INTERFACE

   USES
      uStd, uColors, vmVector,
      {ox}
      oxuTypes, oxuRender, oxuUI,
      uiuControl, uiuWidget, uiuDraw;

CONST
   wdgRENDER_BLOCK_SURFACE       = $0001;
   wdgRENDER_BLOCK_BORDER        = $0002;
   wdgRENDER_BLOCK_SIMPLE        = $0004;
   {render individual corners rounded instead of all}
   wdgRENDER_CORNERS             = $0008;
   {render individual corners rounded instead of all}
   wdgRENDER_CORNER_TL           = $0010;
   wdgRENDER_CORNER_TR           = $0020;
   wdgRENDER_CORNER_BL           = $0040;
   wdgRENDER_CORNER_BR           = $0080;

   wdgRENDER_LINE_TOP            = $0100;
   wdgRENDER_LINE_BOTTOM         = $0200;
   wdgRENDER_LINE_LEFT           = $0400;
   wdgRENDER_LINE_RIGHT          = $0800;

   wdgRENDER_CORNERS_ALL = wdgRENDER_CORNER_TL or wdgRENDER_CORNER_TR or
         wdgRENDER_CORNER_BL or wdgRENDER_CORNER_BR;
   wdgRENDER_LINES_ALL = wdgRENDER_LINE_TOP or wdgRENDER_LINE_BOTTOM or
         wdgRENDER_LINE_LEFT or wdgRENDER_LINE_RIGHT;
   wdgRENDER_BORDER_ALL = wdgRENDER_CORNERS_ALL or wdgRENDER_LINES_ALL;

   wdgRENDER_BLOCK_ALL = wdgRENDER_BLOCK_SURFACE or wdgRENDER_BLOCK_BORDER or wdgRENDER_BORDER_ALL;

TYPE

   { uiRenderWidget }

   uiRenderWidget = record
      class function GetCurvedFrameProperties(pos: uiTControlGridPosition): TBitSet; static;

      class procedure CurvedFrame(x1, y1, x2, y2: loopint); static;
      class procedure CurvedFrameCorners(x1, y1, x2, y2: loopint; corners: longword); static;

      {render the widget surface with bound lines}
      class procedure Box(x1, y1, x2, y2: longint; const sColor, bColor: TColor4ub; properties: TBitSet = wdgRENDER_BLOCK_ALL; opacity: single = 1.0); static;
      class procedure Box(wdg: uiTWidget; const sColor, bColor: TColor4ub; properties: TBitSet = wdgRENDER_BLOCK_ALL; opacity: single = 1.0); static;
      class procedure Box(const p: oxTPoint; const d: oxTDimensions; const sColor, bColor: TColor4ub; Properties: TBitSet = wdgRENDER_BLOCK_ALL; opacity: single = 1.0); static;
   end;


IMPLEMENTATION

class function uiRenderWidget.GetCurvedFrameProperties(pos: uiTControlGridPosition): TBitSet;
var
   edge: boolean = false;

begin
   Result := wdgRENDER_CORNERS_ALL or wdgRENDER_LINES_ALL;

   if(uiCONTROL_GRID_TOP in pos) then begin
      Result.Clear(wdgRENDER_CORNER_BL or wdgRENDER_CORNER_BR or wdgRENDER_LINE_BOTTOM);

      if(uiCONTROL_GRID_MIDDLE in pos) then
         Result.Clear(wdgRENDER_CORNER_TL or wdgRENDER_CORNER_TR or wdgRENDER_LINE_RIGHT);

      edge := true;
   end;

   if(uiCONTROL_GRID_BOTTOM in pos) then begin
      Result.Clear(wdgRENDER_CORNER_TL or wdgRENDER_CORNER_TR);

      if(uiCONTROL_GRID_MIDDLE in pos) then
         Result.Clear(wdgRENDER_CORNER_BL or wdgRENDER_CORNER_BR or wdgRENDER_LINE_RIGHT);

      edge := true;
   end;

   if(uiCONTROL_GRID_LEFT in pos) then begin
      Result.Clear(wdgRENDER_CORNER_TR or wdgRENDER_CORNER_BR or wdgRENDER_LINE_RIGHT);

      if(uiCONTROL_GRID_MIDDLE in pos) then
         Result.Clear(wdgRENDER_CORNER_TL or wdgRENDER_CORNER_BL or wdgRENDER_LINE_BOTTOM);

      edge := true;
   end;

   if(uiCONTROL_GRID_RIGHT in pos) then begin
      Result.Clear(wdgRENDER_CORNER_TL or wdgRENDER_CORNER_BL);

      if(uiCONTROL_GRID_MIDDLE in pos) then
         Result.Clear(wdgRENDER_CORNER_TR or wdgRENDER_CORNER_BR or wdgRENDER_LINE_BOTTOM);

      edge := true;
   end;

   if(not edge) then
      Result.Clear(wdgRENDER_LINE_RIGHT or wdgRENDER_LINE_BOTTOM or wdgRENDER_CORNERS_ALL);
end;

class procedure uiRenderWidget.CurvedFrame(x1, y1, x2, y2: loopint);
var
   p: array[0..3] of TVector2f;
   lines: array[0..3, 0..1] of TVector2f;

begin
   {$IFDEF DEBUG}
   {NOTE: Ignore hints since we initialize both p and lines below}
   p[0] := vmvZero2f;
   lines[0][0] := vmvZero2f;
   {$ENDIF}

   {draw the points}
   {bl}
   p[0].Assign(x1 + 1.375, y1 + 1.375);
   {br}
   p[1].Assign(x2 - 0.375, y1 + 1.375);
   {tl}
   p[2].Assign(x1 + 1.375, y2 - 0.375);
   {tr}
   p[3].Assign(x2 - 0.375, y2 - 0.375);

   uiDraw.Points(p);

   {draw the lines}

   {bottom - bl}
   lines[0][0].Assign(x1 + 2.375, y1 + 0.675);
   {bottom - br}
   lines[0][1].Assign(x2 - 0.675, y1 + 0.675);

   {top - tl}
   lines[1][0].Assign(x1 + 2.325, y2 + 0.675);
   {top - tr}
   lines[1][1].Assign(x2 - 0.375, y2 + 0.675);

   {left - bl}
   lines[2][0].Assign(x1 + 0.675, y1 + 2.675);
   {left - tl}
   lines[2][1].Assign(x1 + 0.675, y2 - 0.675);

   {right - br}
   lines[3][0].Assign(x2 + 0.675, y1 + 2.675);
   {right - tr}
   lines[3][1].Assign(x2 + 0.675, y2 - 0.675);

   oxRender.Vertex(lines[0, 0]);
   oxRender.DrawArrays(oxPRIMITIVE_LINES, 4 * 2);
end;

class procedure uiRenderWidget.CurvedFrameCorners(x1, y1, x2, y2: loopint; corners: longword);
var
   p: array[0..3] of TVector2f;
   lines,
   usedLines: array[0..3, 0..1] of TVector2f;
   pointCount,
   lineCount: loopint;

begin
   pointCount := 0;
   lineCount := 0;

   p[0] := vmvZero2f;
   p[1] := vmvZero2f;
   p[2] := vmvZero2f;
   p[3] := vmvZero2f;

   { SETUP LINES }
   {botton - bl}
   lines[0][0][0] := x1 + 0.675;
   lines[0][0][1] := y1 + 0.675;
   {botton - br}
   lines[0][1][0] := x2 + 0.675;
   lines[0][1][1] := y1 + 0.675;

   {top - tl}
   lines[1][0][0] := x1 + 0.675;
   lines[1][0][1] := y2 + 0.675;
   {top - tr}
   lines[1][1][0] := x2 + 1.375;
   lines[1][1][1] := y2 + 0.675;

   {left - bl}
   lines[2][0][0] := x1 + 0.675;
   lines[2][0][1] := y1 + 0.675;
   {left - tl}
   lines[2][1][0] := x1 + 0.675;
   lines[2][1][1] := y2 + 0.675;

   {right - br}
   lines[3][0][0] := x2 + 0.675;
   lines[3][0][1] := y1 + 0.675;
   {right - tr}
   lines[3][1][0] := x2 + 0.675;
   lines[3][1][1] := y2 + 0.675;

   if(corners <> 0) then begin
      if(corners and wdgRENDER_CORNERS_ALL > 0) then begin
         if(corners and wdgRENDER_CORNER_TL > 0) then begin
            p[pointCount].Assign(x1 + 1.375, y2 - 0.375);
            inc(pointCount);

            lines[1][0].Assign(x1 + 2.325, y2 + 0.675);
            lines[2][1].Assign(x1 + 0.675, y2 - 0.675);
         end;

         if(corners and wdgRENDER_CORNER_TR > 0) then begin
            p[pointCount].Assign(x2 - 0.375, y2 - 0.375);
            inc(pointCount);

            lines[1][1].Assign(x2 - 0.375, y2 + 0.675);
            lines[3][1].Assign(x2 + 0.675, y2 - 0.675);
         end;

         if(corners and wdgRENDER_CORNER_BL > 0) then begin
            p[pointCount].Assign(x1 + 1.375, y1 + 1.375);
            inc(pointCount);

            lines[0][0].Assign(x1 + 2.375, y1 + 0.675);
            lines[2][0].Assign(x1 + 0.675, y1 + 2.675);
         end;

         if(corners and wdgRENDER_CORNER_BR > 0) then begin
            p[pointCount].Assign(x2 - 0.375, y1 + 1.375);
            inc(pointCount);

            lines[0][1].Assign(x2 - 0.675, y1 + 0.675);
            lines[3][0].Assign(x2 + 0.675, y1 + 2.675);
         end;

         oxRender.Vertex(p[0]);
         oxRender.DrawArrays(oxPRIMITIVE_POINTS, pointCount);
      end;

      { setup lines }
      if(corners and wdgRENDER_LINES_ALL > 0) then begin
         usedLines[0][0] := vmvZero2f;
         usedLines[0][1] := vmvZero2f;

         if(corners and wdgRENDER_LINE_BOTTOM > 0) then begin
            usedLines[lineCount] := lines[0];
            inc(lineCount);
         end;

         if(corners and wdgRENDER_LINE_TOP > 0) then begin
            usedLines[lineCount] := lines[1];
            inc(lineCount);
         end;

         if(corners and wdgRENDER_LINE_LEFT > 0) then begin
            usedLines[lineCount] := lines[2];
            inc(lineCount);
         end;

         if(corners and wdgRENDER_LINE_RIGHT > 0) then begin
            usedLines[lineCount] := lines[3];
            inc(lineCount);
         end;

         {render lines}
         oxRender.Vertex(usedLines[0, 0]);
         oxRender.DrawArrays(oxPRIMITIVE_LINES, lineCount * 2);
      end;
   end;
end;

class procedure uiRenderWidget.Box(x1, y1, x2, y2: longint; const sColor, bColor: TColor4ub; properties: TBitSet = wdgRENDER_BLOCK_ALL; opacity: single = 1.0);
var
   sc,
   bc: TColor4ub;
   px1, py1, px2, py2: loopint;

begin
   sc := sColor;
   bc := bColor;

   sc[3] := round(opacity * sColor[3]);
   bc[3] := round(opacity * bColor[3]);

   {render the surface}
   if(properties.IsSet(wdgRENDER_BLOCK_SURFACE)) then begin
      oxui.Material.ApplyColor('color', sc);

      if(properties.IsSet(wdgRENDER_BLOCK_SIMPLE)) then
         uiDraw.Box(x1, y1, x2, y2)
      else begin
         if(properties and wdgRENDER_CORNERS > 0) then begin
            px1 := x1;
            py1 := y1;
            px2 := x2;
            py2 := y2;

            if(properties and wdgRENDER_LINE_LEFT > 0) then
               inc(px1);

            if(properties and wdgRENDER_LINE_BOTTOM > 0) then
               inc(py1);

            if(properties and wdgRENDER_LINE_RIGHT > 0) then
               dec(px2);

            if(properties and wdgRENDER_LINE_TOP > 0) then
               dec(py2);

            uiDraw.Box(px1, py1, px2, py2);
         end else
            uiDraw.Box(x1 + 1, y1 + 1, x2 - 1, y2 - 1)
      end;
   end;

   {render the border}
   if(properties.IsSet(wdgRENDER_BLOCK_BORDER)) then begin
      oxui.Material.ApplyColor('color', bc);

      if(properties.IsSet(wdgRENDER_BLOCK_SIMPLE)) then
         uiDraw.Rect(x1, y1, x2, y2)
      else begin
         if(not properties.IsSet(wdgRENDER_CORNERS)) then
            CurvedFrame(x1, y1, x2, y2)
         else
            CurvedFrameCorners(x1, y1, x2, y2, properties);
      end;
   end;
end;

class procedure uiRenderWidget.Box(wdg: uiTWidget;
   const sColor, bColor: TColor4ub; properties: TBitSet = wdgRENDER_BLOCK_ALL; opacity: single = 1.0);

begin
   Box( wdg.RPosition.x, wdg.RPosition.y - wdg.Dimensions.h + 1,
                        wdg.RPosition.x + wdg.Dimensions.w - 1, wdg.RPosition.y,
                        sColor, bColor, properties, opacity);
end;

class procedure uiRenderWidget.Box(const p: oxTPoint; const d: oxTDimensions;
   const sColor, bColor: TColor4ub; Properties: TBitSet; opacity: single);
begin
   Box( p.x, p.y - d.h + 1, p.x + d.w - 1, p.y,
                        sColor, bColor, properties, opacity);
end;

END.
