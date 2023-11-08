{$MODE OBJFPC}{$H+}{$I-}
PROGRAM Test;

USES
   math, matrix,
   uStd,
   {vmVector}
   vmVector, vmQuaternions, vmCollision, vmBezier, vmMath, vmPerlin;

CONST
   a: TVector3f = (-5.0, -5.0, 0.0);
   b: TVector3f = (5.0,  5.0, 0.0);

VAR
   c: TVector3f;
   m,
   inv_m: matrix.Tmatrix4_single;
   vmM,
   vmMInverse: TMatrix4f;

   i, j: loopint;

BEGIN
   c := vmDirectionAB(a, b);
   writeln(c[0]:0:2, 'x', c[1]:0:2, 'x', c[2]:0:2);
   c := vmDirectionAB(b, a);
   writeln(c[0]:0:2, 'x', c[1]:0:2, 'x', c[2]:0:2);

   m.init_identity();
   vmM := vmmUnit4;

   for i := 0 to 3 do
      for j := 0 to 3 do begin
         writeln(m.data[i][j]:0:3, ' ', vmM[i][j]:0:3);

         if(m.data[i][j] <> vmM[i][j]) then begin
            writeln('Unit mismatch at ', i, ' ', j, m.data[i][j]:0:3, ' ', vmM[i][j]:0:3);
         end;
      end;

   inv_m := m.inverse(1);
   writeln('ndet: ', m.determinant:0:3);
   vmMInverse := vmM.Inversed();

   for i := 0 to 3 do
      for j := 0 to 3 do begin
         if(inv_m.data[i][j] <> vmMInverse[i][j]) then begin
            writeln('Inverse mismatch at ', i, ' ', j, inv_m.data[i][j]:0:3, ' ', vmMInverse[i][j]:0:3);
         end;
      end;
END.
