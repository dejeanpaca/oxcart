{
   thirdparty

   Builds code for third party libraries. No need to build them every time, just initially
   and any time they're updated. The output should go to units/3rdparty.
   Intention is to get lower times on a full engine/project rebuild, and to get a more realistic
   lines of code count for engine/project.

   Started On: 23.09.2017.
}

{$MODE OBJFPC}{$H+}
PROGRAM thirdparty;

   USES
      uStd, uLog, uBuild, StringUtils, ConsoleUtils;

CONST
   unitList: array[0..3] of string = (
      'dglOpenGL/dglOpenGL.pas',
      'openal/openal.pas',
      'Vulkan/Vulkan.pas',
      'Vulkan/PasVulkan.pas'
   );

VAR
   source: string;

procedure build_units();
var
   i: loopint;

begin
   for i := 0 to High(unitList) do begin
      build.Pas(source + unitList[i]);
      log.i();
   end;
end;

BEGIN
   build.Initialize();
   if(not build.Initialized) then
      exit;

   build.GetSymbolParameters();

   build.FPCOptions.UnitOutputPath :=  '../units/3rdparty';
   ReplaceDirSeparators(build.FPCOptions.UnitOutputPath);
   build.SetDefaultSymbols();

   source := '../3rdparty/';

   build_units();
   {$IFDEF WINDOWS}
   build.Pas(source + 'dx/DX12.D3D11.pas');
   log.i();
   {$ENDIF}
END.
