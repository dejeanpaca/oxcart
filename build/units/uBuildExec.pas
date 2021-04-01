{
   uBuildExec, executes build processes
   Copyright (C) 2020. Dejan Boras

   NOTE:
   - Pas() method building will only use some command line options for fpc, if a config file is set in
   build.FPCOptions.UseConfig, as all other fpc options (included units, target platform ...) are assumed to be
   provided in the config file.
   If no config file is provided, all build options are provided via command line options.
   Command line options can be overriden via the fpcParameters argument, in which case none of the above is performed.
   - Laz() method building will use the given lpi file and lazbuild to do the build, and the set Options are ignored.
}

{$INCLUDE oxheader.inc}
UNIT uBuildExec;

INTERFACE

   USES
      sysutils, uStd, uError, uLog, uSimpleParser, uFileUtils, ConsoleUtils,
      classes, process, uProcessHelpers,
      StringUtils,
      uBuild, uBuildInstalls, uBuildFPCConfig
      {$IFDEF UNIX}, BaseUnix{$ENDIF};

TYPE
   { TBuildSystemExec }

   TBuildSystemExec = record
      public
      {result of build output}
      Output: record
         Redirect,
         Success: boolean;
         ExitCode,
         ExitStatus: loopint;
         ExecutableName,
         ErrorDecription,
         LastLine,
         StdErr: StdString;
         OnLine: TProcedures;
      end;

      AbortFlag: boolean;
      Log: PLog;

      {the process we're executing}
      Process: TProcess;
      {stream from the executed process}
      ProcessStream: TProcessStream;

      {initialize}
      class procedure Initialize(out exec: TBuildSystemExec); static;

      {get lazarus project filename for the given path (which may already include project filename)}
      function GetLPIFilename(const path: StdString): StdString;
      {get tool process}
      function GetToolProcess(): TProcess;

      {build a lazarus project}
      procedure Laz(const originalPath: StdString);
      {retrieves the executable name from a lazarus project}
      function GetExecutableNameFromLPI(const path: StdString): StdString;
      {build an fpc program}
      procedure Pas(const originalPath: StdString; fpcParameters: PSimpleStringList = nil);
      {used to report building failed for a process (laz or fpc)}
      procedure BuildingFailed(const p: TProcess);

      {copies a tool into the tool directory}
      procedure CopyTool(const path: StdString);

      {build a tools (lazarus project) and copies it to the tools directory}
      procedure LazTool(const path: StdString);
      {build a tools (fpc source) and copies it to the tools directory}
      procedure PasTool(const path: StdString);

      {writes out output of a process}
      procedure LogOutput(const p: TProcess);

      {stores the output of a build process into the output structure}
      procedure StoreOutput(p: TProcess);
      procedure ResetOutput();
      {wait for a build process to finish (fpc/lazbuild)}
      procedure Wait();

      procedure Abort();
   end;

VAR
   BuildExec: TBuildSystemExec;

IMPLEMENTATION

{ TBuildSystemExec }

class procedure TBuildSystemExec.Initialize(out exec: TBuildSystemExec);
begin
   ZeroOut(exec, SizeOf(exec));

   TProcedures.Initialize(exec.Output.OnLine);
   TProcessStream.Initialize(exec.ProcessStream);

   exec.Log := @stdlog;
end;

function TBuildSystemExec.GetLPIFilename(const path: StdString): StdString;
begin
   if(ExtractFileExt(path) = '.lpi') then
      Result := path
   else
      Result := path + '.lpi';
end;

function TBuildSystemExec.GetToolProcess(): TProcess;
begin
   Result := TProcess.Create(nil);
   Result.ShowWindow := swoHIDE;

   if(not Output.Redirect) then
      Result.Options := Result.Options + [poWaitOnExit]
   else
      Result.Options := Result.Options + [poUsePipes];
end;

procedure TBuildSystemExec.Laz(const originalPath: StdString);
var
   executableName: StdString;
   path: StdString;
   lazarus: PBuildLazarusInstall;

begin
   AbortFlag := false;

   path := originalPath;
   ReplaceDirSeparators(path);

   ResetOutput();

   Log^.i('build > Building lazarus project: ' + path);

   lazarus := BuildInstalls.GetLazarus();

   Process := GetToolProcess();

   Process.Executable := lazarus^.Path + build.GetExecutableName('lazbuild');
   if(build.Options.Rebuild) then
      Process.Parameters.Add('-B');

   Process.Parameters.Add('-q');

   Process.Parameters.Add(GetLPIFilename(path));

   try
      Process.Execute();
   except
      on e: Exception do begin
         Log^.e('build > Failed to execute lazbuild: ' + lazarus^.Path + ' (' + e.ToString() + ')');
         StoreOutput(Process);
         FreeObject(Process);
         exit;
      end;
   end;

   Wait();
   StoreOutput(Process);

   if((Process.ExitStatus = 0) and (Process.ExitCode = 0)) then begin
      {NOTE: we exepect file name in LPI to not have a path}

      executableName := build.GetExecutableName(GetExecutableNameFromLPI(path));

      if(executableName <> '') then
         Output.ExecutableName := ExtractFilePath(path) + executableName
      else
         Output.ExecutableName := ExtractAllNoExt(path);

      Output.Success := true;
      Log^.k('build > Building successful');
   end else begin
      BuildingFailed(Process);
   end;

   FreeObject(Process);
end;

VAR
   executableNameNext: boolean;
   executableName: StdString;

function readf(var parseData: TParseData): boolean;
begin
   Result := true;

   if(parseData.CurrentLine = '<Target>') then begin
      executableNameNext := true;
   end else begin
      if(executableNameNext) then begin
         executableNameNext := false;

         if(pos('Filename', parseData.CurrentLine) > 0) then begin
            parseData.CurrentLine := CopyAfterDel(parseData.CurrentLine, '"');
            parseData.CurrentLine := CopyToDel(parseData.CurrentLine, '"');
            executableName := parseData.CurrentLine;
         end;
      end;
   end;
end;

function TBuildSystemExec.GetExecutableNameFromLPI(const path: StdString): StdString;
var
   p: TParseData;

begin
   executableName := '';
   executableNameNext := true;

   p.Create();
   p.StripWhitespace := true;
   p.Read(GetLPIFilename(path), TParseMethod(@readf));

   Result := executableName;
end;

procedure TBuildSystemExec.Pas(const originalPath: StdString; fpcParameters: PSimpleStringList = nil);
var
   path: StdString;
   i: loopint;
   platform: PBuildPlatform;
   parameters: TSimpleStringList;

begin
   AbortFlag := false;

   path := originalPath;
   ReplaceDirSeparators(path);

   Output.Success := false;
   platform := BuildInstalls.GetPlatform();

   Log^.i('build > Building: ' + path);

   Process := GetToolProcess();

   Process.Executable := platform^.GetExecutablePath();
   Log^.v('Running: ' + Process.Executable);

   if(fpcParameters = nil) then begin
      if(build.FPCOptions.UseConfig = '') then
         parameters := TBuildFPCConfiguration.GetFPCCommandLine()
      else
         parameters := TBuildFPCConfiguration.GetFPCCommandLineForConfig();
   end else
      parameters := fpcParameters^;

   for i := 0 to parameters.n - 1 do begin
      Process.Parameters.Add(parameters.List[i]);
   end;

   Process.Parameters.Add(path);

   try
      Process.Execute();
   except
      on e: Exception do begin
         Log^.e('build > Failed running: ' + Process.Executable + ' (' + e.ToString() + ')');
         StoreOutput(Process);
         FreeObject(Process);
         exit();
     end;
   end;

   Wait();
   StoreOutput(Process);

   if((Process.ExitStatus = 0) and (Process.ExitCode = 0)) then begin
      Output.ExecutableName := build.GetExecutableName(ExtractFilePath(path) +
         ExtractFileNameNoExt(path), build.Options.IsLibrary);

      Output.Success := true;
      Log^.k('build > Building successful');
   end else begin
      BuildingFailed(Process);
   end;

   FreeObject(Process);
end;

procedure TBuildSystemExec.BuildingFailed(const p: TProcess);
begin;
   Output.ErrorDecription := '';
   Output.Success := false;

   if(not FileExists(p.Executable)) then
      Output.ErrorDecription := 'tool not found: ' + p.Executable;

   if(p.ExitCode <> 0) then
      Output.ErrorDecription := 'tool returned exit code: ' + sf(p.ExitCode);

   if(p.ExitStatus <> 0) then
      Output.ErrorDecription := 'tool exited with status: ' + sf(p.ExitStatus);

   Log^.e('build > ' + Output.ErrorDecription);

   LogOutput(p);

   if(Output.StdErr <> '') then
      Log^.e(Output.StdErr);
end;

procedure TBuildSystemExec.CopyTool(const path: StdString);
var
   fullPath, target: StdString;
   error: fileint;

begin
   Output.Success := false;

   if(path = '') then begin
      Log^.e('build > CopyTool given empty parameter.');
      exit;
   end;

   fullPath := path;
   ReplaceDirSeparators(fullPath);

   target := build.Tools.Path + ExtractFileName(fullPath);

   if(FileUtils.Exists(fullPath) < 0) then begin
      Log^.e('build > Tool: ' + fullPath + ' could not be found');
      exit;
   end;

   error := FileUtils.Copy(fullPath, target);
   if(error < 0) then begin
      Log^.e('build > Copy tool: ' + path + ' to ' + target + ' failed: ' + sf(error) + '/' + getRunTimeErrorDescription(ioE));
      exit;
   end else
      Log^.i('build > Copied tool: ' + path + ' to ' + target);

   {$IFDEF UNIX}
   if(FpChmod(target, &755) <> 0) then begin
      log^.e('build > Failed to set tool permissions: ' + target);
      exit;
   end;
   {$ENDIF}

   Output.Success := true;
end;

procedure TBuildSystemExec.LazTool(const path: StdString);
begin
   Laz(path);

   if(Output.Success) then
      CopyTool(Output.ExecutableName);
end;

procedure TBuildSystemExec.PasTool(const path: StdString);
begin
   Pas(path);

   if(Output.Success) then
      CopyTool(Output.ExecutableName);
end;

procedure TBuildSystemExec.LogOutput(const p: TProcess);
var
   buffer: array[0..32768] of char;
   bufferRead: loopint;

begin
   {$IFDEF DEBUG}
   buffer[0] := #0;
   {$ENDIF}

   if(p.Output <> nil) and (p.Output.NumBytesAvailable > 0) then begin
      bufferRead := p.Output.Read(buffer{%H-}, Length(buffer));
      buffer[bufferRead] := #0;
      Log^.i(pchar(@buffer));
   end;
end;

procedure TBuildSystemExec.StoreOutput(p: TProcess);
begin
   Output.StdErr := '';
   Output.ExitCode := p.ExitCode;

   if(poUsePipes in p.Options) then begin
      if(not (poStderrToOutPut in p.Options)) and (p.Stderr <> nil) then
        Output.StdErr := TProcessUtils.GetString(p.Stderr);
   end;
end;

procedure TBuildSystemExec.ResetOutput();
begin
   Output.Success := false;
   Output.ExecutableName := '';
   Output.ErrorDecription := '';
end;

procedure TBuildSystemExec.Wait();
var
   s: StdString;

begin
   if(Output.Redirect) then
      Process.OpenOutputStream(ProcessStream);

   repeat
      if(Output.Redirect) then begin
         while(not eof(ProcessStream.Stream)) do begin
            ReadLn(ProcessStream.Stream, s);
            Output.LastLine := s;
            Output.OnLine.Call();
         end;

         break;
      end;

      if(AbortFlag) then begin
         Log^.i('build > aborted');

         if(Process <> nil) then
            Process.Terminate(0);

         break;
      end;

      Sleep(5);
   until (not Process.Running);

   ProcessStream.Close();
end;

procedure TBuildSystemExec.Abort();
begin
   Log^.i('build > aborting ...');

   AbortFlag := true;

   if(Process <> nil) then
      Process.Terminate(217);

   ProcessStream.Close();
end;

INITIALIZATION
   TBuildSystemExec.Initialize(BuildExec);

END.
