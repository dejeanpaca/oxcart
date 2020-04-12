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

{$INCLUDE oxdefines.inc}
UNIT uBuildExec;

INTERFACE

   USES
      sysutils, uStd, uLog, uSimpleParser, uFileUtils, ConsoleUtils,
      classes, process, StreamIO,
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
         LastLine: StdString;
         OnLine: TProcedures;
      end;

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

      {run a command (abstraction over process.RunCommand)}
      procedure RunCommand(const exename: StdString; const commands: array of StdString);
      procedure RunCommandCurrentDir(const exename: StdString; const commands: array of StdString);

      {stores the output of a build process into the output structure}
      procedure StoreOutput(p: TProcess);
      procedure ResetOutput();
      {wait for a build process to finish (fpc/lazbuild)}
      procedure Wait(p: TProcess);
   end;

VAR
   BuildExec: TBuildSystemExec;

IMPLEMENTATION

{ TBuildSystemExec }

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

   if(not Output.Redirect) then
      Result.Options := Result.Options + [poWaitOnExit]
   else
      Result.Options := Result.Options + [poUsePipes];
end;

procedure TBuildSystemExec.Laz(const originalPath: StdString);
var
   p: TProcess;
   executableName: StdString;
   path: StdString;
   lazarus: PBuildLazarusInstall;

begin
   path := originalPath;
   ReplaceDirSeparators(path);

   ResetOutput();

   log.i('build > Building lazarus project: ' + path);

   lazarus := BuildInstalls.GetLazarus();

   p := GetToolProcess();

   p.Executable := lazarus^.Path + build.GetExecutableName('lazbuild');
   if(build.Options.Rebuild) then
      p.Parameters.Add('-B');

   p.Parameters.Add('-q');

   p.Parameters.Add(GetLPIFilename(path));

   try
      p.Execute();
   except
      on e: Exception do begin
         log.e('build > Failed to execute lazbuild: ' + lazarus^.Path + ' (' + e.ToString() + ')');
         StoreOutput(p);
         p.Free();
         exit;
      end;
   end;

   Wait(p);
   StoreOutput(p);

   if((p.ExitStatus = 0) and (p.ExitCode = 0)) then begin
      {NOTE: we exepect file name in LPI to not have a path}

      executableName := build.GetExecutableName(GetExecutableNameFromLPI(path));

      if(executableName <> '') then
         Output.ExecutableName := ExtractFilePath(path) + executableName
      else
         Output.ExecutableName := ExtractAllNoExt(path);

      Output.Success := true;
      log.k('build > Building successful');
   end else begin
      BuildingFailed(p);
   end;

   p.Free();
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

   TParseData.Init(p);
   p.StripWhitespace := true;
   p.Read(GetLPIFilename(path), TParseMethod(@readf));

   Result := executableName;
end;

procedure TBuildSystemExec.Pas(const originalPath: StdString; fpcParameters: PSimpleStringList = nil);
var
   p: TProcess;
   path: StdString;
   i: loopint;
   platform: PBuildPlatform;
   parameters: TSimpleStringList;

begin
   path := originalPath;
   ReplaceDirSeparators(path);

   Output.Success := false;
   platform := BuildInstalls.GetPlatform();

   log.i('build > Building: ' + path);

   p := GetToolProcess();

   p.Executable := build.GetExecutableName(platform^.Path + 'fpc');

   if(fpcParameters = nil) then begin
      if(build.FPCOptions.UseConfig = '') then
         parameters := TBuildFPCConfiguration.GetFPCCommandLine()
      else
         parameters := TBuildFPCConfiguration.GetFPCCommandLineForConfig();
   end else
      parameters := fpcParameters^;

   for i := 0 to parameters.n - 1 do begin
      p.Parameters.Add(parameters.List[i]);
   end;

   p.Parameters.Add(path);

   try
      p.Execute();
   except
      on e: Exception do begin
         log.e('build > Failed running: ' + p.Executable + ' (' + e.ToString() + ')');
         StoreOutput(p);
         p.Free();
         exit();
     end;
   end;

   Wait(p);
   StoreOutput(p);

   if((p.ExitStatus = 0) and (p.ExitCode = 0)) then begin
      Output.ExecutableName := build.GetExecutableName(ExtractFilePath(path) + ExtractFileNameNoExt(path), build.Options.IsLibrary);
      Output.Success := true;
      log.k('build > Building successful');
   end else begin
      BuildingFailed(p);
   end;

   p.Free();
end;

procedure TBuildSystemExec.BuildingFailed(const p: TProcess);
begin
   Output.ErrorDecription := '';
   Output.Success := false;

   if(not FileExists(p.Executable)) then
      Output.ErrorDecription := 'tool not found: ' + p.Executable;

   if(p.ExitCode <> 0) then
      Output.ErrorDecription := 'tool returned exit code: ' + sf(p.ExitCode);
   if(p.ExitStatus <> 0) then
      Output.ErrorDecription := 'tool exited with status: ' + sf(p.ExitStatus);

   log.e('build > ' + Output.ErrorDecription);

   LogOutput(p);
end;

procedure TBuildSystemExec.CopyTool(const path: StdString);
var
   fullPath, target: StdString;
   error: fileint;

begin
   Output.Success := false;

   if(path = '') then begin
      log.e('build > CopyTool given empty parameter.');
      exit;
   end;

   fullPath := path;
   ReplaceDirSeparators(fullPath);

   target := build.Tools.Path + ExtractFileName(fullPath);

   if(FileUtils.Exists(fullPath) < 0) then begin
      log.e('build > Tool: ' + fullPath + ' could not be found');
      exit;
   end;

   error := FileUtils.Copy(fullPath, target);
   if(error < 0) then begin
      log.e('build > Copy tool: ' + path + ' to ' + target + ' failed: ' + sf(error) + '/' + getRunTimeErrorDescription(ioE));
      exit;
   end else
      log.i('build > Copied tool: ' + path + ' to ' + target);

   {$IFDEF UNIX}
   if(FpChmod(target, &755) <> 0) then begin
      log.e('build > Failed to set tool permissions: ' + target);
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
      log.i(pchar(@buffer));
   end;
end;

procedure TBuildSystemExec.RunCommand(const exename: StdString; const commands: array of StdString);
var
   outputString: string = '';
   ansiCommands: array of String;

begin
   ansiCommands := StringUtils.GetAnsiStrings(commands);

   if(not process.RunCommand(exename, ansiCommands, outputString)) then
      log.e('Failed to run process: ' + exename);

   if(outputString <> '') then
      console.i(outputString);
end;

procedure TBuildSystemExec.RunCommandCurrentDir(const exename: StdString; const commands: array of StdString);
begin
   RunCommand(IncludeTrailingPathDelimiterNonEmpty(GetCurrentDir()) + exename, commands);
end;

procedure TBuildSystemExec.StoreOutput(p: TProcess);
begin
   Output.ExitCode := p.ExitCode;

   if(poUsePipes in p.Options) then begin
      if(not (poStderrToOutPut in p.Options)) and (p.Stderr <> nil) then begin
         try
            p.Stderr.Seek(0, soBeginning);

            if(p.Stderr.NumBytesAvailable > 0) then
               Output.ErrorDecription := p.Stderr.ReadAnsiString();
         except
            on e : Exception do begin
               log.e('build > Failed to read output: ' + e.ToString());
               Output.ErrorDecription := '';
            end;
         end;
      end;
   end;
end;

procedure TBuildSystemExec.ResetOutput();
begin
   Output.Success := false;
   Output.ExecutableName := '';
   Output.ErrorDecription := '';
end;

procedure TBuildSystemExec.Wait(p: TProcess);
var
   s: StdString;
   f: TextFile;

begin
   ZeroOut(f, SizeOf(f));

   if(Output.Redirect) then begin
      AssignStream(f, p.Output);
      Reset(f);
   end;

   repeat
      if(Output.Redirect) then begin
         while(not eof(f)) do begin
            ReadLn(f, s);
            Output.LastLine := s;
            Output.OnLine.Call();
         end;

         break;
      end;

      Sleep(5);
   until (not p.Running);

   if(Output.Redirect) then begin
      Close(f);
   end;
end;

INITIALIZATION
   TProcedures.Initialize(BuildExec.Output.OnLine);

END.
