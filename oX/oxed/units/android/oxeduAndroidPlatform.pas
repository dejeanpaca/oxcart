{
   oxeduAndroidPlatform, android platform build specifics
   Copyright (C) 2019. Dejan Boras

   TODO: Add support for library paths
}

{$INCLUDE oxheader.inc}
UNIT oxeduAndroidPlatform;

INTERFACE

   USES
      uStd, udvars,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED, oxeduPlatform, oxeduPlatformConfiguration, oxeduAndroidSettings;

TYPE
   { oxedTAndroidPlatform }

   oxedTAndroidPlatform = class(oxedTPlatform)
      constructor Create(); override;

      procedure ProjectReset(); override;
      function GetDvarGroup(): PDVarGroup; override;
   end;

   { oxedTAndroidPlatformArchitecture }

   oxedTAndroidPlatformArchitecture = class(oxedTPlatformArchitecture)
      {toolchain path prefix within the ndk (only the distinct part for this arch) }
      ToolChainPathPrefix,
      {target folder for libraries within android project files for this architecture
      (only folder name for the arch, not the whole path)}
      LibTarget: StdString;
   end;

VAR
   oxedAndroidPlatform: oxedTAndroidPlatform;

IMPLEMENTATION

{ oxedTAndroidPlatform }

constructor oxedTAndroidPlatform.Create();
var
   arch: oxedTAndroidPlatformArchitecture;

   procedure completeArch(a: oxedTAndroidPlatformArchitecture; const archPath: StdString);
   begin
      {set extensions}
      a.LibraryExtension := '.so';
      a.LibraryPrefix := 'lib';
   end;

begin
   inherited;

   Name := 'Android';
   Id := 'android';
   OS := 'android';
   GlyphName := 'brands:61819';

   Symbols.Add('GLES');

   RequireCMEM := true;
   SupportsExternalDebugSymbols := false;
   ExcludeDefaultLibraryPath := true;

   Configuration := oxedTPlatformConfiguration.Create();

   {arm}
   arch := oxedTAndroidPlatformArchitecture(
      AddArchitecture(oxedTAndroidPlatformArchitecture.Create('Android Arm x32', 'arm')));
   arch.DefaultFPUType := 'vfpv3_d16';
   arch.DefaultCPUType := 'armv7a';
   arch.BinUtilsPrefix := 'arm-linux-androideabi-';
   arch.ToolChainPathPrefix := 'arm-linux-androideabi-4.9';
   arch.LibTarget := 'arm-linux-androideabi';
   completeArch(arch, 'arm');

   {aarch64}
   arch := oxedTAndroidPlatformArchitecture(
      AddArchitecture(oxedTAndroidPlatformArchitecture.Create('Android Arm x64', 'aarch64')));
   arch.BinUtilsPrefix := 'aarch64-linux-android-';
   arch.ToolChainPathPrefix := 'aarch64-linux-android-4.9';
   arch.LibTarget := 'aarch64-linux-android';
   completeArch(arch, 'arm64');

   {x86}
   arch := oxedTAndroidPlatformArchitecture(
      AddArchitecture(oxedTAndroidPlatformArchitecture.Create('Android X86 x32', 'i386')));
   arch.BinUtilsPrefix := 'i686-linux-android-';
   arch.ToolChainPathPrefix := 'arm-linux-androideabi-4.9';
   arch.LibTarget := 'i686-linux-android';
   arch.DefaultCPUType := 'PENTIUM4';
   arch.DefaultFPUType := 'SSE3';
   completeArch(arch, 'x86');

   {x86-64}
   arch := oxedTAndroidPlatformArchitecture(
      AddArchitecture(oxedTAndroidPlatformArchitecture.Create('Android X86 x64', 'x86_64')));
   arch.BinUtilsPrefix := 'x86_64-linux-android-';
   arch.ToolChainPathPrefix := 'x86_64-4.9';
   arch.LibTarget := 'x86_64-linux-android';
   completeArch(arch, 'x86_64');
end;

procedure oxedTAndroidPlatform.ProjectReset();
begin
   oxedAndroidSettings.ProjectReset();
end;

function oxedTAndroidPlatform.GetDvarGroup(): PDVarGroup;
begin
   Result := @oxedAndroidSettings.Project.dvg;
end;

procedure init();
begin
   oxedAndroidPlatform := oxedTAndroidPlatform.Create();
   oxedPlatforms.Add(oxedAndroidPlatform);
end;

INITIALIZATION
   oxed.Init.Add('platform.android', @init);

END.
