{
   uiuDefaultFont, default font for UI
   Copyright (C) 2019. Dejan Boras

   Started On:    04.04.2019.
}

{$INCLUDE oxdefines.inc}
UNIT uiuDefaultFont;

INTERFACE

   USES
      uStd, uLog,
      {ox}
      oxuPaths, oxuFont, oxuRunRoutines,
      oxuUI, oxuFreetypeFonts;

TYPE
   { uiTDefaultFontManager }

   uiTDefaultFontManager = record
      Path: string;
      Size: loopint;
      Font: oxTFont;

      procedure Initialize();
      procedure Deinitialize();
   end;

VAR
   uiDefaultFont: uiTDefaultFontManager;

IMPLEMENTATION

{ uiTDefaultFontManager }

procedure uiTDefaultFontManager.Initialize();
var
   assetPath: String;

begin
   assetPath := oxPaths.Find(Path);
   Font := oxFreetypeManager.CreateFont(assetPath, Size);

   if(Font <> nil) then
      log.v('ui > Loaded default font: ' + assetPath)
   else
      log.w('ui > Failed to load default font: ' + assetPath);

   oxui.SetDefaultFont(Font);
end;

procedure uiTDefaultFontManager.Deinitialize();
begin
   if(Font <> nil) then begin
      FreeObject(Font);
      log.v('ui > Destroyed default font')
   end;
end;

procedure initialize();
begin
   uiDefaultFont.Initialize();
end;

procedure deinitialize();
begin
   uiDefaultFont.Deinitialize();
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   uiDefaultFont.Path := oxPaths.Fonts + 'Inconsolata.ttf';
   uiDefaultFont.Size := 12;

   oxui.InitializationProcs.Add(initRoutines, 'default_font', @initialize, @deinitialize);

END.
