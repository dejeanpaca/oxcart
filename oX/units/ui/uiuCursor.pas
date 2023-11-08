{
   uiuCursor, cursor management
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuCursor;

INTERFACE

   USES
      uStd,
      {app}
      appuMouse,
      {ox}
      uOX, oxuRunRoutines,
      oxuPlatform, oxuTexture, oxuTextureGenerate, oxuTypes, oxuTransform, oxuRender,
      {ui}
      oxuUI, uiuTypes, uiuControl, uiuWindowTypes, uiuDraw;

TYPE
   uiTLoadedCursors = specialize TSimpleList<uiTCursorType>;
   uiTCustomCursors = specialize TSimpleList<oxTTexture>;

   { uiTCursorGlobal }

   uiTCursorGlobal = record
      {already loaded system cursors}
      LoadedCursors: uiTLoadedCursors;
      {current cursor type}
      CurrentCursorType: uiTCursorType;
      {is custom cursor enabled currently}
      CustomCursor: loopint;

      {list of custom cursors}
      CustomCursors: uiTCustomCursors;
      {overriden cursor size, if non-zero this size is used instead of the texture size}
      CursorSize: oxTDimensions;

      {default cursor size}
      DefaultCursorSize: oxTDimensions;

      function LoadCursor(const fn: StdString): longword;

      procedure SetCustomCursor(cursor: LongWord);
      procedure SetCursorTypeForced(cursorType: uiTCursorType);
      procedure SetCursorType(control: uiTControl);
      procedure SetCursorType(cursorType: uiTCursorType);
   end;

VAR
   uiCursor: uiTCursorGlobal;

IMPLEMENTATION

{ uiTCursorGlobal }

function uiTCursorGlobal.LoadCursor(const fn: StdString): longword;
var
   t: oxTTexture = nil;
   error: loopint;

begin
   error := oxTextureGenerate.Generate(fn, t);
   if(t <> nil) and (error = 0) then begin
      CustomCursors.Add(t);

      exit(CustomCursors.n);
   end;

   result := 0;
end;

procedure uiTCursorGlobal.SetCustomCursor(cursor: LongWord);
begin
   CustomCursor := cursor;
   CursorSize := DefaultCursorSize;

   if(CustomCursor <> 0) then
      appm.Hide(nil);
end;

procedure uiTCursorGlobal.SetCursorTypeForced(cursorType: uiTCursorType);
begin
   if(LoadedCursors.Find(cursorType) < 0) then begin
      oxPlatform.LoadCursor(cursorType);
      LoadedCursors.Add(cursorType);
   end;

   CurrentCursorType := cursorType;
   oxPlatform.SetCursor(cursorType);

   if(CustomCursor <> 0) then
      appm.Show(nil);

   CustomCursor := 0;
   CursorSize := DefaultCursorSize;
end;

procedure uiTCursorGlobal.SetCursorType(control: uiTControl);
begin
   if(control.CustomCursorType = 0) then
      SetCursorType(control.CursorType)
   else
      SetCustomCursor(control.CustomCursorType);
end;

procedure uiTCursorGlobal.SetCursorType(cursorType: uiTCursorType);
begin
   if(CurrentCursorType = cursorType) then
      exit;

   SetCursorTypeForced(cursorType);
end;

procedure init();
begin
   uiCursor.SetCursorTypeForced(uiCURSOR_TYPE_DEFAULT);
end;

procedure deinit();
begin
   // TODO: Make sure to unload the cursors

   uiCursor.LoadedCursors.Dispose();
   uiCursor.CustomCursors.Dispose();
end;

INITIALIZATION
   uiCursor.CurrentCursorType := uiCURSOR_TYPE_DEFAULT;
   ox.Init.Add('ui.cursor', @init, @deinit);

   uiCursor.LoadedCursors.Initialize(uiCursor.LoadedCursors);
   uiCursor.CustomCursors.Initialize(uiCursor.CustomCursors);

END.
