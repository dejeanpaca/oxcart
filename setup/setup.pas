{
   Deploys the workspace into a workable state. Builds certain often used tools.
}
{$MODE OBJFPC}{$H+}
PROGRAM setup;

   USES
      sysutils, uStd, StringUtils, uLog, uFiles, uFileUtils, uBuild, uLPI, uTest, appuPaths, ParamUtils, uTiming;

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

function can_build(const specific: string): boolean;
begin
  {build if specified this, or nothing specified}
  result := ((specific = build_what) or (build_what = '')) and (specific <> '');

  if(result) then
     log.w('Building: ' + specific);
end;

procedure build_tool(var tool: TTool; pas: boolean);
begin
   if can_build(tool.Name) then begin
      if pas then
         build.PasTool(tool.Path)
      else begin
         if(FileUtils.Exists(tool.Path + '.lpi') > 0) then
            build.LazTool(tool.Path)
         else begin
            if(FileUtils.Exists(tool.Path + '.pas') > 0) then
               lpibuild.BuildFromPas(tool.Path + '.pas')
            else if(FileUtils.Exists(tool.Path + '.pp') > 0) then
               lpibuild.BuildFromPas(tool.Path + '.pp')
            else if(FileUtils.Exists(tool.Path + '.pp') > 0) then
               log.w('Not found an appropriate file for: ' + tool.Path);
         end;
      end;

      if build.output.success then begin
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
   log.v('FPC: ' + build.GetPlatform()^.FpcPath);
   log.v('Lazarus: ' + build.lazarusPath);
   log.v('');

   for i := 0 to length(laz_tools) - 1 do
      build_tool(laz_tools[i], false);

   for i := 0 to length(pas_tools) - 1 do
      build_tool(pas_tools[i], true);
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
      else begin
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
   timer.Start();

   build.Initialize();
   if(not build.Initialized) then begin
      if(build.ConfigPath = 'default') then begin
         log.w('Configuration path doesn''t seem set, will attempt to set one');
         build.AutoDetermineConfigPath();
         build.SaveLocationConfiguration();

         log.w('Attempt to reinitialize build');
         build.Initialize();
      end;

      if(not build.Initialized) then begin
         log.e('Build system not initialized. Cannot perform setup.');
         halt(1);
      end;
   end;

   lpi.Initialize();

   processParameters();

   build_tools();
   log.i();

   if (build_count > 0) or (fail_count > 0) then
      log.i(sf(build_count) + ' succeeded, ' + sf(fail_count) + ' failed');

   buildSymbolParameters();

   if(can_build('oxed') or can_build('ox')) then begin
      path := '..' + DirectorySeparator + 'oX' + DirectorySeparator + 'setup' + DirectorySeparator;
      log.w('Setting up oX at: ' + path);

      if(SetCurrentDir(path)) then begin
         build.Laz('setup');
         log.i();

         if(build.Output.Success) then
            build.RunCommandCurrentDir('setup', parameters.GetArray());
      end else
         log.e('Failed to change current working directory to: ' + path);
   end;

   timer.Update();
   log.w('Elapsed: ' + sf(timer.Elapsedf(), 2) + 's');
END.

