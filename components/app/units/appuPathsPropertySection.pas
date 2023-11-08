{
   appuPathsPropertySection, paths property section
   Copyright (C) 2012. Dejan Boras

   Started On:    02.01.2012.
}

{$MODE OBJFPC}{$H+}
UNIT appuPathsPropertySection;

INTERFACE

   USES uPropertySection, appuPaths;

CONST
   APP_PATHS_PROPERTY_SECTION             = 'app_paths';

   APP_PATHS_PROP_STRING_PRESET_CONFIG    = 0001;
   APP_PATHS_PROP_STRING_CONFIG           = 0002;
   APP_PATHS_PROP_BOOL_CONFIG_CREATED     = 0001;

VAR
   appPathsPropertySection: TPropertySection;

IMPLEMENTATION

procedure setString(code: longint; const prop: string);
begin
   if(code = APP_PATHS_PROP_STRING_PRESET_CONFIG) then
      appPath.Configuration.Preset := prop
   else if(code = APP_PATHS_PROP_STRING_CONFIG) then
      appPath.Configuration.Path := prop;
end;

procedure setBoolean(code: longint; prop: boolean);
begin
   if(code = APP_PATHS_PROP_BOOL_CONFIG_CREATED) then
      appPath.Configuration.Created := prop;
end;

INITIALIZATION
   appPathsPropertySection             := propertySections.dummy;
   appPathsPropertySection.Name        := APP_PATHS_PROPERTY_SECTION;
   appPathsPropertySection.setString   := @setString;
   appPathsPropertySection.setBoolean  := @setBoolean;

   propertySections.Register(appPathsPropertySection);
END.
