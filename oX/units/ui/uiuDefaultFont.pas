{
   uiuDefaultFont, default font for UI
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuDefaultFont;

INTERFACE

   USES
      uStd, uLog,
      {ox}
      oxuPaths, oxuFont, oxuRunRoutines, oxuGlobalInstances,
      oxuFreetypeFonts,
      {ui}
      oxuUI, uiuBase;

TYPE
   uiPDefaultFontManager = ^uiTDefaultFontManager;

   { uiTDefaultFontManager }

   uiTDefaultFontManager = record
      Path: StdString;
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
   assetPath: StdString;

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

{$IFNDEF OX_LIBRARY}
procedure initialize();
begin
   uiDefaultFont.Initialize();
end;

procedure deinitialize();
begin
   uiDefaultFont.Deinitialize();
end;

{$ELSE}
procedure initializeLibrary();
var
   instance: uiPDefaultFontManager;

begin
   instance := oxExternalGlobalInstances.FindInstancePtr('uiTDefaultFontManager');

   if(instance <> nil) then begin
      uiDefaultFont.Path := instance^.Path;
      uiDefaultFont.Size := instance^.Size;
      uiDefaultFont.Font := instance^.Font;
   end;
end;
{$ENDIF}

INITIALIZATION
   uiDefaultFont.Path := oxPaths.Fonts + 'Inconsolata.ttf';
   uiDefaultFont.Size := 12;

   oxGlobalInstances.Add('uiTDefaultFontManager', @uiDefaultFont);

   {$IFNDEF OX_LIBRARY}
   ui.InitializationProcs.Add('default_font', @initialize, @deinitialize);
   {$ELSE}
   ui.InitializationProcs.Add('default_font', @initializeLibrary);
   {$ENDIF}

END.
