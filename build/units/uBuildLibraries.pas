{
   uBuildLibraries
   Copyright (C) 2020. Dejan Boras

   Started On:    13.01.2020.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uBuildLibraries;

INTERFACE

   USES
      uStd, uLog, StringUtils, uFileUtils,
      uBuild;

TYPE
   { TBuildSystemLibraries }

   TBuildSystemLibraries = record
      public

      Source,
      Target: StdString;

      {copy a library with the given name from source to target (set in Libraries)}
      function CopyLibrary(const name: StdString; const newName: StdString = ''): boolean;
   end;

VAR
   buildLibraries: TBuildSystemLibraries;

IMPLEMENTATION

function TBuildSystemLibraries.CopyLibrary(const name: StdString; const newName: StdString = ''): boolean;
var
   optimizationSource,
   usedSource: StdString;
   optimizationLevel: loopint;

function getNewName(): StdString;
begin
   if(newName <> '') then
      Result := newName
   else
      Result := name;
end;

function getPath(): StdString;
begin
   Result := Source + IncludeTrailingPathDelimiterNonEmpty(build.CurrentPlatform^.GetName());
end;

begin
   Result := false;
   optimizationLevel := build.OptimizationLevel;
   usedSource := '';

   {find optimized library if one specified}
   if(build.OptimizationLevel > 0) then begin
      optimizationLevel := build.OptimizationLevel;

      repeat
         optimizationSource := getPath() +
            IncludeTrailingPathDelimiterNonEmpty(build.GetOptimizationLevelName(optimizationLevel)) + name;

         if(FileUtils.Exists(optimizationSource) > 0) then begin
            if(optimizationLevel <> build.OptimizationLevel) then
               log.w('Could not find optimized library ' + name + ' at level ' +
                  build.GetOptimizationLevelNameHuman(build.OptimizationLevel) + ', used ' +
                  build.GetOptimizationLevelNameHuman(optimizationLevel) + ' instead');

            usedSource := optimizationSource;
            break;
         end;

         dec(optimizationLevel);
      until optimizationLevel < 0;

      if(optimizationLevel <= 0) then begin
         log.w('Could not find library ' + name + ' in ' + optimizationSource);
         usedSource := getPath() + name;
      end;
   end else
      usedSource := getPath() + name;

   if(FileUtils.Exists(usedSource) <= 0) then begin
      log.e('Could not find library ' + name + ' in ' + usedSource);

      usedSource := '';

      if(optimizationLevel <= 0) then begin
         for optimizationLevel := 1 to build.CurrentPlatform^.OptimizationLevels.n do begin
            usedSource := getPath() +
               IncludeTrailingPathDelimiterNonEmpty(build.GetOptimizationLevelName(optimizationLevel)) + name;

            if(FileUtils.Exists(usedSource) > 0) then begin
               log.w('Using optimized library: ' + usedSource + ' because regular not found');
               break;
            end else
               usedSource := '';
         end;
      end;

      if(usedSource = '') then begin
         log.e('Failed to find library: ' + name + ' in ' + getPath());
         exit(false);
      end;
   end;

   if(FileUtils.Copy(usedSource, Target + getNewName()) > 0) then begin
      log.k('Copied ' + getNewName() + ' library successfully');
      Result := true;
   end else
      log.e('Failed to copy library from ' + usedSource + ' to ' + Target + getNewName());
end;

procedure initialize();
begin
   BuildLibraries.Source := build.Tools.Build + 'libraries' + DirectorySeparator;
end;

INITIALIZATION
   build.OnInitialize.Add(@initialize);

END.
