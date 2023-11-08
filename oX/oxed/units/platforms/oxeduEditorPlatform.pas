{
   oxeduEditorPlatform, editor build specifics
   Copyright (C) 2019. Dejan Boras

   Started On:    29.09.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduEditorPlatform;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED, oxeduPlatform, oxeduPlatformConfiguration;

TYPE
   { oxedTEditorPlatform }

   oxedTEditorPlatform = class(oxedTPlatform)
      constructor Create(); override;

      procedure Load(); override;
   end;

IMPLEMENTATION

{ oxedTEditorPlatform }

constructor oxedTEditorPlatform.Create();
begin
   inherited;

   Name := 'Editor';
   Id := 'editor';
   GlyphName := 'brands:61820';

   {editor platform is always enabled}
   Enabled := true;

   Configuration := oxedTPlatformConfiguration.Create();

   AddArchitecture('editor', 'editor');
end;

procedure oxedTEditorPlatform.Load();
begin
   {prevent disabling editor platform via config file}
   Enabled := true;
end;

procedure init();
begin
   oxedPlatforms.Add(oxedTEditorPlatform.Create());
end;

INITIALIZATION
   oxed.Init.Add('platform.editor', @init);

END.