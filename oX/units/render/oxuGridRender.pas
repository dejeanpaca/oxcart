{
   oxuGridRender, utilities and helpers for rendering
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuGridRender;

INTERFACE

   USES
     uStd, vmVector,
     {oX}
     oxuRender, oxuTypes, oxuTransform;

TYPE

   { oxTGridRender }

   oxTGridRender = record
      procedure Render2D(size: single; count: loopint; offsetY: single = 0; closeEdges: boolean = true);
      procedure Render3D(size: single; count: loopint; closeEdges: boolean = true);
   end;

VAR
   oxGridRender: oxTGridRender;

IMPLEMENTATION


{ oxTGridRender }

procedure oxTGridRender.Render2D(size: single; count: loopint; offsetY: single; closeEdges: boolean);
var
   i,
   pos: loopint;
   separation: single;
   grid: array[0..65535] of TVector3f;


begin
   pos := 0;

   grid[0] := vmvZero3f;

   separation := size / count;

   for i := 0 to count - 1 do begin
      grid[pos][0] := -size;
      grid[pos][1] := offsetY;
      grid[pos][2] := separation * i;

      inc(pos);

      grid[pos][0] := +size;
      grid[pos][1] := offsetY;
      grid[pos][2] := separation * i;

      inc(pos);

      grid[pos][0] := -size;
      grid[pos][1] := offsetY;
      grid[pos][2] := -separation * i;

      inc(pos);

      grid[pos][0] := +size;
      grid[pos][1] := offsetY;
      grid[pos][2] := -separation * i;

      inc(pos);
   end;

   for i := 0 to count - 1 do begin
      grid[pos][0] := separation * i;
      grid[pos][1] := offsetY;
      grid[pos][2] := -size;

      inc(pos);

      grid[pos][0] := separation * i;
      grid[pos][1] := offsetY;
      grid[pos][2] := +size;

      inc(pos);

      grid[pos][0] := -separation * i;
      grid[pos][1] := offsetY;
      grid[pos][2] := -size;

      inc(pos);

      grid[pos][0] := -separation * i;
      grid[pos][1] := offsetY;
      grid[pos][2] := +size;

      inc(pos);
   end;

   if(closeEdges) then begin
      separation := size;

      grid[pos][0] := -size;
      grid[pos][1] := offsetY;
      grid[pos][2] := separation;

      inc(pos);

      grid[pos][0] := +size;
      grid[pos][1] := offsetY;
      grid[pos][2] := separation;

      inc(pos);

      grid[pos][0] := -size;
      grid[pos][1] := offsetY;
      grid[pos][2] := -separation;

      inc(pos);

      grid[pos][0] := +size;
      grid[pos][1] := offsetY;
      grid[pos][2] := -separation;

      inc(pos);

      grid[pos][0] := separation;
      grid[pos][1] := offsetY;
      grid[pos][2] := -size;

      inc(pos);

      grid[pos][0] := separation;
      grid[pos][1] := offsetY;
      grid[pos][2] := +size;

      inc(pos);

      grid[pos][0] := -separation;
      grid[pos][1] := offsetY;
      grid[pos][2] := -size;

      inc(pos);

      grid[pos][0] := -separation;
      grid[pos][1] := offsetY;
      grid[pos][2] := +size;

      inc(pos);
   end;

   oxRender.Vertex(grid[0]);
   oxRender.DrawArrays(oxPRIMITIVE_LINES, pos);
end;

procedure oxTGridRender.Render3D(size: single; count: loopint; closeEdges: boolean);
var
   i,
   j,
   pos: loopint;
   separation,
   offsetY: single;
   grid: array[0..65535] of TVector3f;


begin
   pos := 0;
   grid[0] := vmvZero3f;

   separation := size / count;

   for i := 0 to (count * 2) do begin
      for j := 0 to (count * 2) do begin
         grid[pos][0] := separation * j - size;
         grid[pos][1] := -size;
         grid[pos][2] := separation * i - size;

         inc(pos);

         grid[pos][0] := separation * j - size;
         grid[pos][1] := +size;
         grid[pos][2] := separation * i - size;

         inc(pos);
      end;
   end;

   for i := 0 to (count * 2) do begin
      offsetY := separation * i - size;
      Render2D(size, count, offsetY, closeEdges);
   end;

   oxRender.Vertex(grid[0]);
   oxRender.DrawArrays(oxPRIMITIVE_LINES, pos);
end;

END.

