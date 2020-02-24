{
   oxeduLinuxPlatform, linux platform build specifics
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduLinuxPlatform;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED, oxeduPlatform, oxeduPlatformConfiguration;

TYPE
   { oxedTLinuxPlatform }

   oxedTLinuxPlatform = class(oxedTPlatform)
      constructor Create(); override;
   end;

   { oxedTLinux32PlatformArchitecture }

   oxedTLinux32PlatformArchitecture = class(oxedTPlatformArchitecture)
      constructor Create(); override;
   end;

   { oxedTLinux64PlatformArchitecture }

   oxedTLinux64PlatformArchitecture = class(oxedTPlatformArchitecture)
      constructor Create(); override;
   end;


IMPLEMENTATION

{ oxedTLinux64PlatformArchitecture }

constructor oxedTLinux64PlatformArchitecture.Create();
begin
   Name := 'Linux 32';
   Architecture := 'x86';
   Platform := 'i386-linux';
end;

{ oxedTLinux32PlatformArchitecture }

constructor oxedTLinux32PlatformArchitecture.Create();
begin
   Name := 'Linux 64';
   Architecture := 'x86';
   Platform := 'x86_64-linux';
end;

{ oxedTLinuxPlatform }

constructor oxedTLinuxPlatform.Create();
begin
   inherited;

   Name := 'Linux';
   Id := 'linux';
   GlyphName := 'brands:61820';

   Configuration := oxedTPlatformConfiguration.Create();

   AddArchitecture(oxedTLinux32PlatformArchitecture.Create());
   AddArchitecture(oxedTLinux64PlatformArchitecture.Create());
end;

procedure init();
begin
   oxedPlatforms.Add(oxedTLinuxPlatform.Create());
end;

INITIALIZATION
   oxed.Init.Add('platform.linux', @init);

END.
