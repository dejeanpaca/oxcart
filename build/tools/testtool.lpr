{$MODE OBJFPC}{$H+}
PROGRAM testtool;

   USES
      uStd, uLog, ParamUtils, uFileUtils,
      uBuild, uTest, uTestRunner;

function processParams(const {%H-}pstr: StdString; const lstr: StdString): boolean;
begin
   if(lstr = '-file') then
      TestRunner.FileName := parameters.Next()
   else if(lstr = '-dir') then
      TestRunner.CurrentDirectory := true
   else if (lstr = '-selftest') then
      UnitTests.SelfTest := true
   else if (lstr = '-nobuild') then
      UnitTests.NoBuild := true
   else if (lstr = '-infomode') then
      UnitTests.InfoMode := true;

   result := true;
end;

BEGIN
   build.Initialize();

   if(build.Initialized) then begin
      parameters.process(@processParams);

      {only run info mode if set}
      if(UnitTests.InfoMode) then begin
         TestRunner.Run();
         UnitTests.Pool.Write(true);

         exit;
      end;

      UnitTests.InfoMode := true;
      TestRunner.Run();
      UnitTests.InfoMode := false;
      TestRunner.Run();
      TestRunner.WriteResults();
   end else
      halt(1);
END.
