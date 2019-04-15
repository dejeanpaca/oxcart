{
   uiuCursor, cursor management
   Copyright (C) 2017. Dejan Boras

   Started On:    03.03.2017.
}

{$INCLUDE oxdefines.inc}
UNIT uiuCursor;

INTERFACE

   USES
      uStd, uInit,
      {app}
      appuMouse,
      {ox}
      uOX, oxuRunRoutines,
      oxuPlatform, oxuTexture, oxuTextureGenerate, oxuTypes, oxuTransform, oxuRender,
      oxuRenderUtilities,
      {ui}
      oxuUI, uiuTypes, uiuControl, uiuWindow, uiuWindowTypes;

TYPE
   uiTLoadedCursors = specialize TPreallocatedArrayList<uiTCursorType>;
   uiTCustomCursors = specialize TPreallocatedArrayList<oxTTexture>;

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

      function LoadCursor(const fn: string): longword;

      procedure SetCustomCursor(cursor: LongWord);
      procedure SetCursorTypeForced(cursorType: uiTCursorType);
      procedure SetCursorType(control: uiTControl);
      procedure SetCursorType(cursorType: uiTCursorType);
   end;

VAR
   uiCursor: uiTCursorGlobal;

IMPLEMENTATION

{ uiTCursorGlobal }

function uiTCursorGlobal.LoadCursor(const fn: string): longword;
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

procedure renderCursor({%H-}wnd: uiTWindow);
var
   size: oxTDimensions;
   tex: oxTTexture;

begin
   if(uiCursor.CustomCursor > 0) and (uiCursor.CustomCursor <= uiCursor.CustomCursors.n) then begin
      tex := uiCursor.CustomCursors.List[uiCursor.CustomCursor - 1];
      if(tex.rId = 0) then
         exit;

      {get size from texture or from overriden size}
      if(uiCursor.CursorSize.w > 0) then
         size.w := uiCursor.CursorSize.w
      else
         size.w := tex.Width;

      if(uiCursor.CursorSize.h > 0) then
         size.h := uiCursor.CursorSize.h
      else
         size.h := tex.Height;

      {move into position}
      oxTransform.Identity();
      oxTransform.Translate(oxui.mSelect.startPoint.x + (size.w / 2), oxui.mSelect.startPoint.y - (size.h / 2), 0);
      oxTransform.Scale(size.w / 2, size.h / 2, 0);
      oxTransform.Apply();

      {bind texture}
      oxRender.EnableBlend();
      oxui.Material.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);
      oxRenderingUtilities.StartQuad(tex);
      oxRenderingUtilities.Quad();

      oxTransform.Identity();
      oxTransform.Apply();
   end;
end;

procedure init();
begin
   uiCursor.SetCursorTypeForced(uiCURSOR_TYPE_DEFAULT);

   uiWindow.OxwPostRender.Add(@renderCursor);
end;

procedure deinit();
begin
   // TODO: Make sure to unload the cursors

   uiCursor.LoadedCursors.Dispose();
   uiCursor.CustomCursors.Dispose();
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   uiCursor.CurrentCursorType := uiCURSOR_TYPE_DEFAULT;
   ox.Init.Add(initRoutines, 'ui.cursor', @init, @deinit);

   uiCursor.LoadedCursors.Initialize(uiCursor.LoadedCursors);
   uiCursor.CustomCursors.Initialize(uiCursor.CustomCursors);

END.
