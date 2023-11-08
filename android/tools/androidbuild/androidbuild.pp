{
   androidbuild, a helper tool for building android programs

   Started On:    03.02.2012.
}

{$MODE OBJFPC}{$H+}
PROGRAM androidbuild;

   USES sysutils, ConsoleUtils, StringUtils, uFileUtils;

CONST
   {$INCLUDE config.inc}

VAR
   selfparameters: string;

procedure Execute();
var
   path, configlocation, parameters: string;
   errorCode: longint;

begin
   path              := COMPILER_LOCATION;
   configlocation    := COMPILER_CONFIG_LOCATION;

   FileUtils.NormalizePath(path);
   FileUtils.NormalizePath(configlocation);

   { construct parameters }
   parameters := COMPILER_PARAMETERS + '-n @'+configlocation+' ' + ' "-FU'+ DEFAULT_OUTPUT_DIRECTORY + '" ' + selfparameters;

   try
      errorCode := ExecuteProcess(path, parameters, []);
   except
      writeln('Error: Failed to execute ' + path);
   end;

   halt(errorCode);
end;

procedure PrepareOutputDirectory();
var
   path, subPath, currentPath: string;

begin
   path := DEFAULT_OUTPUT_DIRECTORY;
   if(path <> '') then begin
      FileUtils.NormalizePath(path);

      { create directories }
      currentPath := '';

      repeat
         subPath := CopyToDel(path, DirectorySeparator);
         if(currentPath = '') then
            currentPath := subPath
         else
            currentPath := currentPath + DirectorySeparator + subPath;

         {$I-}
         mkdir(currentPath);
         IOResult();
         {$I+}
      until (path = '');
   end;
end;

BEGIN
   console.GetParamsString(selfparameters);
   PrepareOutputDirectory();
   Execute();
END.
