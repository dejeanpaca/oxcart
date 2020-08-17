{
   oxuRenderers, oX renderers
   Copyright (C) 2013. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuRenderers;

INTERFACE

   USES
      StringUtils, uLog, uStd, udvars, ParamUtils,
      {ox}
      uOX, oxuRunRoutines, oxuRenderer;

CONST
   oxcMAX_RENDERERS  = 8;
   oxcMAX_RENDERER   = oxcMAX_RENDERERS - 1;

TYPE
   oxTRendererList = specialize TSimpleList<oxTRenderer>;

   { oxTRenderers }

   oxTRenderers = record
      StartedInitialization: boolean;

      vSelectedRenderer: StdString;
      OverrideRenderer: oxTRenderer;

      n: longint;
      Init: oxTRunRoutines;
      List: array[0..oxcMAX_RENDERER] of oxTRenderer;

      {routines called when the renderer is used}
      UseRoutines,
      {routines called after use routines}
      PostUseRoutines: TProcedures;
      {routines called on ox start}
      StartRoutines: TProcedures;

      procedure LogRenderers();
      procedure SetRenderer();

      procedure Initialize();
      procedure DeInitialize();

      procedure Startup();
      procedure PostContext();

      procedure Register(renderer: oxTRenderer);
      procedure SelectRenderer(renderer: oxTRenderer);
      procedure Use(renderer: oxTRenderer);

      {find the renderer by name}
      function Find(const name: StdString): oxTRenderer;
      {Give the index of the currently used renderer, or the specified one.
      Returns index if found, or -1 if nothing found}
      function CurrentIndex(renderer: oxTRenderer = nil): longint;
   end;

VAR
   oxRenderers: oxTRenderers;

IMPLEMENTATION

VAR
   dvRenderer: TDVar;

{ oxTRenderers }

procedure oxTRenderers.LogRenderers();
var
   i: longint;

begin
   {we'll assume 0 renderer is nil, and only report other renderers}

   if(n > 1) then begin
      log.Enter('Renderers (' + sf(n - 1) + ')');

      for i := 1 to (n - 1) do
         Log.i(List[i].Name);

      log.Leave();
   end else
      log.w('There are no renderers.');
end;

procedure oxTRenderers.SetRenderer();
var
   r: oxTRenderer;

begin
   if(OverrideRenderer = nil) then
      r := Find(vSelectedRenderer)
   else
      r := OverrideRenderer;

   {automatically select an appropriate renderer if one is selected from settings}
   if(r <> nil) then
      SelectRenderer(r)
   else begin
      {should not use nil as the default renderer if there is anything else}
      if(oxRenderer = oxNilRenderer) and (n > 1) then
         SelectRenderer(list[1])
      else
         SelectRenderer(list[0]);
   end;
end;

procedure oxTRenderers.Initialize();
var
   i: loopint;

begin
   StartedInitialization := true;
   LogRenderers();
   Log.Enter('Initializing renderers');
   Init.iCall();

   for i := 0 to (n - 1) do begin
      if(List[i].Id <> 'nil') then begin
         log.Collapsed(List[i].Name);
            List[i].Initialize();
            Log.i('Initialized');
         log.Leave();
      end else
         List[i].Initialize();
   end;

   Log.Leave();
end;

procedure oxTRenderers.DeInitialize();
var
   i: longint;

begin
   if(StartedInitialization) then begin
      StartedInitialization := false;

      log.Enter('De-initializing renderers');

      for i := 0 to (n - 1) do begin
         List[i].DeInitialize();
         List[i] := nil;
      end;

      Init.dCall();
      log.Leave();

      n := 0;
   end;
end;

procedure oxTRenderers.Startup();
begin
   StartRoutines.Call();
   oxRenderer.StartRoutines.Call();
end;

procedure oxTRenderers.PostContext();
var
   i: loopint;

begin
   for i := 0 to (n - 1) do begin
      {switch current settings to target settings}
      List[i].Settings := List[i].TargetSettings;
      List[i].PostContext();
   end;
end;

procedure oxTRenderers.Register(renderer: oxTRenderer);
begin
   if(renderer <> nil) then begin
      List[n] := renderer;
      inc(n);
   end;
end;

procedure oxTRenderers.SelectRenderer(renderer: oxTRenderer);
begin
   if(renderer <> nil) then
      oxRenderer := renderer
   else
      oxRenderer := oxNilRenderer;

   vSelectedRenderer := renderer.Name;
   log.i('Using renderer: ' + renderer.Name);
end;

procedure oxTRenderers.Use(renderer: oxTRenderer);
begin
   SelectRenderer(renderer);

   oxRenderer.Use();
   UseRoutines.Call();
   oxRenderer.UseRoutines.Call();
   oxRenderers.PostUseRoutines.Call();
end;

function oxTRenderers.Find(const name: StdString): oxTRenderer;
var
   i: longint;
   lname: StdString;

begin
   if(n > 0) then begin
      lname := LowerCase(name);

      for i := 0 to (n - 1) do begin
         if(LowerCase(List[i].Name) = lname) then
            exit(List[i]);
      end;
   end;

   Result := nil;
end;

function oxTRenderers.CurrentIndex(renderer: oxTRenderer): longint;
var
   i: loopint;

begin
   if(renderer = nil) then
      renderer := oxRenderer;

   if(renderer <> nil) then begin
      for i := 0 to (n - 1) do begin
         if(list[i] = renderer) then
            exit(i);
      end;
   end;

   Result := -1;
end;

VAR
   paramHandler: TParameterHandler;

function processParam(const {%H-}paramKey: StdString; var params: array of StdString; n: longint): boolean;
var
   name: StdString;
   renderer: oxTRenderer;

begin
   Result := false;

   if(n = 1) then begin
      name := LowerCase(params[0]);

      renderer := oxRenderers.Find(name);
      if(renderer <> nil) then begin
         oxRenderers.OverrideRenderer := renderer;
         log.i('Specified renderer: ' + renderer.Name);

         exit(true);
      end else
         log.w('Could not find renderer: ' + params[0]);
   end else
      log.e('Did not specify ' + paramHandler.ParamKey + ' parameter value');
end;

INITIALIZATION
   oxTRunRoutines.Initialize(oxRenderers.Init);

   TProcedures.Initialize(oxRenderers.UseRoutines);
   TProcedures.Initialize(oxRenderers.PostUseRoutines);
   TProcedures.Initialize(oxRenderers.StartRoutines);

   ox.dvar.Add(dvRenderer, 'renderer', dtcSTRING, @oxRenderers.vSelectedRenderer);

   parameters.AddHandler(paramHandler, 'ox.renderer', '-ox.renderer', @processParam);

END.
