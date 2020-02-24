{
   vmVector, matrix operations
   Copyright (C) 2010. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT vmMatrix;

INTERFACE

   USES vmVector;

{convert a 3x3 matrix to a 4x4 matrix}
procedure vmMatrix3ToMatrix4(const m3: TMatrix3; var m4: TMatrix4); {$IFDEF VM_INLINE}inline;{$ENDIF} {OK}

IMPLEMENTATION

procedure vmMatrix3ToMatrix4(const m3: TMatrix3; var m4: TMatrix4); {$IFDEF VM_INLINE}inline;{$ENDIF} {OK}
begin
   {set the m3 the top-left 3x3 matrix values in the m4, fill the other
   values with zeroes, and the down-right value with 1}

   m4[0][0] := m3[0][0];
   m4[0][1] := m3[0][1];
   m4[0][2] := m3[0][2];
   m4[0][3] := 0;

   m4[1][0] := m3[1][0];
   m4[1][1] := m3[1][1];
   m4[1][2] := m3[1][2];
   m4[1][3] := 0;

   m4[2][0] := m3[2][0];
   m4[2][1] := m3[2][1];
   m4[2][2] := m3[2][2];
   m4[2][3] := 0;

   m4[3][0] := 0;
   m4[3][1] := 0;
   m4[3][2] := 0;
   m4[3][3] := 1;
end;

END.
