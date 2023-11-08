{
   oxeduEditRenderers, oxed edit window renderers
   Copyright (C) 2016. Dejan Boras

   Started On:    24.04.2017.

   TODO: Remove lists since we can have the edit renderers in the oxed components list anyways
}

{$INCLUDE oxdefines.inc}
UNIT oxeduEditRenderers;

INTERFACE

   USES
      uStd, uInit,
      {ox}
      oxuProjection, oxuCamera, oxuEntity, oxuScene, oxuComponent,
      oxuTexture, oxuDefaultTexture,
      {ui}
      uiuWindowTypes,
      {oxed}
      uOXED, oxeduIcons, oxeduComponent;

TYPE
   {scene edit render parameters}
   oxedTEditRenderParameters = record
      Window: uiTWindow;
      Camera: oxTCamera;
      Projection: oxTProjection;
      Scene: oxTScene;
      Entity: oxTEntity;
      ComponentObject: oxTComponent;
      Component: oxedPComponent;
   end;

   { oxedTEditRenderer }

   oxedTEditRenderer = class
      {renderer name}
      Name: string;
      {associated component type}
      Component: oxedPComponent;
      {render only when selected}
      Selected: boolean;

      {render}
      procedure Render(var {%H-}parameters: oxedTEditRenderParameters); virtual;
      procedure RenderSelected(var {%H-}parameters: oxedTEditRenderParameters); virtual;
      procedure Initialize(); virtual;
      procedure Deinitialize(); virtual;
   end;

   oxedTEditRenderComponentPair = record
      Renderer: oxedTEditRenderer;
      Component: oxedPComponent;
      ComponentObject: oxTComponent;
   end;

   oxedTEditRenderers = specialize TPreallocatedArrayList<oxedTEditRenderer>;
   oxedTEditRendererComponentPairs = specialize TPreallocatedArrayList<oxedTEditRenderComponentPair>;

   { oxedTEditRenderersHelper }

   oxedTEditRenderersHelper = record helper for oxedTEditRenderers
      function Find(componentType: oxTComponentType): oxedTEditRenderer;
      function FindForEntity(entity: oxTEntity; exclude: oxTComponent = nil): oxedTEditRendererComponentPairs;
   end;

   { oxedTEditRendererComponentPairsHelper }

   oxedTEditRendererComponentPairsHelper = record helper for oxedTEditRendererComponentPairs
      procedure Call(var params: oxedTEditRenderParameters);
      procedure CallSelected(var params: oxedTEditRenderParameters);
   end;

   { oxedTEditRenderersGlobal }

   oxedTEditRenderersGlobal = record
      {are the glyphs rendered in 3d}
      Glyphs3D: boolean;

      {renderers active on selection}
      Selection,
      {list of all renderers}
      Renderers: oxedTEditRenderers;

      {renderer initialization routines}
      Init: TInitializationProcs;

      procedure InitParams(out params: oxedTEditRenderParameters);

      procedure Initialize(editRenderer: oxedTEditRenderer);
   end;

VAR
  oxedEditRenderers: oxedTEditRenderersGlobal;

IMPLEMENTATION

{ oxedTEditRendererComponentPairsHelper }

procedure oxedTEditRendererComponentPairsHelper.Call(var params: oxedTEditRenderParameters);
var
  i: loopint;

begin
   for i := 0 to (n - 1) do begin
      params.ComponentObject := List[i].ComponentObject;
      params.Component := List[i].Component;

      if(List[i].Renderer <> nil) then
         List[i].Renderer.Render(params);
   end;
end;

procedure oxedTEditRendererComponentPairsHelper.CallSelected(var params: oxedTEditRenderParameters);
var
  i: loopint;

begin
   for i := 0 to (n - 1) do begin
      params.Component := List[i].Component;

      if(List[i].Renderer <> nil) then
         List[i].Renderer.RenderSelected(params);
   end;
end;

{ oxedTEditRenderersGlobal }

procedure oxedTEditRenderersGlobal.InitParams(out params: oxedTEditRenderParameters);
begin
   ZeroOut(params, SizeOf(params));
end;

procedure oxedTEditRenderersGlobal.Initialize(editRenderer: oxedTEditRenderer);
begin
   editRenderer.Initialize();
end;

{ oxedTEditRenderersHelper }

function oxedTEditRenderersHelper.Find(componentType: oxTComponentType): oxedTEditRenderer;
var
   i: loopint;

begin
   for i := 0 to (n - 1) do begin
      if(List[i].Component^.Component = componentType) then
         exit(List[i]);
   end;

   result := nil;
end;

function oxedTEditRenderersHelper.FindForEntity(entity: oxTEntity; exclude: oxTComponent): oxedTEditRendererComponentPairs;
var
   i: loopint;
   pair: oxedTEditRenderComponentPair;

begin
   Result.Initialize(Result);

   for i := 0 to (entity.Components.n - 1) do begin
      if(entity.Components.List[i] <> exclude) then begin
         pair.ComponentObject := entity.Components.List[i];
         pair.Component := oxedComponents.Find(oxTComponentType(pair.ComponentObject.ClassType));
         pair.Renderer := Find(oxTComponentType(pair.ComponentObject.ClassType));

         Result.Add(pair);
      end;
   end;
end;

{ oxTEditRenderer }

procedure oxedTEditRenderer.Render(var parameters: oxedTEditRenderParameters);
begin

end;

procedure oxedTEditRenderer.RenderSelected(var parameters: oxedTEditRenderParameters);
begin

end;

procedure oxedTEditRenderer.Initialize();
begin
end;

procedure oxedTEditRenderer.Deinitialize();
begin

end;

procedure init();
var
   i: loopint;

begin
   oxedEditRenderers.Init.iCall();

   for i := 0 to (oxedEditRenderers.Renderers.n - 1) do begin
      oxedEditRenderers.Initialize(oxedEditRenderers.Renderers.List[i]);
   end;
end;

procedure deinit();
var
   i: loopint;

begin
   for i := 0 to (oxedEditRenderers.Renderers.n - 1) do
      oxedEditRenderers.Renderers.List[i].Deinitialize();

   oxedEditRenderers.Init.dCall();
   oxedEditRenderers.Renderers.Dispose();
end;

INITIALIZATION
   oxedEditRenderers.Init.Init('oxed.edit_renderers');
   oxedEditRenderers.Glyphs3D := true;

   oxedEditRenderers.Selection.Initialize(oxedEditRenderers.Selection);
   oxedEditRenderers.Renderers.Initialize(oxedEditRenderers.Renderers);

   oxed.Init.Add('oxed.edit_renderers', @init, @deinit);


END.
