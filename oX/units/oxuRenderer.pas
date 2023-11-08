{
   oxuRenderer, oX renderer
   Copyright (C) 2013. Dejan Boras
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
      SupportsThreading: boolean;

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
      function GetContext({%H-}wnd: oxTWindow; {%H-}shareContext: loopint = 0): loopint; virtual;
      function GetUnusedContext(): loopint; virtual;
      function GetContextString({%H-}index: loopint = 0): StdString; virtual;
      procedure ContextCurrent(context: loopint); virtual;
      procedure ClearContext(context: loopint); virtual;
      function DestroyContext({%H-}context: loopint): boolean; virtual;

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
      if(RenderingContexts[i].Window = nil) then begin
         log.i('Created rendering context ' + sf(i));

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
   Result := GetUnusedContext();

   if(Result < 0) then
      Result := AddRenderingContext(wnd);
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

procedure oxTRenderer.ContextCurrent(context: loopint);
begin
   if(context >= 0) then begin
      RenderingContexts[context].Used := true;
   end;
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

function instanceGlobal(): TObject;
begin
   Result := oxTRenderer.Create();
end;

INITIALIZATION
   oxGlobalInstances.Add(oxTRenderer, @oxRenderer, @instanceGlobal)^.Allocate := false;

END.
