{
   oxeduWindowsPlatform, windows platform build specifics
   Copyright (C) 2017. Dejan Boras

   Started On:    19.07.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduWindowsPlatform;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED, oxeduPlatform, oxeduPlatformConfiguration;

TYPE
   { oxedTWindowsPlatform }

   oxedTWindowsPlatform = class(oxedTPlatform)
      constructor Create(); override;
   end;

   { oxedTWin32PlatformArchitecture }

   oxedTWin32PlatformArchitecture = class(oxedTPlatformArchitecture)
      constructor Create(); override;
   end;

   { oxedTWin64PlatformArchitecture }

   oxedTWin64PlatformArchitecture = class(oxedTPlatformArchitecture)
      constructor Create(); override;
   end;

IMPLEMENTATION

{ oxedTWin32PlatformArchitecture }

constructor oxedTWin32PlatformArchitecture.Create();
begin
   Name := 'Windows 32';
   Architecture := 'x86';
   Platform := 'i386-win32';
end;

{ oxedTWin64PlatformArchitecture }

constructor oxedTWin64PlatformArchitecture.Create();
begin
   Name := 'Windows 64';
   Architecture := 'x86-64';
   Platform := 'i386-win64';
end;

{ oxedTWindowsPlatform }

constructor oxedTWindowsPlatform.Create();
begin
   inherited;

   Name := 'Windows';
   id := 'windows';
   GlyphName := 'brands:61818';

   Configuration := oxedTPlatformConfiguration.Create();

   AddArchitecture(oxedTWin32PlatformArchitecture.Create());
   AddArchitecture(oxedTWin64PlatformArchitecture.Create());
end;

procedure init();
begin
   oxedPlatforms.Add(oxedTWindowsPlatform.Create());
end;

INITIALIZATION
   oxed.Init.Add('platform.windows', @init);

END.
