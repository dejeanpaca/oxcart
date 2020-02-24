{
   uTestProgram
   Copyright (C) 2015. Dejan Boras

   Handles a test program, compiles and runs it and reports Results.
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT uTestProgram;

INTERFACE

   USES
      process, uStd, uLog, StringUtils, uFileUtils,
      uBuild, uSimpleParser, uTest;

TYPE

   { TUnitTestProgram }

   TUnitTestProgram = class
      public
      Group: PUnitTestResultsPool;

      {description of any error occured}
      ErrorDescription: StdString;

      {filename of the test program}
      FileName: StdString;
      {has the test program successfully been run (nothing to do with any tests succeeding)}
      Success,
      {is the program a lazarus project}
      Laz: boolean;

      Results: TUnitTestResults;

      {set the test program lazarus project or source code file}
      procedure SetFile(const fn: StdString);
      {analyzes the test program to find all the available tests}
      procedure Analyze();
      {executes the test program}
      procedure Execute();
      procedure Execute(const fn: StdString);

      function LoadResults(): boolean;
      procedure DeleteResults();
   end;

   { TUnitTestProgramGlobal }

   TUnitTestProgramGlobal = record
      function RunProgram(const fileName: StdString): boolean;
   end;

VAR
   TestProgram: TUnitTestProgramGlobal;

IMPLEMENTATION

{ TUnitTestProgramGlobal }

function TUnitTestProgramGlobal.RunProgram(const fileName: StdString): boolean;
var
   tp: TUnitTestProgram;
   i: longint;

begin
   Result := false;

   tp := TUnitTestProgram.Create();
   tp.Execute(fileName);

   if(tp.ErrorDescription <> '') and (tp.group <> nil) then
      tp.group^.ErrorDescription := tp.ErrorDescription;

   if(UnitTests.InfoMode) or (not tp.Success) then begin
      FreeObject(tp);
      exit;
   end;

   if(tp.ErrorDescription = '') then begin
      tp.LoadResults();

      if(tp.ErrorDescription = '') then begin
         UnitTests.Pool.SetResultsFrom(tp.Results);

         log.i('test count: ' + sf(tp.Results.List.n));

         if(tp.Results.List.n > 0) then begin
            for i := 0 to (tp.Results.List.n - 1) do begin
               if(tp.Results.List.List[i].Success) then
                  log.i('test > ' + tp.Results.List.List[i].Name + ': pass')
               else
                  log.i('test > ' + tp.Results.List.List[i].Name + ': fail');
            end;
         end;

         Result := true;
      end else
         log.e(tp.ErrorDescription);

      tp.DeleteResults();
   end else
      log.e(tp.ErrorDescription);

   if(tp.ErrorDescription <> '') and (tp.group <> nil) then
      tp.group^.ErrorDescription := tp.ErrorDescription;

   FreeObject(tp);
end;

{ TUnitTestProgram }

procedure TUnitTestProgram.SetFile(const fn: StdString);
begin
   fileName := fn;
   laz := LowerCase(ExtractFileExt(fileName)) = '.lpi';
end;

function analyzeFile(var p: TParseData): boolean;
var
   tp: TUnitTestProgram;
   idx: longint;
   name,
   description,
   currentLine: StdString;

procedure getNameAndDescription();
begin
   name := '';

   idx := pos('''', p.CurrentLine);
   Delete(p.CurrentLine, 1, idx);
   idx := pos('''', p.CurrentLine);
   name := copy(p.CurrentLine, 1, idx - 1);

   description := '';
   Delete(p.CurrentLine, 1, idx);

   idx := pos('''', p.CurrentLine);
   if(idx > 0) then begin
      Delete(p.CurrentLine, 1, idx);
      idx := pos('''', p.CurrentLine);
      description := copy(p.CurrentLine, 1, idx - 1);
   end;
end;

begin
   tp := TUnitTestProgram(p.ExternalData);

   currentLine := lowercase(p.CurrentLine);
   name := '';
   description := '';

   {found group name}

   if(pos('unittests.initialize(', currentLine) > 0) then begin
      getNameAndDescription();

      {group already exists, no need to analyze the file}
      tp.group := UnitTests.Pool.Find(name);
      if(tp.group <> nil) then begin
         log.e('Failed to find group with name: ' + name);
         exit(false);
      end;

      tp.group := UnitTests.Pool.Add(name);
   {found a test}
   end else if(pos('unittests.add(', currentLine) > 0) then begin
      getNameAndDescription();

      if(tp.group <> nil) then
         tp.group^.Results.Add(name, description);
   end;

   Result := true;
end;

procedure TUnitTestProgram.Analyze();
var
   p: TParseData;
   fn: StdString;

begin
   log.i('Analyzing: ' + fileName);

   fn := fileName;
   {use lpr file, instead of lpi for analysis, as we analyze the code, not the project file}
   if(laz) then
      fn := ExtractAllNoExt(fn) + '.lpr';

   TParseData.Init(p);
   p.ExternalData := Self;
   p.Read(fn, TParseMethod(@analyzeFile));
end;

procedure TUnitTestProgram.Execute();
var
   p: TProcess;

begin
   Success := false;

   Analyze();

   if(UnitTests.InfoMode) then
      exit;

   log.i('Running program: ' + fileName);

   {compile first}
   if(not UnitTests.NoBuild) then begin
      if(laz) then
         build.Laz(fileName)
      else
         build.Pas(fileName);

      if(build.Output.ErrorDecription <> '') then
         ErrorDescription := build.Output.ErrorDecription;
   end;

   if(not build.Output.Success) then
      exit();

   {run}
   p := TProcess.Create(nil);

   p.Executable := build.Output.ExecutableName;

   if(build.Output.ExecutableName <> '') then begin
      try
         p.Execute();

         repeat
         until (not p.Running);

         log.i('Executed: ' + build.Output.ExecutableName);

         if(p.ExitStatus = 0) then
            Success := true
         else
            ErrorDescription := 'Failure: Test program returned a non-zero exit code.';
      except
         ErrorDescription := 'Failed to execute test program: ' + build.Output.ExecutableName;
      end;
   end else
      ErrorDescription := 'Could not determine executable name for ' + fileName;

   p.Free();
end;

procedure TUnitTestProgram.Execute(const fn: StdString);
begin
   SetFile(fn);
   Execute();
end;

function TUnitTestProgram.LoadResults(): boolean;
begin
   Result := UnitTests.LoadResults(Results);

   ErrorDescription := UnitTests.ErrorDescription;
end;

procedure TUnitTestProgram.DeleteResults();
begin
   if(fileName <> '') then begin
      FileUtils.Erase(TEST_RESULTS_FILENAME);
      ioerror();
   end;
end;

END.
