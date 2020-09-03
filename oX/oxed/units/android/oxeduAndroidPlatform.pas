{
   oxeduAndroidPlatform, android platform build specifics
   Copyright (C) 2019. Dejan Boras

   TODO: Add support for library paths
}

{$INCLUDE oxdefines.inc}
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

   oxedTAndroidPlatformArchitecture = class(oxedTPlatformArchitecture)
      {toolchain path within the ndk (only the distinct part for this arch) }
      ToolChainPath,
      {path in the ndk where we link to libraries (only the distinct part for this arch)}
      LibPath,
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
   platformToolchainPath: StdString = '';

   procedure completeArch(a: oxedTAndroidPlatformArchitecture; const archPath: StdString);
   begin
      {complete toolchain path}
      a.ToolChainPath := a.ToolChainPath + DirSep + 'prebuilt' + DirSep +
         platformToolchainPath + DirSep + 'bin';

      {complete lib path}
      a.LibPath := archPath + DirSep + 'usr' + DirSep + 'lib';
   end;

begin
   inherited;

   platformToolchainPath := '';

   {$IF DEFINED(WINDOWS)}
      {$IFDEF CPU64}
         platformToolchainPath := 'windows-x86_64';
      {$ELSE}
      platformToolchainPath := 'windows-x86';
      {$ENDIF}
   {$ELSEIF DEFINED(LINUX)}
      {$IFDEF CPU64}
      platformToolchainPath := 'linux-x86_&4';
      {$ELSE}
      platformToolchainPath := 'linux-x86';
      {$ENDIF}
   {$ENDIF}

   Name := 'Android';
   Id := 'android';
   OS := 'android';
   GlyphName := 'brands:61819';

   Configuration := oxedTPlatformConfiguration.Create();

   {arm}
   arch := oxedTAndroidPlatformArchitecture(
      AddArchitecture(oxedTAndroidPlatformArchitecture.Create('Android Arm x32', 'arm')));
   arch.DefaultFPUType := 'vfpv3_d16';
   arch.DefaultCPUType := 'armv7a';
   arch.BinUtilsPrefix := 'arm-linux-androideabi-';
   arch.ToolChainPath := 'arm-linux-androideabi-4.9';
   arch.LibTarget := 'armeabi-v7a';
   completeArch(arch, 'arm');

   {aarch64}
   arch := oxedTAndroidPlatformArchitecture(
      AddArchitecture(oxedTAndroidPlatformArchitecture.Create('Android Arm x64', 'aarch64')));
   arch.BinUtilsPrefix := 'aarch64-linux-android-';
   arch.ToolChainPath := 'aarch64-linux-android-4.9';
   arch.LibTarget := 'arm64-v8a';
   completeArch(arch, 'arm64');

   {x86}
   arch := oxedTAndroidPlatformArchitecture(
      AddArchitecture(oxedTAndroidPlatformArchitecture.Create('Android X86 x32', 'i386')));
   arch.BinUtilsPrefix := 'i686-linux-android-';
   arch.ToolChainPath := 'arm-linux-androideabi-4.9';
   arch.ToolChainPath := 'x86-4.9';
   arch.LibTarget := 'x86';
   completeArch(arch, 'x86');

   {x86-64}
   arch := oxedTAndroidPlatformArchitecture(
      AddArchitecture(oxedTAndroidPlatformArchitecture.Create('Android X86 x64', 'x86_64')));
   arch.BinUtilsPrefix := 'x86_64-linux-android-';
   arch.ToolChainPath := 'x86_64-4.9';
   arch.LibTarget := 'x86_64';
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
