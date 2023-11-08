{
   uBuildLibraries
   Copyright (C) 2019. Dejan Boras

   Started On:    13.01.2019.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uBuildLibraries;

INTERFACE

   USES
      uStd, uBuild;

TYPE
   { TBuildSystemLibraries }

   TBuildSystemLibraries = record
      public

      Source,
      Target: StdString;
      OptimizationLevel: longint;

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
   optimizationLevel: longint;

function getNewName(): StdString;
begin
   if(newName <> '') then
      Result := newName
   else
      Result := name;
end;

function getPath(): StdString;
begin
   Result := Libraries.Source + IncludeTrailingPathDelimiterNonEmpty(CurrentPlatform^.GetName());
end;

begin
   Result := false;
   optimizationLevel := Libraries.OptimizationLevel;
   usedSource := '';

   {find optimized library if one specified}
   if(Libraries.OptimizationLevel > 0) then begin
      optimizationLevel := Libraries.OptimizationLevel;

      repeat
         optimizationSource := getPath() +
            IncludeTrailingPathDelimiterNonEmpty(GetOptimizationLevelName(optimizationLevel)) + name;

         if(FileUtils.Exists(optimizationSource) > 0) then begin
            if(optimizationLevel <> Libraries.OptimizationLevel) then
               log.w('Could not find optimized library ' + name + ' at level ' +
                  GetOptimizationLevelNameHuman(Libraries.OptimizationLevel) + ', used ' +
                  GetOptimizationLevelNameHuman(optimizationLevel) + ' instead');

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
         for optimizationLevel := 1 to CurrentPlatform^.OptimizationLevels.n do begin
            usedSource := getPath() +
               IncludeTrailingPathDelimiterNonEmpty(GetOptimizationLevelName(optimizationLevel)) + name;

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

   if(FileUtils.Copy(usedSource, Libraries.Target + getNewName()) > 0) then begin
      log.k('Copied ' + getNewName() + ' library successfully');
      Result := true;
   end else
      log.e('Failed to copy library from ' + usedSource + ' to ' + Libraries.Target + getNewName());
end;

procedure initialize();
begin
   BuildLibraries.Source := Tools.Build + 'libraries' + DirectorySeparator;
end;

INITIALIZATION
   build.OnInitialize.Add(@initialize);

END.
