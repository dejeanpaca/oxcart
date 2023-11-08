{
   oxuRenderers, oX renderers
   Copyright (C) 2013. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRenderers;

INTERFACE

   USES
      StringUtils, uLog, uStd, udvars,
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

      {log the list of renderers}
      procedure LogList();
      {set the configured renderer, or if none, use a default one}
      procedure SetInitial();

      procedure Initialize();
      procedure DeInitialize();

      procedure Startup();
      procedure PostContext();

      procedure Register(renderer: oxTRenderer);
      procedure Select(renderer: oxTRenderer);
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

procedure oxTRenderers.LogList();
var
   i: longint;

begin
   {we'll assume 0 renderer is nil, and only report other renderers}

   if(n > 1) then begin
      log.Enter('Renderers (' + sf(n - 1) + ')');

      for i := 1 to (n - 1) do
         log.i(List[i].Name);

      log.Leave();
   end else
      log.w('There are no renderers.');
end;

procedure oxTRenderers.SetInitial();
var
   r: oxTRenderer;

begin
   if(OverrideRenderer = nil) then
      r := Find(vSelectedRenderer)
   else
      r := OverrideRenderer;

   {automatically select an appropriate renderer if one is selected from settings}
   if(r <> nil) then
      Select(r)
   else begin
      {should not use nil as the default renderer if there is anything else}
      if(oxRenderer = oxNilRenderer) and (n > 1) then
         Select(list[1])
      else
         Select(list[0]);
   end;
end;

procedure oxTRenderers.Initialize();
var
   i: loopint;

begin
   StartedInitialization := true;
   LogList();
   log.Enter('Initializing renderers');
   Init.iCall();

   for i := 0 to (n - 1) do begin
      if(List[i].Id <> 'nil') then begin
         log.Collapsed(List[i].Name);
            List[i].Initialize();
            log.i('Initialized');
         log.Leave();
      end else
         List[i].Initialize();
   end;

   log.Leave();
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

procedure oxTRenderers.Select(renderer: oxTRenderer);
begin
   if(renderer <> nil) then
      oxRenderer := renderer
   else
      oxRenderer := oxNilRenderer;

   vSelectedRenderer := oxRenderer.Name;
   log.i('Selected renderer: ' + vSelectedRenderer);
end;

procedure oxTRenderers.Use(renderer: oxTRenderer);
begin
   oxRenderer := renderer;
   log.i('Using renderer: ' + renderer.Name);

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


INITIALIZATION
   oxTRunRoutines.Initialize(oxRenderers.Init);

   TProcedures.Initialize(oxRenderers.UseRoutines);
   TProcedures.Initialize(oxRenderers.PostUseRoutines);
   TProcedures.Initialize(oxRenderers.StartRoutines);

   ox.dvar.Add(dvRenderer, 'renderer', dtcSTRING, @oxRenderers.vSelectedRenderer);

END.