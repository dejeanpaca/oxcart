PROGRAM quatperformance;

USES dStd, dTiming,
   vmVector, vmQuaternions;

CONST
   ITERATIONS = 1 * 1024 * 1024;

VAR
   q: TQuaternion;
   m: TMatrix3;

procedure RunTest();
var
   i: longint;

begin
   for i := 0 to (ITERATIONS - 1) do
      vmqFromMatrix(m, q);
end;

procedure RunAltTest();
var
   i: longint;

begin
   for i := 0 to (ITERATIONS - 1) do
      vmqFromMatrixAlt(m, q);
end;

BEGIN
   m := vmmUnit3;

   timStart();
   RunTest();
   timUpdate();
   writeln('Standard took: ', timElapsed);

   timStart();
   RunAltTest();
   timUpdate();
   writeln('Alternative took: ', timElapsed);
END.
