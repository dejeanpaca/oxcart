{
   oxuRenderer, oX renderer
   Copyright (C) 2013. Dejan Boras

   TODO: Maybe sort out rendering context handling
}

{$INCLUDE oxheader.inc}
UNIT oxuRenderer;

INTERFACE

   USES
      uStd, uColors, uLog, uImage, uComponentProvider, StringUtils, vmVector,
      {oX}
      uOX, oxuTypes, oxuWindowTypes, oxuGlobalInstances, oxuPlatform, oxuRunRoutines,
      oxuRendererSettings;

TYPE
   { oxTRendererProperites }

   oxTRendererProperties = record
      {does this renderer support threading}
      SupportsThreading,
      {do we support render scaling}
      SupportsRenderScaling: boolean;

      Textures: record
         {does the renderer support power of 2 textures}
         Npot,
         {has a warning about power of 2 textures been issued}
         WarnedNpot: boolean;
      end;
   end;

   oxTRendererInitRoutine = procedure(wnd: oxTWindow);
   oxTRendererInitRoutines = specialize TSimpleList<oxTRendererInitRoutine>;

   { oxTRendererInitRoutinesHelper }

   oxTRendererInitRoutinesHelper = record helper for oxTRendererInitRoutines
      procedure Call(wnd: oxTWindow);
   end;

   { oxTRendererRenderingContext }
   oxTRendererRenderingContext = record
      Window: oxTWindow;
      Created,
      Used: boolean;
   end;

   { oxTRenderer }
   oxTRenderer = class
      public
         {renderer Id, always should start with 'renderer.'}
         Id,
         {user friendly name}
         Name: string;

         {window class to instance}
         WindowInstance: oxTWindowClass;
         PlatformInstance: TClass;

         Components: TComponentProvider;
         UseRoutines: TProcedures;
         StartRoutines: TProcedures;
         Init,
         AfterInit: oxTRunRoutines;
         OnWindowInit: oxTRendererInitRoutines;

         Properties: oxTRendererProperties;

         {flag to preserve RCs while destroying or recreating a window}
         PreserveRCs: boolean;
         RenderingContexts: array[0..oxMAXIMUM_RENDER_CONTEXT] of oxTRendererRenderingContext;

         {current renderer settings}
         Settings,
         {target settings}
         TargetSettings,
         {context window settings}
         ContextSettings: oxTRendererSettings;

         {$IFDEF OX_LIBRARY_SUPPORT}
         ExternalRenderer: oxTRenderer;
         {$ENDIF}

      constructor Create(); virtual;

      {initialize the renderer}
      procedure Initialize(); virtual;
      {deinitialize the renderer}
      procedure DeInitialize(); virtual;

      {after initialize the renderer}
      procedure AfterInitialize(); virtual;
      {after deinitialize the renderer}
      procedure AfterDeinitialize(); virtual;

      {initialize the renderer}
      procedure OnInitialize(); virtual;
      {deinitialize the renderer}
      procedure OnDeInitialize(); virtual;

      {called post context window creation}
      procedure PostContext(); virtual;

      { WINDOWS SETUP }

      {setup any data for the window}
      procedure SetupData({%H-}wnd: oxTWindow); virtual;
      {setup window itself}
      function SetupWindow({%H-}wnd: oxTWindow): boolean; virtual;
      {called when before window is created}
      function PreInitWindow({%H-}wnd: oxTWindow): boolean; virtual;
      {initialize system side of the window}
      function InitWindow({%H-}wnd: oxTWindow): boolean; virtual;
      {$IFDEF OX_LIBRARY}
      {initialize window when it runs in library mode (if required)}
      function InitWindowLibrary({%H-}wnd: oxTWindow): boolean; virtual;
      {$ENDIF}
      {initialize system side of the window}
      function DeInitWindow({%H-}wnd: oxTWindow): boolean; virtual;
      {log any window properties}
      procedure LogWindow({%H-}wnd: oxTWindow); virtual;

      {tells if this renderer needs a context window}
      function ContextWindowRequired(): boolean; virtual;

      { RENDERING }

      {swap window buffers}
      procedure SwapBuffers({%H-}wnd: oxTWindow); virtual;

      {add a new rendering context}
      function AddRenderingContext(wnd: oxTWindow): loopint;
      {remove a specified context}
      procedure RemoveContext(context: loopint);
      {check if the specified rendering context is already used}
      function RenderingContextUsed(context: loopint): boolean;
      {get context}
      function GetContext({%H-}wnd: oxTWindow; {%H-}shareContext: loopint = -1): loopint; virtual;
      function GetRenderingContext({%H-}wnd: oxTWindow; {%H-}shareContext: loopint = -1): loopint; virtual;
      function GetUnusedContext(): loopint; virtual;
      function GetContextString({%H-}index: loopint = 0): StdString; virtual;
      procedure ContextCurrent(const {%H-}context: oxTRenderTargetContext); virtual;
      procedure ContextCurrent(context: loopint; var {%H-}target: oxTRenderTarget);
      procedure ClearContext(context: loopint); virtual;
      function DestroyContext({%H-}context: loopint): boolean; virtual;

      function RenderingContextCount(): loopint;

      {destroy every rendering context}
      procedure DestroyAllRenderingContexts(wnd: oxTWindow);

      procedure StartThread({%H-}wnd: oxTWindow); virtual;
      procedure StopThread({%H-}wnd: oxTWindow); virtual;

      procedure SetProjectionMatrix(const {%H-}m: TMatrix4f); virtual;
      procedure Viewport({%H-}x, {%H-}y, {%H-}w, {%H-}h: longint); virtual;
      procedure Clear({%H-}clearBits: longword); virtual;
      procedure ClearColor({%H-}c: TColor4f); virtual;
      procedure ClearColor({%H-}r, g, b, a: single);

      { COMPONENTS }

      {get a component from the renderer}
      function GetComponent(const componentName: string): TObject;
      {find component}
      function FindComponent(const componentName: string): PSingleComponent;

      { GENERIC }

      function GetSummary(): TStringArray; virtual;
      {selects this renderer for use}
      procedure Use(); virtual;

      { THREAD LOGGING HELPERS }
      procedure logti(const what: StdString);
      procedure logtv(const what: StdString);
      procedure logtw(const what: StdString);
      procedure logte(const what: StdString);

      function GetThreadName(): string;
   end;

   oxTRendererClass = class of oxTRenderer;

VAR
   oxRenderer: oxTRenderer;
   oxNilRenderer: oxTRenderer;

IMPLEMENTATION

{ oxTRendererInitRoutinesHelper }

procedure oxTRendererInitRoutinesHelper.Call(wnd: oxTWindow);
var
   i: loopint;

begin
   for i := 0 to (n - 1) do
      List[i](wnd);
end;

{ oxTRenderer }

constructor oxTRenderer.Create();
begin
   WindowInstance := oxTWindow;
   TargetSettings := oxrTargetSettings;
   ContextSettings := oxrContextSettings;
   Settings := ContextSettings;
   PlatformInstance := oxTPlatform;

   {$IFNDEF NO_THREADS}
   Properties.SupportsThreading := true;
   {$ENDIF}
   Properties.SupportsRenderScaling := true;

   ComponentProvider.Initialize(Components);
   UseRoutines.Initialize(UseRoutines);
   StartRoutines.Initialize(StartRoutines);
   OnWindowInit.Initialize(OnWindowInit);
end;

procedure oxTRenderer.Initialize();
begin
   {$IFDEF OX_LIBRARY}
   ExternalRenderer := oxTRenderer(oxExternalGlobalInstances^.FindInstance('oxTRenderer'));
   {$ENDIF}

   OnInitialize();

   Init.iCall();
end;

procedure oxTRenderer.DeInitialize();
begin
   Init.dCall();

   OnDeInitialize();
end;

procedure oxTRenderer.AfterInitialize();
begin
   if(not ox.InitializationFailed) then
      AfterInit.iCall();
end;

procedure oxTRenderer.AfterDeinitialize();
begin
   AfterInit.dCall();
end;


procedure oxTRenderer.SetupData(wnd: oxTWindow);
begin
end;

function oxTRenderer.InitWindow(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

{$IFDEF OX_LIBRARY}
function oxTRenderer.InitWindowLibrary(wnd: oxTWindow): boolean;
begin
   Result := true;
end;
{$ENDIF}

function oxTRenderer.DeInitWindow(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

function oxTRenderer.SetupWindow(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

function oxTRenderer.PreInitWindow(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

procedure oxTRenderer.LogWindow(wnd: oxTWindow);
begin
end;

function oxTRenderer.ContextWindowRequired(): boolean;
begin
   Result := false;
end;

procedure oxTRenderer.OnInitialize();
begin

end;

procedure oxTRenderer.OnDeInitialize();
begin

end;

procedure oxTRenderer.PostContext();
begin

end;

procedure oxTRenderer.SwapBuffers(wnd: oxTWindow);
begin

end;

function oxTRenderer.AddRenderingContext(wnd: oxTWindow): loopint;
var
   i: loopint;

begin
   for i := 0 to oxMAXIMUM_RENDER_CONTEXT do begin
      if(not RenderingContexts[i].Created) then begin
         log.i('Created rendering context ' + sf(i));

         RenderingContexts[i].Created := true;
         RenderingContexts[i].Window := wnd;
         RenderingContexts[i].Used := false;
         exit(i);
      end;
   end;

   Result := -1;
end;

procedure oxTRenderer.RemoveContext(context: loopint);
begin
   if(context > -1) then begin
      RenderingContexts[context].Window := nil;
      RenderingContexts[context].Used := false;
      RenderingContexts[context].Created := false;

      log.i('Rendering context ' + sf(context) + ' destroyed');
   end;
end;

function oxTRenderer.RenderingContextUsed(context: loopint): boolean;
begin
   if(context >= 0) then
      exit(RenderingContexts[context].Used);

   Result := false;
end;

function oxTRenderer.GetContext(wnd: oxTWindow; shareContext: loopint): loopint;
begin
   Result := -1;
end;

function oxTRenderer.GetRenderingContext(wnd: oxTWindow; shareContext: loopint): loopint;
var
   rtc: oxTRenderTargetContext;

begin
   {get an unused context if we can first}
   Result := GetUnusedContext();

   if(Result < 0) then begin
      if(shareContext = -1) then begin
         {we always share a context with the first one}
         if(RenderingContexts[0].Window <> nil) then begin
            shareContext := 0;
         end;
      end;

      wnd.FromWindow(rtc);

      {sometimes, gl won't allow sharing lists or getting a context if we have one set currently}
      if(wnd.RenderingContext > -1) then
         ClearContext(wnd.RenderingContext);

      {get new context}
      Result := GetContext(wnd, shareContext);

      {restore the original context for this window}
      if(wnd.RenderingContext > -1) then
         ContextCurrent(rtc);
   end;
end;

function oxTRenderer.GetUnusedContext(): loopint;
var
   i: loopint;

begin
   for i := 0 to oxMAXIMUM_RENDER_CONTEXT do begin
      if(RenderingContexts[i].Window <> nil) and (not RenderingContexts[i].Used) then
         exit(i);
   end;

   Result := -1;
end;

function oxTRenderer.GetContextString(index: loopint): StdString;
begin
   Result := '';
end;

procedure oxTRenderer.ContextCurrent(const context: oxTRenderTargetContext);
begin
end;

procedure oxTRenderer.ContextCurrent(context: loopint; var target: oxTRenderTarget);
var
   rtc: oxTRenderTargetContext;

begin
   rtc.Target := @target;
   rtc.ContextType := oxRENDER_TARGET_CONTEXT_RENDER;
   rtc.RenderContext := context;

   ContextCurrent(rtc);
end;

procedure oxTRenderer.ClearContext(context: loopint);
begin
   if(context >= 0) then begin
      assert(RenderingContexts[context].Used = true, 'Rendering context ' + sf(context) + ' cleared more than once, or was not current before');
      RenderingContexts[context].Used := false;
   end;
end;

function oxTRenderer.DestroyContext(context: loopint): boolean;
begin
   RemoveContext(context);
   Result := true;
end;

function oxTRenderer.RenderingContextCount(): loopint;
var
   i: loopint;

begin
   Result := 0;

   for i := 0 to oxMAXIMUM_RENDER_CONTEXT do begin
      if(RenderingContexts[i].Created) then
         inc(Result);
   end;
end;

procedure oxTRenderer.DestroyAllRenderingContexts(wnd: oxTWindow);
var
   i: loopint;

begin
   for i := 0 to oxMAXIMUM_RENDER_CONTEXT do begin
      if(RenderingContexts[i].Window = wnd) then begin
         DestroyContext(i);
      end;
   end;
end;

procedure oxTRenderer.StartThread(wnd: oxTWindow);
begin
end;

procedure oxTRenderer.StopThread(wnd: oxTWindow);
begin

end;

procedure oxTRenderer.SetProjectionMatrix(const m: TMatrix4f);
begin

end;

procedure oxTRenderer.Viewport(x, y, w, h: longint);
begin

end;

procedure oxTRenderer.Clear(clearBits: longword);
begin

end;

procedure oxTRenderer.ClearColor(c: TColor4f);
begin
end;

procedure oxTRenderer.ClearColor(r, g, b, a: single);
var
   c: TColor4f;

begin
   c := TColor4f.Create(r, g, b, a);
   ClearColor(c);
end;

function oxTRenderer.GetComponent(const componentName: string): TObject;
var
   p: PSingleComponent;

begin
   p := FindComponent(componentName);

   if(p <> nil) then
      Result := p^.return()
   else
      Result := nil;
end;

function oxTRenderer.FindComponent(const componentName: string): PSingleComponent;
begin
   Result := Components.FindComponent(componentName);

   if(Result = nil) and (oxNilRenderer <> Self) then
      log.w('Requested component <' + componentName + '> not found for renderer ' + Name);
end;

function oxTRenderer.GetSummary(): TStringArray;
var
   list: array[0..0] of StdString;

begin
   list[0] := 'Renderer: ' + Name;
   Result := list;
end;

procedure oxTRenderer.Use();
begin
end;

procedure oxTRenderer.logti(const what: StdString);
begin
   consoleLog.i(Id + ' (t: ' + GetThreadName() + ')  ' + what);
end;

procedure oxTRenderer.logtv(const what: StdString);
begin
   consoleLog.v(Id + ' (t: ' + GetThreadName() + ') ' + what);
end;

procedure oxTRenderer.logtw(const what: StdString);
begin
   consoleLog.w(Id + ' (t: ' + GetThreadName() + ') ' + what);
end;

procedure oxTRenderer.logte(const what: StdString);
begin
   consoleLog.e(Id + ' (t: ' + GetThreadName() + ') ' + what);
end;

function oxTRenderer.GetThreadName(): string;
begin
   Result := HexStr(GetThreadID(), SizeOf(TThreadID) * 2);
end;

function instanceGlobal(): TObject;
begin
   Result := oxTRenderer.Create();
end;

INITIALIZATION
   oxGlobalInstances.Add(oxTRenderer, @oxRenderer, @instanceGlobal)^.Allocate := false;

END.
