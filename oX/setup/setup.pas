{$INCLUDE oxdefines.inc}
PROGRAM setup;

USES
   sysutils, uStd, uLog, ParamUtils, uFileUtils, uProcessHelpers,
   uBuild, uBuildLibraries, uBuildConfiguration, uBuildExec, uLPI;

{$R *.res}

TYPE
   TMode = (
      MODE_ALL,
      MODE_RESOURCES,
      MODE_OXED,
      MODE_OXED_LIBRARIES,
      MODE_OXED_BUILD
   );

VAR
   mode: TMode = MODE_ALL;

function isMode(specifiedMode: TMode; optional: boolean = false): boolean;
begin
   if(not optional) then
      Result := (mode = MODE_ALL) or (mode = specifiedMode)
   else
      Result := mode = specifiedMode;
end;

function isOXEDMode(specifiedMode: TMode): boolean;
begin
   Result := (mode = MODE_ALL) or (mode = MODE_OXED) or (mode = specifiedMode);
end;

BEGIN
   SetCurrentDir('..');
   log.v('Current working directory: ' + GetCurrentDir());

   build.Initialize();
   build.OptimizationLevel := build.GetOptimizationLevelByName('sse3');
   lpi.Initialize();

   if(parameters.FindFlag('oxed')) then
      mode := MODE_OXED;

   if(parameters.FindFlag('oxed-libraries')) then
      mode := MODE_OXED_LIBRARIES;

   if(parameters.FindFlag('oxed-build')) then
      mode := MODE_OXED_BUILD;

   if(parameters.FindFlag('resources')) then
      mode := MODE_RESOURCES;

   {build resources (optional)}
   if(isMode(MODE_RESOURCES, true)) then begin
      log.i('Building resources');
      ProcessHelpers.RunCommand('file2code', ['-pas', '-lf', 'data/internal/font/font.tga', 'units/resources/default_font.inc', 'default_font']);
      ProcessHelpers.RunCommand('file2code', ['-pas', '-lf', 'data/internal/default.tga', 'units/resources/default_texture.inc', 'default_texture']);
      log.i('Done building resources');
   end;

   {set up libraries}
   if(isOXEDMode(MODE_OXED_LIBRARIES)) then begin
      log.i('Setting up OXED Libraries');

      {$IFDEF WINDOWS}
      buildLibraries.Target := 'oxed' + DirectorySeparator;

      buildLibraries.CopyLibrary('oal_soft.dll', 'openal32.dll');
      buildLibraries.CopyLibrary('freetype-6.dll');
      {$ENDIF}

      log.i('Done setting up OXED libraries');
   end;

   {build OXED}
   if(isOXEDMode(MODE_OXED_BUILD)) then begin
      log.i('Building OXED');
      log.i('Done building OXED');

      BuildExec.Laz('oxed' + DirectorySeparator + 'oxed.lpi');
   end;
END.
