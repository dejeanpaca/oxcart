{
   uTest
   Copyright (C) 2015. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uTestRunner;

INTERFACE

   USES sysutils, uStd, uLog, uFileUtils, StringUtils,
     uTest, uTestProgram;

TYPE

   { TTestRunner }

   TTestRunner = record
     {should tests only run in the current directory}
     CurrentDirectory: boolean;
     {run a a test with a specific filename}
     FileName,
     {directory to run within (if empty, assume current)}
     Directory: StdString;

     procedure RunDirectory(recursive: boolean = false);
     procedure RunRecursive();
     procedure Run();
     procedure WriteResults();

     procedure Destroy();
   end;

VAR
   TestRunner: TTestRunner;

IMPLEMENTATION

function RecursiveOnFile(const f: TFileTraverseData): boolean;
var
   ext: StdString;

begin
   Result := true;

   if(FileExists(ExtractFilePath(f.f.Name) + DirectorySeparator + 'tests.self') and (not UnitTests.SelfTest)) then
      exit;

   ext := ExtractFileExts(f.f.Name, 2);
   if(ext <> '') then begin
      if(ext = '.test.lpi') or (ext = '.test.pas') then
         TestProgram.RunProgram(f.f.Name);
   end;
end;

procedure TTestRunner.RunDirectory(recursive: boolean);
var
   traverse: TFileTraverse;

begin
   TFileTraverse.Initialize(traverse);

   traverse.OnFile := @RecursiveOnFile;
   traverse.Recursive := recursive;

   traverse.AddExtension('.lpi');
   traverse.AddExtension('.pas');

   if(Directory <> '') then
      traverse.Run(Directory)
   else
      traverse.Run();
end;

procedure TTestRunner.RunRecursive();
begin
   RunDirectory(true);
end;

procedure TTestRunner.Run();
begin
   if(CurrentDirectory) then begin
      RunDirectory();
      exit;
   end;

   if(FileName <> '') then begin
      TestProgram.RunProgram(FileName);
      exit;
   end;

   RunRecursive();
end;

procedure TTestRunner.WriteResults();
var
   passCount,
   failCount: longint;
   what: StdString;

begin
   failCount := UnitTests.Pool.FailCount();
   passCount := UnitTests.Pool.PassCount();

   log.i();
   log.i('> Results');
   UnitTests.Pool.Write(true);
   log.i();

   what := '> Total Results';
   if(failCount > 0) then
      log.e(what)
   else
      log.k(what);

   log.i();
   log.i('Groups: ' + sf(UnitTests.Pool.GroupCount()));
   log.i('Tests: ' + sf(UnitTests.Pool.TestCount()));

   what := 'Passed: ' + sf(passCount);

   if(failCount > 0) then
      log.i(what)
   else
      log.k(what);

   if(failCount > 0) then
      log.e('Failed: ' + sf(failCount))
   else
      log.i('Failed: 0');
end;

procedure TTestRunner.Destroy();
begin
   UnitTests.Destroy();
end;

END.

