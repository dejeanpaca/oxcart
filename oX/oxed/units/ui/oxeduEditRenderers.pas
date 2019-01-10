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
      uStd, uInit, uLog,
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

      procedure Associate(componentType: oxTComponentType);
   end;

   oxedTEditRenderComponentPair = record
      Renderer: oxedTEditRenderer;
      Component: oxedPComponent;
      ComponentObject: oxTComponent;
   end;

   oxedTEditRendererComponentPairs = specialize TPreallocatedArrayList<oxedTEditRenderComponentPair>;

   { oxedTEditRendererComponentPairsHelper }

   oxedTEditRendererComponentPairsHelper = record helper for oxedTEditRendererComponentPairs
      procedure Call(var params: oxedTEditRenderParameters);
      procedure CallSelected(var params: oxedTEditRenderParameters);
   end;

   { oxedTEditRenderersGlobal }

   oxedTEditRenderersGlobal = record
      {are the glyphs rendered in 3d}
      Glyphs3D: boolean;

      {renderer initialization routines}
      Init: TInitializationProcs;

      function Find(componentType: oxTComponentType): oxedTEditRenderer;
      function FindForEntity(entity: oxTEntity; exclude: oxTComponent = nil): oxedTEditRendererComponentPairs;

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
      params.ComponentObject := List[i].ComponentObject;
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


function oxedTEditRenderersGlobal.Find(componentType: oxTComponentType): oxedTEditRenderer;
var
   i: loopint;

begin
   for i := 0 to (oxedComponents.List.n - 1) do begin
      if(oxedComponents.List[i].Component = componentType) then
         exit(oxedTEditRenderer(oxedComponents.List[i].EditRenderer));
   end;

   Result := nil;
end;

function oxedTEditRenderersGlobal.FindForEntity(entity: oxTEntity; exclude: oxTComponent): oxedTEditRendererComponentPairs;
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

procedure oxedTEditRenderer.Associate(componentType: oxTComponentType);
begin
   Component := oxedComponents.Find(componentType);

   if(Component <> nil) then
      Component^.EditRenderer := Self
   else
      log.w('Could not associate component ' + componentType.ClassName + ' with renderer ' + Self.ClassName);
end;

procedure init();
var
   i: loopint;

begin
   oxedEditRenderers.Init.iCall();

   for i := 0 to (oxedComponents.List.n - 1) do begin
      {$IFDEF DEBUG_EXTENDED}
      if(oxedComponents.List[i].EditRenderer <> nil) and (oxedComponents.List[i].Component = nil) then
         log.v('Edit renderer for nil component: ', oxedComponents.List[i].EditRenderer.ClassName);

      if(oxedComponents.List[i].EditRenderer = nil) and (oxedComponents.List[i].Component <> nil) then
         log.v('Missing edit renderer: ', oxedComponents.List[i].Component.ClassName);
      {$ENDIF}

      if(oxedComponents.List[i].EditRenderer <> nil) then
         oxedEditRenderers.Initialize(oxedTEditRenderer(oxedComponents.List[i].EditRenderer));
   end;
end;

procedure deinit();
var
   i: loopint;

begin
   for i := 0 to (oxedComponents.List.n - 1) do begin
      if(oxedComponents.List[i].EditRenderer <> nil) then
         oxedTEditRenderer(oxedComponents.List[i].EditRenderer).Deinitialize();
   end;

   oxedEditRenderers.Init.dCall();
end;

INITIALIZATION
   oxedEditRenderers.Init.Init('oxed.edit_renderers');
   oxedEditRenderers.Glyphs3D := true;

   oxed.Init.Add('oxed.edit_renderers', @init, @deinit);


END.
