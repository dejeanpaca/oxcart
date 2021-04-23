{
   oxuWindowSettings, oX window settings
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuWindowSettings;

INTERFACE

   USES
      uOX, uStd, udvars, dvaruFile,
      {oX}
      oxuTypes, oxuWindowTypes;

TYPE
   oxPWindowSettings = ^oxTWindowSettings;

   { oxTWindowSettings }

   oxTWindowSettings = record
      FullscreenDimensions,
      Dimensions: oxTDimensions;

      Fullscreen,
      WindowedFullscreen: boolean;

      {load settings into a window}
      procedure Load(w: oxTWindow);
      {read settings from a window}
      procedure Read(w: oxTWindow);
   end;

   oxTWindowSettingsGlobal = record
      AllocateCount: longint;

      w: array[-1..oxcMAXIMUM_WINDOWS - 1] of oxTWindowSettings;
      {window count}
      n: longint;
   end;

VAR
   oxWindowSettings: oxTWindowSettingsGlobal;

IMPLEMENTATION

{ DVAR SUPPORT }
VAR
   vIndex: longint;

   dvgWindows,
   dvgWindow: TDVarGroup;

   dvCount,
   dvIndex,
   dvWidth,
   dvHeight,
   dvFSWidth,
   dvFSHeight,
   dvFullscreen,
   dvWindowedFullscreen: TDVar;

{ oxTWindowSettings }

procedure oxTWindowSettings.Load(w: oxTWindow);
begin
   if(Dimensions.w <= 0) or (Dimensions.h <= 0) then
      Dimensions.Assign(640, 480);

   if(w.oxProperties.Fullscreen) then
      w.Dimensions := FullscreenDimensions
   else
      w.Dimensions := Dimensions;

   w.oxProperties.Fullscreen := Fullscreen;
   w.oxProperties.WindowedFullscreen := WindowedFullscreen;
end;

procedure oxTWindowSettings.Read(w: oxTWindow);
begin
   Dimensions := w.Dimensions;

   if(w.oxProperties.Fullscreen) then begin
      FullscreenDimensions := w.Dimensions;
      Dimensions := w.FullscreenDimensions;
   end;

   Fullscreen := w.oxProperties.Fullscreen;
   WindowedFullscreen := w.oxProperties.WindowedFullscreen;
end;

function getSelectedWindowSettings(): oxPWindowSettings;
begin
   if(vIndex >= 0) and (vIndex < oxcMAXIMUM_WINDOWS) then
      result := @oxWindowSettings.w[vIndex]
   else
      result := nil;
end;

procedure adjustVariables();
var
   selected: oxPWindowSettings;

begin
   selected := getSelectedWindowSettings();

   if(selected <> nil) then begin
      dvWidth.Update(selected^.Dimensions.w);
      dvHeight.Update(selected^.Dimensions.h);
      dvFSWidth.Update(selected^.FullscreenDimensions.w);
      dvFSHeight.Update(selected^.FullscreenDimensions.h);
      dvFullscreen.Update(selected^.Fullscreen);
      dvWindowedFullscreen.Update(selected^.WindowedFullscreen);
   end;
end;

procedure dvIndexNotify(var {%H-}context: TDVarNotificationContext);
begin
   adjustVariables();
end;

procedure dvSaveHandler(var context: TDVarNotificationContext);
var
   i: longint;

begin
   if(context.What <> DVAR_NOTIFICATION_WRITE) then
      exit;

   context.Result := 0;

   for i := 0 to (oxWindowSettings.n - 1) do begin
      dvIndex.Assign(i);

      dvarPFileData(context.f)^.Write(context.Parent, dvgWindow);
   end;
end;

procedure initializeSettings();
var
   i: loopint;

begin
   for i := -1 to (oxcMAXIMUM_WINDOWS - 1) do begin
      ZeroOut(oxWindowSettings.w[i], SizeOf(oxTWindowSettings));

      oxWindowSettings.w[i].Dimensions.Assign(640, 480);
   end;
end;

INITIALIZATION
   ox.dvar.Add('windows', dvgWindows);
   dvgWindows.Add(dvCount, 'count', dtcINT32, @oxWindowSettings.AllocateCount);

   ox.dvar.Add('window', dvgWindow);
   dvgWindow.Add(dvIndex, 'index', dtcINT32, @vIndex);
   dvIndex.pNotify := @dvIndexNotify;

   dvgWindow.Add(dvWidth, 'width', dtcINT32, @oxWindowSettings.w[0].Dimensions.w);
   dvgWindow.Add(dvHeight, 'height', dtcINT32, @oxWindowSettings.w[0].Dimensions.h);
   dvgWindow.Add(dvFSWidth, 'fullscreen_width', dtcINT32, @oxWindowSettings.w[0].FullscreenDimensions.w);
   dvgWindow.Add(dvFSHeight, 'fullscreen_height', dtcINT32, @oxWindowSettings.w[0].FullscreenDimensions.h);
   dvgWindow.Add(dvFullscreen, 'fullscreen', dtcBOOL, @oxWindowSettings.w[0].Fullscreen);
   dvgWindow.Add(dvWindowedFullscreen, 'windowed_fullscreen', dtcBOOL, @oxWindowSettings.w[0].WindowedFullscreen);

   dvgWindow.pNotify := @dvSaveHandler;

   oxWindowSettings.AllocateCount := 1;
   initializeSettings();
END.
