{
   Deploys the workspace into a workable state. Builds certain often used tools.
}

{$INCLUDE oxheader.inc}
PROGRAM setup;

   USES
      sysutils, uStd, StringUtils, uLog, uFileUtils, appuPaths,
      ParamUtils, uTiming, uProcessHelpers,
      uBuild, uBuildConfiguration, uBuildInstalls,  uBuildExec,
      uLPI, uLPIBuild, uTest;

TYPE
   TTool = record
      Name,
      Path: string;
   end;

CONST
   PROGRAMS_SOURCE = '../programs/';
   BUILD_SOURCE= '../build/';

   laz_tools: array[0..3] of TTool = (
      (Name: 'file2code'; Path: PROGRAMS_SOURCE + 'file2code/file2code'),
      (Name: 'txt2passtr'; Path: PROGRAMS_SOURCE + 'pasutils/txt2passtr'),
      (Name: 'testtool'; Path: BUILD_SOURCE + 'tools/testtool'),
      (Name: 'lpitool'; Path: BUILD_SOURCE + 'tools/lpitool')
   );

   pas_tools: array[0..0] of TTool = (
      (Name: ''; Path: '')
   );

VAR
   build_what,
   path: string;
   build_count: longint = 0;
   fail_count: longint = 0;
   symbolParameters: array of string;
   cleanBuild,

   checkedToolDir: boolean;
   quitOnFail: boolean = true;

   setupTimer: TTimer;

procedure fail(const reason: string);
begin
   log.e(reason);
   halt(1);
end;

function can_build(const specific: string): boolean;
begin
  {build if specified this, or nothing specified}
  Result := (specific = build_what) or (build_what = '');
end;

procedure build_tool(var tool: TTool; pas: boolean);
begin
   if(tool.Path = '') then
      exit;

   BuildExec.ResetOutput();

   if(not checkedToolDir) then begin
      if not DirectoryExists(build.Tools.Path) then begin
         fail('Could not find tool output directory: ' + build.Tools.Path);
      end;

      checkedToolDir := true;
   end;

   if (build_what = 'tools') or can_build(tool.Name) then begin
      log.w('Building: ' + tool.Name);

      if pas then
         BuildExec.PasTool(tool.Path)
      else begin
         if(FileUtils.Exists(tool.Path + '.lpi') > 0) then begin
            BuildExec.LazTool(tool.Path);
         end else begin
            lpibuild.BuildFromPas(tool.Path);
         end;
      end;

      if BuildExec.Output.Success then begin
         inc(build_count);
         log.k('SUCCESS: ' + tool.Name);
      end else begin
         inc(fail_count);
         log.e('FAILED: ' + tool.Name);
      end;

      log.i();
  end;
end;

procedure build_tools();
var
   i: longint;

begin
   log.v('FPC: ' + BuildInstalls.GetPlatform()^.GetExecutablePath());
   log.v('Lazarus: ' + BuildInstalls.CurrentLazarus^.Path);
   log.v('');

   for i := 0 to high(laz_tools) do begin
      build_tool(laz_tools[i], false);

      if(quitOnFail) and (fail_count > 0) then
         exit;
   end;

   for i := 0 to high(pas_tools) - 1 do begin
      build_tool(pas_tools[i], true);

      if(quitOnFail) and (fail_count > 0) then
         exit;
   end;
end;

procedure buildSymbolParameters();
var
   i: loopint;

begin
   SetLength(symbolParameters, build.Symbols.n * 2);

   if(build.Symbols.n > 0) then begin
      for i := 0 to build.Symbols.n - 1 do begin
         symbolParameters[i * 2 + 0] := '-d';
         symbolParameters[i * 2 + 1] := build.Symbols.List[i];
      end;
   end;
end;

procedure processParameters();
var
   cur: string;

begin
   build.GetSymbolParameters();

   parameters.Reset();

   repeat
      cur := parameters.Next();

      {ignore symbol defines}
      if(cur = '-d') then
         parameters.Next()
         {ignore symbol defines}
      else if(cur = '-no-quit') then begin
         log.w('Quit on failure is disabled');
         quitOnFail := false;
      end else if(cur = '-clean') then begin
         log.v('Will do a clean build');
         cleanBuild := true;
      end else begin
         {whatever is left is our target}
         if(build_what = '') and (cur <> 'setup.pas') then begin
            build_what := cur;
            log.i('Target set: ' + build_what);
         end else
            log.w('Extra unknown parameter: ' + cur);
      end;
   until parameters.IsEnd();
end;

BEGIN
   setupTimer.Start();
   build.Initialize();

   if(not build.Initialized) then begin
      if(build.ConfigPath = 'default') then begin
         log.w('Configuration path doesn''t seem set, will attempt to set one');
         BuildConfiguration.AutoDetermineConfigPath();
         BuildConfiguration.SaveLocationConfiguration();

         log.w('Attempt to reinitialize build');
         build.Initialize();
      end;

      if(not build.Initialized) then
         fail('Build system not initialized. Cannot perform setup.');
   end;

   lpi.Initialize();
   if(not lpi.Initialized) then
      fail('Failed to initialize lpi build system');

   {output all units into a single directory to speed up the process}
   build.FPCOptions.UnitOutputPath := IncludeTrailingPathDelimiterNonEmpty(GetCurrentDir) + 'lib';

   processParameters();

   if(cleanBuild) then begin
      log.i('Removing: ' + build.FPCOptions.UnitOutputPath);
      FileUtils.RmDir(build.FPCOptions.UnitOutputPath);
   end;

   build_tools();

   log.i();

   if (build_count > 0) or (fail_count > 0) then
      log.i(sf(build_count) + ' succeeded, ' + sf(fail_count) + ' failed');

   if(quitOnFail) and (fail_count > 0) then
      fail('Quitting due to one or more failures');

   buildSymbolParameters();

   if(can_build('oxed') or can_build('ox')) then begin
      path := '..' + DirectorySeparator + 'oX' + DirectorySeparator + 'setup' + DirectorySeparator;

      log.w('Setting up oX at: ' + path);

      if(SetCurrentDir(path)) then begin
         log.v('At: ' + GetCurrentDir());

         BuildExec.Laz('setup');
         log.i();

         if(BuildExec.Output.Success) then
            ProcessHelpers.RunCommandCurrentDir('setup', parameters.GetArray());
      end else
         log.e('Failed to change current working directory to: ' + path);
   end;

   setupTimer.Update();
   log.w('Elapsed: ' + setupTimer.ElapsedfToString() + 's');
END.
