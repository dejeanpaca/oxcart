{
   oxeduEditRenderers, oxed edit window renderers
   Copyright (C) 2016. Dejan Boras

   Started On:    24.04.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduComponent;

INTERFACE

   USES
      uStd, uInit,
      {ox}
      uOX, oxuComponent, oxuComponentDescriptors, oxuRunRoutines,
      {oxed}
      uOXED, oxeduComponentGlyph;

TYPE
   oxedPComponent = ^oxedTComponent;

   { oxedTComponent }

   oxedTComponent = record
      Component: oxTComponentType;
      {glyph associated with this component}
      Glyph: oxedTComponentGlyph;
      {edit mode renderer associated with this component}
      EditRenderer: TObject;

      class procedure Initialize(out c: oxedTComponent); static;
   end;

   oxedTComponentList = specialize TPreallocatedArrayList<oxedTComponent>;

   { oxedTComponents }

   oxedTComponents = record
      List: oxedTComponentList;

      function Add(component: oxTComponentType): oxedPComponent;
      function Find(component: oxTComponentType): oxedPComponent;
   end;

VAR
   oxedComponents: oxedTComponents;

IMPLEMENTATION

{ oxedTComponent }

class procedure oxedTComponent.Initialize(out c: oxedTComponent);
begin
   ZeroPtr(@c, SizeOf(c));
end;

{ oxedTComponents }

function oxedTComponents.Add(component: oxTComponentType): oxedPComponent;
var
   c: oxedTComponent;

begin
   c.Initialize(c);
   c.Component := component;

   List.Add(c);

   Result := List.GetLast();
end;

function oxedTComponents.Find(component: oxTComponentType): oxedPComponent;
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if (List.List[i].Component.ClassName = component.ClassName) then
         exit(@List.List[i]);
   end;

   Result := nil;
end;

procedure init();
var
   i: loopint;

begin
   oxedTComponentList.InitializeValues(oxedComponents.List);

   {initialize components}
   for i := 0 to oxComponentDescriptors.List.n - 1 do begin
      oxedComponents.Add(oxTComponentType(oxComponentDescriptors.List[i]^.Component));
   end;
end;

procedure deinit();
begin
   oxedComponents.List.Dispose();
end;

procedure oxed_init();
var
   i: loopint;

begin
   {initialize components}
   for i := 0 to oxedComponents.List.n - 1 do begin
      oxedComponents.List.List[i].Glyph.CreateTexture();
   end;
end;

procedure oxed_deinit();
var
   i: loopint;

begin
   {initialize components}
   for i := 0 to oxedComponents.List.n - 1 do begin
      oxedComponents.List.List[i].Glyph.Destroy();
   end;
end;


VAR
   initRoutines: oxTRunRoutine;
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'oxed.components', @init, @deinit);
   oxed.Init.Add(oxedInitRoutines, 'components', @oxed_init, @oxed_deinit);

END.
