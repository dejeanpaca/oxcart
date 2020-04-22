{
   oxeduThingies, oxed edit window renderers
   Copyright (C) 2017. Dejan Boras

   TODO: Remove lists since we can have the edit renderers in the oxed components list anyways
}

{$INCLUDE oxdefines.inc}
UNIT oxeduThingies;

INTERFACE

   USES
      uStd, uLog,
      {ox}
      oxuRunRoutines, oxuProjectionType,
      oxuCamera, oxuEntity, oxuScene, oxuComponent,
      oxuTexture, oxuDefaultTexture,
      {ui}
      uiuWindowTypes,
      {oxed}
      uOXED, oxeduIcons, oxeduComponent, oxeduComponentGlyph;

TYPE
   {scene edit render parameters}
   oxedTThingieRenderParameters = record
      Window: uiTWindow;
      Camera: oxPCamera;
      Projection: oxPProjection;
      Scene: oxTScene;
      Entity: oxTEntity;
      ComponentObject: oxTComponent;
      Component: oxedPComponent;
   end;

   oxedPThingie = ^oxedTThingie;

   { oxedTThingie }

   oxedTThingie = object
      {renderer name}
      Name: string;
      {associated component type}
      Component: oxedPComponent;
      ComponentType: oxTComponentType;
      {render only when selected}
      Selected: boolean;
      {glyph for this thingie}
      Glyph: oxedPComponentGlyph;

      Links: record
         Next: oxedPThingie;
      end;

      constructor Create();

      {render}
      procedure Render(var {%H-}parameters: oxedTThingieRenderParameters); virtual;
      procedure RenderSelected(var {%H-}parameters: oxedTThingieRenderParameters); virtual;
      procedure Initialize(); virtual;
      procedure Deinitialize(); virtual;

      procedure Link(useComponentType: oxTComponentType);
      procedure AssociateComponent();
   end;

   oxedTThingieRenderComponentPair = record
      Renderer: oxedPThingie;
      Component: oxedPComponent;
      ComponentObject: oxTComponent;
   end;

   oxedTThingieComponentPairs = specialize TSimpleList<oxedTThingieRenderComponentPair>;

   { oxedTThingieComponentPairsHelper }

   oxedTThingieComponentPairsHelper = record helper for oxedTThingieComponentPairs
      procedure Call(var params: oxedTThingieRenderParameters);
      procedure CallSelected(var params: oxedTThingieRenderParameters);
   end;

   { oxedTThingiesGlobal }

   oxedTThingiesGlobal = record
      {are the glyphs rendered in 3d}
      Glyphs3D: boolean;

      {linked list of thingies}
      Start,
      Last: oxedPThingie;

      function Find(componentType: oxTComponentType): oxedPThingie;
      function FindForEntity(entity: oxTEntity; exclude: oxTComponent = nil): oxedTThingieComponentPairs;

      procedure InitParams(out params: oxedTThingieRenderParameters);

      procedure Initialize(var Thingie: oxedTThingie);
   end;

VAR
  oxedThingies: oxedTThingiesGlobal;

IMPLEMENTATION

{ oxedTThingieComponentPairsHelper }

procedure oxedTThingieComponentPairsHelper.Call(var params: oxedTThingieRenderParameters);
var
  i: loopint;

begin
   for i := 0 to (n - 1) do begin
      params.ComponentObject := List[i].ComponentObject;
      params.Component := List[i].Component;

      if(List[i].Renderer <> nil) then
         List[i].Renderer^.Render(params);
   end;
end;

procedure oxedTThingieComponentPairsHelper.CallSelected(var params: oxedTThingieRenderParameters);
var
  i: loopint;

begin
   for i := 0 to (n - 1) do begin
      params.ComponentObject := List[i].ComponentObject;
      params.Component := List[i].Component;

      if(List[i].Renderer <> nil) then
         List[i].Renderer^.RenderSelected(params);
   end;
end;

{ oxedTThingiesGlobal }

procedure oxedTThingiesGlobal.InitParams(out params: oxedTThingieRenderParameters);
begin
   ZeroOut(params, SizeOf(params));
end;

procedure oxedTThingiesGlobal.Initialize(var Thingie: oxedTThingie);
begin
   Thingie.Initialize();
end;

function oxedTThingiesGlobal.Find(componentType: oxTComponentType): oxedPThingie;
var
   i: loopint;

begin
   if(componentType <> nil) then begin
      for i := 0 to (oxedComponents.List.n - 1) do begin
         if (oxedComponents.List[i].Component.ClassName = componentType.ClassName) then
            exit(oxedPThingie(oxedComponents.List[i].Thingie));
      end;
   end;

   Result := nil;
end;

function oxedTThingiesGlobal.FindForEntity(entity: oxTEntity; exclude: oxTComponent): oxedTThingieComponentPairs;
var
   i: loopint;
   pair: oxedTThingieRenderComponentPair;

begin
   Result.Initialize(Result);

   for i := 0 to (entity.Components.n - 1) do begin
      if(exclude = nil) or (entity.Components.List[i].ClassName <> exclude.ClassName) then begin
         pair.ComponentObject := entity.Components.List[i];
         pair.Component := oxedComponents.Find(oxTComponentType(pair.ComponentObject.ClassType));
         pair.Renderer := Find(oxTComponentType(pair.ComponentObject.ClassType));

         Result.Add(pair);
      end;
   end;
end;


{ oxTThingie }

constructor oxedTThingie.Create();
begin

end;

procedure oxedTThingie.Render(var parameters: oxedTThingieRenderParameters);
begin

end;

procedure oxedTThingie.RenderSelected(var parameters: oxedTThingieRenderParameters);
begin

end;

procedure oxedTThingie.Initialize();
begin
end;

procedure oxedTThingie.Deinitialize();
begin

end;

procedure oxedTThingie.Link(useComponentType: oxTComponentType);
begin
   ComponentType := useComponentType;

   if(oxedThingies.Start = nil) then
      oxedThingies.Start := @Self
   else
      oxedThingies.Last^.Links.Next := @Self;

   oxedThingies.Last := @Self;
end;

procedure oxedTThingie.AssociateComponent();
begin
   if(Component <> nil) then
      Component^.Thingie := @Self
   else
      log.w('Could not associate component ' + componentType.ClassName + ' with renderer ' + Name);
end;

procedure init();
var
   i: loopint;
   cur: oxedPThingie;

begin
   cur := oxedThingies.Start;

   if(cur <> nil) then repeat
      cur^.AssociateComponent();

      cur := cur^.Links.Next;
   until cur = nil;

   for i := 0 to (oxedComponents.List.n - 1) do begin
      {$IFDEF DEBUG_EXTENDED}
      if(oxedComponents.List[i].Thingie <> nil) and (oxedComponents.List[i].Component = nil) then
         log.v('Edit renderer for nil component: ', oxedComponents.List[i].Thingie.ClassName);

      if(oxedComponents.List[i].Thingie = nil) and (oxedComponents.List[i].Component <> nil) then
         log.v('Missing edit renderer: ', oxedComponents.List[i].Component.ClassName);
      {$ENDIF}

      if(oxedComponents.List[i].Thingie <> nil) then
         oxedThingies.Initialize(oxedPThingie(oxedComponents.List[i].Thingie)^);
   end;

   cur := oxedThingies.Start;

   if(cur <> nil) then repeat
      cur^.Initialize();

      cur := cur^.Links.Next;
   until cur = nil;
end;

procedure deinit();
var
   cur: oxedPThingie;

begin
   cur := oxedThingies.Start;

   if(cur <> nil) then repeat
      cur^.DeInitialize();

      cur := cur^.Links.Next;
   until cur = nil;
end;

INITIALIZATION
   oxedThingies.Glyphs3D := true;

   oxed.Init.Add('oxed.edit_renderers', @init, @deinit);


END.
