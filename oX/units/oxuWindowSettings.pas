{
   oxuWindowSettings, oX window settings
   Copyright (c) 2017. Dejan Boras

   Started On:    28.02.2017.
}

{$INCLUDE oxdefines.inc}
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
   dvFullscreen,
   dvWindowedFullscreen: TDVar;

{ oxTWindowSettings }

procedure oxTWindowSettings.Load(w: oxTWindow);
begin
   if(Dimensions.w <= 0) or (Dimensions.h <= 0) then
      Dimensions.Assign(640, 480);

   w.Dimensions := Dimensions;
   w.oxProperties.Fullscreen := Fullscreen;
   w.oxProperties.WindowedFullscreen := WindowedFullscreen;
end;

procedure oxTWindowSettings.Read(w: oxTWindow);
begin
   Dimensions.w := w.Dimensions.w;
   Dimensions.h := w.Dimensions.h;
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
      dvFullscreen.Update(selected^.Fullscreen);
      dvWindowedFullscreen.Update(selected^.WindowedFullscreen);
   end;
end;

procedure dvIndexNotify({%H-}p: PDVar; {%H-}what: longword);
begin
   adjustVariables();
end;

procedure dvSaveHandler(var df: dvarTFileData; const parent: StdString);
var
   i: longint;

begin
   for i := 0 to (oxWindowSettings.n - 1) do begin
      dvIndex.Assign(i);

      df.Write(parent, dvgWindow);
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
   dvgWindow.Add(dvFullscreen, 'fullscreen', dtcBOOL, @oxWindowSettings.w[0].Fullscreen);
   dvgWindow.Add(dvWindowedFullscreen, 'windowed_fullscreen', dtcBOOL, @oxWindowSettings.w[0].WindowedFullscreen);

   dvarf.OnSave.Add(@dvgWindow, @dvSaveHandler);

   oxWindowSettings.AllocateCount := 1;
   initializeSettings();
END.
