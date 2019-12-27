{
   oxuStarfield, a simple point star field
   Copyright (C) 2011. Dejan Boras

   Started On:    07.05.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuStarfield;

INTERFACE

USES
      vmVector, uColors, uStd,
      {oX}
      oxuTypes, oxuTimer, oxuTransform, oxuRender;

TYPE

   { oxTStarfield }

   oxTStarfield = class
      public
         nStars: longint;
         Stars: array of TVector3f;
         Colors: array of TColor3f;

         theta: single;
         farZ,
         farZ2: single;
         speed: single;

         errorCode: longint;

      constructor Create();
      procedure genStar(var v: TVector3f);
      procedure CreateStars(n: longint);
      procedure CreateStart();
      procedure Render();
   end;

IMPLEMENTATION

constructor oxTStarfield.Create();
begin
    nStars  := 0;
    farZ    := 1000.0;
    farZ2   := farZ / 2;
    theta   := 0.0;
    speed   := 40.0;
end;

procedure oxTStarfield.genStar(var v: TVector3f);
begin
   v[0] :=  random() * farZ - farZ2;
   v[1] :=  random() * farZ - farZ2;
   v[2] := -random() * farZ;
end;

procedure oxTStarfield.CreateStars(n: longint);
var
   i: longint;

begin
   if(n > 0) then begin
      nStars := n;

      try
         SetLength(Stars, nStars);
      except
         errorCode := eNO_MEMORY;
         exit;
      end;

      try
         SetLength(Colors, nStars);
      except
         errorCode := eNO_MEMORY;
         exit;
      end;

      for i := 0 to (n - 1) do
         genStar(Stars[i]);

      for i := 0 to (n - 1) do
         Colors[i] := cWhite3f;
   end;
end;

procedure oxTStarfield.CreateStart();
begin
   CreateStars(nStars);
end;

procedure oxTStarfield.Render();
var
   i: longint;
   dt,
   col: single;

begin
   if(nStars > 0) then begin
      {glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);}

      {TODO: Replace with ox equivalent
      glEnable(GL_POINT_SMOOTH);
      glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);}

      oxRender.PointSize(1.2);

      dt    := oxMainTimeFlow;
      theta := theta + (5 * dt);

      {move and regenerate stars}
      for i := 0 to (nStars - 1) do begin
         Stars[i][2] := Stars[i][2] + (speed * dt);
         if(Stars[i][2] >= 0.0) then begin
            Stars[i][0] := random() * farZ - farZ2;
            Stars[i][1] := random() * farZ - farZ2;
            Stars[i][2] := -farZ;
         end;

         col := 1.0 - (abs(Stars[i][2]) / farZ);
         if(col <= 0.05) then
            col := 0.05;

         FillDWord(Colors[i], 3, longword(col));
      end;

      {prepare for rendering}
      oxTransform.Identity();

      oxTransform.RotateZ(theta);
      oxTransform.Apply();

      oxRender.Vertex(Stars[0]);
      oxRender.Color(Colors[0]);

      {shove the data down GPU's throat}
      oxRender.DrawArrays(oxPRIMITIVE_POINTS, nStars);
   end;
end;

END.
