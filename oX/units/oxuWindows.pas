{
   oxuWindows, oX windows management
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuWindows;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      {oX}
      uOX, oxuWindowTypes, oxuWindow, oxuGlobalInstances,
      oxuViewport, oxuRenderer, oxuWindowSettings,
      {$IFDEF OX_LIBRARY}
      oxuRenderers,
      {$ENDIF}
      {io}
      uiuWindowTypes, uiuControl;

CONST
   oxcMAXIMUM_WINDOWS               = 4;
   oxcMAX_WINDOW                    = oxcMAXIMUM_WINDOWS - 1;

   oxcCONTEXT_WINDOW_IDX            = -1;

TYPE
   oxPWindows = ^oxTWindows;

   { oxTWindows }

   oxTWindows = record
      {window list}
      n: loopint;
      w: array[-1..oxcMAXIMUM_WINDOWS - 1] of oxTWindow;

      {called when windows are being created}
      OnCreate,
      {called after windows are created}
      OnPostCreate: TProcedures;

      MaxWindowAllocate: loopint;
      {Indicate to the system if the screen is allowed to go into idle mode (turn off/screensaver)}
      AllowScreenIdle,
      {allow screen to go idle while we're paused or in a menu}
      AllowScreenIdleDuringMenu: boolean;

      {description of last error}
      LastErrorDescription: string;

      {list of external windows}
      ExternalWindows: uiTSimpleControlList;

      procedure Create();

      {window allocation}
      procedure Setup(var wnd: oxTWindow; const settings: oxTWindowSettings; contextWindow: boolean = false);
      procedure Setup();
      procedure Dispose(includePrimary: boolean = true);
      procedure DisposeExceptPrimary();

      {store configuration for each window}
      procedure StoreConfiguration();

      procedure Allocate(count: loopint);

      {create windows}
      function Initialize(): boolean;

      {set window as current}
      procedure SetCurrent(wnd: oxTWindow);

      {do we currently allow screen to go idle}
      function AllowedScreenIdle(): boolean;
   end;

VAR
   oxWindows: oxTWindows;
   {$IFDEF OX_LIBRARY}
   oxExternalWindows: oxPWindows;
   {$ENDIF}

IMPLEMENTATION


function oxTWindows.Initialize(): boolean;
var
   i: loopint;
   externalWindow: TObject = nil;

begin
   Result := false;

   {$IFDEF OX_LIBRARY}
   oxExternalWindows := oxExternalGlobalInstances^.FindInstancePtr('oxTWindows');

   if(oxExternalWindows = nil) then
      exit(false);

   oxWindowSettings.AllocateCount := oxExternalWindows^.ExternalWindows.n;
   if(oxWindowSettings.AllocateCount > 0) then begin
      {get the renderer from the first window}
      oxRenderers.vSelectedRenderer :=
         oxTRenderer(oxTWindow(oxExternalWindows^.ExternalWindows.List[0].oxwParent).Renderer).Name;

      log.v('Using external renderer: ' + oxRenderers.vSelectedRenderer);
      oxRenderers.SetRenderer();
   end else begin
      log.e('No external windows are set');
      exit(false);
   end;
   {$ENDIF}

   {validate allocate count}
   if(oxWindowSettings.AllocateCount <= 0) then
      oxWindowSettings.AllocateCount := 1;

   {call the callback procedure}
   OnCreate.Call();

   {allocate default window count if not already allocated}
   if(n = 0) then
      Allocate(oxWindowSettings.AllocateCount);

   {setup all the windows}
   Setup();

   {create all windows}
   if(n > 0) then begin
      for i := 0 to (n - 1) do begin
         oxWindow.Current := w[i];

         {$IFDEF OX_LIBRARY}
         if(oxExternalWindows <> nil) and (oxExternalWindows^.ExternalWindows.n > 0) then
            externalWindow := oxExternalWindows^.ExternalWindows.List[i];
         {$ENDIF}

         if(not oxWindow.CreateWindow(w[i], externalWindow)) then begin
            LastErrorDescription := w[i].ErrorDescription;

            exit;
         end;
      end;

      OnPostCreate.Call();

      log.i('Created ' + sf(n) + ' windows.');

      Result := true;
   end else
      log.e('Error: No windows were allocated.');
end;

procedure oxTWindows.Create();
begin
   MaxWindowAllocate := 1;
   AllowScreenIdleDuringMenu := true;

   ExternalWindows.InitializeValues(ExternalWindows);
end;

procedure oxTWindows.Setup(var wnd: oxTWindow; const settings: oxTWindowSettings; contextWindow: boolean = false);
begin
   wnd.Viewport.Initialize();

   if(not ox.LibraryMode) and (not ox.Mobile) then
      settings.Load(wnd);

   oxWindow.Init(wnd, contextWindow);
end;

procedure oxTWindows.Setup();
var
   i: loopint;

begin
   if(n > 0) then begin
      {initialize uninitialized windows}
      for i := 0 to (n - 1) do begin
         Setup(w[i], oxWindowSettings.w[i]);
         w[i].Index := i;

         if(i > 0) then
            w[i].Title := w[i].Title + ' (' + sf(i) + ')';
      end;

      if(oxWindow.Current = nil) then
         oxWindow.Current := w[0];
   end;
end;

procedure oxTWindows.Dispose(includePrimary: boolean);
var
   i: loopint;

begin
   if(n > 0) then begin
      for i := Low(w) to High(w) do begin
         if(not includePrimary) and (i = 0) then
            continue;

         if(w[i] <> nil) then begin
            if(not (uiwndpDISPOSED in w[i].Properties)) then
               oxWindow.Dispose(w[i]);

            FreeObject(w[i]);
         end;
      end;

      if(includePrimary) then
         n := 0
      else
         n := 1;
   end;
end;

procedure oxTWindows.DisposeExceptPrimary();
begin
   Dispose(false);
end;

procedure oxTWindows.StoreConfiguration();
var
   i: loopint;

begin
   for i := Low(w) to High(w) do begin
      if(w[i] <> nil) then
         oxWindowSettings.w[i].Read(w[i]);
   end;
end;

procedure oxTWindows.Allocate(count: loopint);
var
   i: loopint;

begin
   {make sure we are not given some maniacal amount of windows}
   if(count > oxcMAXIMUM_WINDOWS) then
      count := oxcMAXIMUM_WINDOWS;

   if(count > MaxWindowAllocate) then
      count := MaxWindowAllocate;

   if(count > 0) then begin
      n := count;
      oxWindowSettings.n := count;

      {initialize uninitialized windows}
      for i := 0 to (n - 1) do
         w[i] := oxRenderer.WindowInstance.Create();
   end;

   oxWindowSettings.AllocateCount := count;
end;

procedure oxTWindows.SetCurrent(wnd: oxTWindow);
begin
   oxWindow.Current := wnd;
end;

function oxTWindows.AllowedScreenIdle(): boolean;
begin
   Result := false;

   if(oxWindows.AllowScreenIdle) then
      Result := true
   else if(oxWindows.AllowScreenIdleDuringMenu) then begin
      // TODO: Check if we're allowed to go idle
   end;
end;

INITIALIZATION
   oxGlobalInstances.Add('oxTWindows', @oxWindows);
   oxWindows.Create();

END.
