{
   oxuEntity, entity management
   Copyright (c) 2011. Dejan Boras

   Started On:    05.11.2013.
}

{$INCLUDE oxdefines.inc}
UNIT oxuEntity;

INTERFACE

   USES
      uStd, vmVector,
      {oX}
      oxuTransform, oxuComponent, oxuSerialization, oxuGlobalInstances;

TYPE
   { oxTEntities }
   oxTEntities = specialize TPreallocatedArrayList<oxTTransform>;

   { oxTEntity }

   oxTEntity = class(oxTTransform)
      public
      {parent entity}
      Parent: oxTEntity;

      {name of the entity}
      Name: string;
      {is the entity enabled}
      Enabled,
      {is the entity static}
      IsStatic,
      {should we render this entity}
      Renderable: boolean;

      {all entity components}
      Components: oxTComponentsList;
      {sub-entities}
      Children: oxTEntities;

      {$IFDEF OXED}
      {editor specific properties per entity}
      Editor: TObject;
      {$ENDIF}

      constructor Create(); override;

      {add a component to the list of components}
      function Add(component: oxTComponent): oxTComponent;
      {add an entity to the list of children}
      function Add(entity: oxTEntity): oxTEntity;
      {remove the specified entity from list of children}
      procedure Remove(entity: oxTEntity);
      {remove component at the specified index}
      procedure RemoveComponent(index: loopint);

      {find the specified entity in children, if nothing found return -1}
      function Find(entity: oxTEntity): loopint;
      {used by Find(path), searches entity children named as the part of path at the specified path position, then proceeds further}
      function Find(current: oxTEntity; const path: string; pathPos: loopint): oxTEntity;
      {find the specified entity by path, if nothing found return -1}
      function Find(const path: string): oxTEntity;

      {tells if this entity has the given entity as one of the parents}
      function HasParent(p: oxTEntity): boolean;

      {get specified component}
      function GetComponent(componentType: oxTComponentType): oxTComponent;
      function GetComponent(const componentType: string): oxTComponent;
      {get first instance of specified component in children}
      function GetComponentInChildren(componentType: oxTComponentType): oxTComponent;
      function GetComponentInChildren(const componentType: string): oxTComponent;
      {get all components of the specified type}
      procedure GetComponents(componentType: oxTComponentType; var list: oxTComponentsList);
      procedure GetComponents(const componentType: string; var list: oxTComponentsList);
      {get all components of the specified type}
      procedure GetComponentsInChildren(componentType: oxTComponentType; var list: oxTComponentsList);
      procedure GetComponentsInChildren(const componentType: string; var list: oxTComponentsList);

      {set position}
      procedure SetPosition(x, y, z: single);
      procedure SetPosition(const v: TVector3f);

      {set rotation}
      procedure SetRotation(x, y, z: single);
      procedure SetRotation(const v: TVector3f);

      {set scale}
      procedure SetScale(x, y, z: single);
      procedure SetScale(const v: TVector3f);

      {get the world matrix}
      procedure GetWorldMatrix(out m: TMatrix4f);
      {get the world position}
      procedure GetWorldPosition(out p: TVector3f);
      {get the world rotation}
      procedure GetWorldRotation(out p: TVector3f);
      {get the world scale}
      procedure GetWorldScale(out p: TVector3f);

      {set the world position}
      procedure SetWorldPosition(const p: TVector3f);
      {set the world rotation}
      procedure SetWorldRotation(const r: TVector3f);
      {set the world scale}
      procedure SetWorldScale(const s: TVector3f);

      {call component load methods}
      procedure LoadComponents();
      {call component load methods in children recursively}
      procedure LoadComponentsInChildren();
      {call component start methods}
      procedure StartComponents();
      {call component start methods in children recursively}
      procedure StartComponentsInChildren();
      {update the entity}
      procedure UpdateComponents();
      {update children}
      procedure UpdateComponentsInChildren();

      {remove components and children}
      procedure Empty();

      {load resources for all components}
      procedure LoadResources();

      destructor Destroy; override;
   end;

   { oxTEntitiesHelper }

   oxTEntitiesHelper = record helper for oxTEntities
      {find an entity in the list}
      function Find(const name: string): oxTEntity;
      {destroy entities}
      procedure Destroy();
   end;

   oxTEntityCallback = procedure(entity: oxTEntity);
   oxTEntityCallbacks = specialize TPreallocatedArrayList<oxTEntityCallback>;

   { oxTEntityCallbacksHelper }

   oxTEntityCallbacksHelper = record helper for oxTEntityCallbacks
      procedure Call(entity: oxTEntity);
   end;

   oxTComponentCallback = procedure(entity: oxTEntity; component: oxTComponent);
   oxTComponentCallbacks = specialize TPreallocatedArrayList<oxTComponentCallback>;

   { oxTComponentCallbacksHelper }

   oxTComponentCallbacksHelper = record helper for oxTComponentCallbacks
      procedure Call(entity: oxTEntity; component: oxTComponent);
   end;

   { oxTEntityGlobal }

   oxTEntityGlobal = class
      OnCreate,
      OnDestroy,
      OnAdd,
      OnRemove,
      OnClone: oxTEntityCallbacks;

      OnComponentAdd,
      OnComponentRemove: oxTComponentCallbacks;

      Serialization: oxTSerialization; static;

      {create a new empty entity}
      function New(const name: string = ''): oxTEntity; virtual;

      constructor Create;
   end;

VAR
   oxEntity: oxTEntityGlobal;

IMPLEMENTATION

function instance(): TObject;
begin
   Result := oxTEntity.Create();
end;

function instanceGlobal(): TObject;
begin
   Result := oxTEntityGlobal.Create();
end;

{ oxTComponentCallbacksHelper }

procedure oxTComponentCallbacksHelper.Call(entity: oxTEntity; component: oxTComponent);
var
   i: loopint;

begin
   for i := 0 to (n - 1) do
      List[i](entity, component);
end;

{ oxTEntityCallbacksHelper }

procedure oxTEntityCallbacksHelper.Call(entity: oxTEntity);
var
   i: loopint;

begin
   for i := 0 to (n - 1) do
      List[i](entity);
end;

{ oxTEntity }

constructor oxTEntity.Create();
begin
   inherited;

   Children.InitializeValues(Children);
   Components.InitializeValues(Components, 8);

   Renderable := true;
   Enabled := true;

   oxEntity.OnCreate.Call(self);
end;

function oxTEntity.Add(component: oxTComponent): oxTComponent;
begin
   component.Parent := Self;
   Components.Add(component);
   component.OnAdd();

   oxEntity.OnComponentAdd.Call(Self, component);
   Result := component;
end;

function oxTEntity.Add(entity: oxTEntity): oxTEntity;
begin
   entity.Parent := Self;
   Children.Add(entity);
   oxEntity.OnAdd.Call(entity);

   Result := entity;
end;

procedure oxTEntity.Remove(entity: oxTEntity);
var
   i: loopint;

begin
   for i := 0 to (Children.n - 1) do begin
      if(Children.List[i] = entity) then begin
         oxEntity.OnRemove.Call(entity);
         FreeObject(Children.List[i]);
         Children.Remove(i);
         exit;
      end;
   end;
end;

procedure oxTEntity.RemoveComponent(index: loopint);
begin
   if(index >= 0) and (index <= Components.n) then begin
      oxEntity.OnComponentRemove.Call(Self, Components.List[index]);
      FreeObject(Components.List[index]);
      Components.Remove(index);
   end;
end;

function oxTEntity.Find(entity: oxTEntity): loopint;
var
   i: loopint;

begin
   for i := 0 to (Children.n - 1) do begin
      if(Children.List[i] = entity) then
         exit(i);
   end;

   Result := -1;
end;

function oxTEntity.Find(current: oxTEntity; const path: string; pathPos: loopint): oxTEntity;
var
   len,
   endPos,
   i: loopint;

   subPath: string;

begin
   len := Length(path);

   {path was completed}
   if(pathPos > len) then
      exit(current);

   {assume end is after the path length}
   endPos := len + 1;

   {find the sub path name, based on the current position and next path separator}
   for i := pathPos to len do begin
      if(path[i] = '/') then begin
         endPos := i;
         break;
      end;
   end;

   subPath := copy(path, pathPos, endPos - 1);

   {find}
   for i := 0 to current.Children.n - 1 do begin
      if(oxTEntity(current.Children.List[i]).Name = subPath) then
         exit(Find(oxTEntity(current.Children.List[i]), path, endPos + 1));
   end;

   {nothing found here, quit}
   Exit(nil);
end;

function oxTEntity.Find(const path: string): oxTEntity;
begin
   Result := Find(Self, path, 1);
end;

function oxTEntity.HasParent(p: oxTEntity): boolean;
var
   cur: oxTEntity;

begin
   cur := Parent;
   if(cur <> nil) then repeat
      if(cur = p) then
         exit(true);

      cur := cur.Parent;
   until (cur = nil);

   Result := false;
end;

function oxTEntity.GetComponent(componentType: oxTComponentType): oxTComponent;
var
   i: longint;

begin
   for i := 0 to (Components.n - 1) do begin
      if(Components.List[i].ClassType = componentType) then
         exit(Components.List[i]);
   end;

   Result := nil;
end;

function oxTEntity.GetComponent(const componentType: string): oxTComponent;
var
   i: longint;

begin
   for i := 0 to (Components.n - 1) do begin
      if(Components.List[i].ClassName = componentType) then
         exit(Components.List[i]);
   end;

   Result := nil;
end;

function oxTEntity.GetComponentInChildren(componentType: oxTComponentType): oxTComponent;
var
   i: loopint;

begin
   for i := 0 to Components.n - 1 do begin
      if(Components.List[i].ClassType = componentType) then
         exit(Components.List[i]);
   end;

   for i := 0 to Children.n - 1 do begin
      Result := oxTEntity(Children.List[i]).GetComponent(componentType);

      if(Result <> nil) then
         exit(Result);
   end;

   Result := nil;
end;

function oxTEntity.GetComponentInChildren(const componentType: string): oxTComponent;
var
   i: loopint;

begin
   for i := 0 to Components.n - 1 do begin
      if(Components.List[i].ClassName = componentType) then
         exit(Components.List[i]);
   end;

   for i := 0 to Children.n - 1 do begin
      Result := oxTEntity(Children.List[i]).GetComponent(componentType);

      if(Result <> nil) then
         exit(Result);
   end;

   Result := nil;
end;

procedure oxTEntity.GetComponents(componentType: oxTComponentType; var list: oxTComponentsList);
var
   i: longint;

begin
   for i := 0 to (Components.n - 1) do begin
      if(Components.List[i].ClassType = componentType) then
         list.Add(Components.List[i]);
   end;
end;

procedure oxTEntity.GetComponents(const componentType: string; var list: oxTComponentsList);
var
   i: longint;

begin
   for i := 0 to (Components.n - 1) do begin
      if(Components.List[i].ClassName = componentType) then
         list.Add(Components.List[i]);
   end;
end;

procedure oxTEntity.GetComponentsInChildren(componentType: oxTComponentType; var list: oxTComponentsList);
var
   i: longint;

begin
   GetComponents(componentType, list);

   for i := 0 to (Children.n - 1) do
      oxTEntity(Children.List[i]).GetComponentsInChildren(componentType, list);
end;

procedure oxTEntity.GetComponentsInChildren(const componentType: string; var list: oxTComponentsList);
var
   i: longint;

begin
   GetComponents(componentType, list);

   for i := 0 to (Children.n - 1) do
      oxTEntity(Children.List[i]).GetComponentsInChildren(componentType, list);
end;

procedure oxTEntity.SetPosition(x, y, z: single);
var
   i: loopint;

begin
   vPosition[0] := x;
   vPosition[1] := y;
   vPosition[2] := z;

   SetupMatrix();

   for i := 0 to (Components.n - 1) do
      Components.List[i].OnPositionChanged();
end;

procedure oxTEntity.SetPosition(const v: TVector3f);
begin
   SetPosition(v[0], v[1], v[2]);
end;

procedure oxTEntity.SetRotation(x, y, z: single);
var
   i: loopint;

begin
   vRotation[0] := x;
   vRotation[1] := y;
   vRotation[2] := z;

   SetupMatrix();

   for i := 0 to (Components.n - 1) do
      Components.List[i].OnRotationChanged();
end;

procedure oxTEntity.SetRotation(const v: TVector3f);
begin
   SetRotation(v[0], v[1], v[2]);
end;

procedure oxTEntity.SetScale(x, y, z: single);
var
   i: loopint;

begin
   vScale[0] := x;
   vScale[1] := y;
   vScale[2] := z;

   SetupMatrix();

   for i := 0 to (Components.n - 1) do
      Components.List[i].OnScaleChanged();
end;

procedure oxTEntity.SetScale(const v: TVector3f);
begin
   SetScale(v[0], v[1], v[2]);
end;

procedure oxTEntity.GetWorldMatrix(out m: TMatrix4f);
var
   cur: oxTEntity;

begin
   cur := self;
   m := vmmUnit4;

   repeat
      m := m * cur.Matrix;

      cur := cur.Parent;
   until (cur = nil);
end;

procedure oxTEntity.GetWorldPosition(out p: TVector3f);
var
   cur: oxTEntity;

begin
   cur := self;
   p := vmvZero3f;

   repeat
      p := p + cur.vPosition;

      cur := cur.Parent;
   until (cur = nil);
end;

procedure oxTEntity.GetWorldRotation(out p: TVector3f);
var
   cur: oxTEntity;

begin
   cur := self;
   p := vmvZero3f;

   repeat
      p := p + cur.vRotation;

      cur := cur.Parent;
   until (cur = nil);
end;

procedure oxTEntity.GetWorldScale(out p: TVector3f);
var
   cur: oxTEntity;

begin
   cur := self;
   p := vScale;

   if(cur.Parent <> nil) then begin
      cur := cur.Parent;

      repeat
         p := p * cur.vScale;

         cur := cur.Parent;
      until (cur = nil);
   end;
end;

procedure oxTEntity.SetWorldPosition(const p: TVector3f);
var
   cP: TVector3f;
   cur: oxTEntity;

begin
   cP := vmvZero3f;

   if(self.Parent <> nil) then begin
      cur := self.Parent;

      repeat
         cP := cP + cur.vScale;

         cur := cur.Parent;
      until (cur = nil);
   end;

   vPosition[0] := p[0] - cP[0];
   vPosition[1] := p[1] - cP[1];
   vPosition[2] := p[2] - cP[2];
end;

procedure oxTEntity.SetWorldRotation(const r: TVector3f);
var
   cR: TVector3f;
   cur: oxTEntity;

begin
   cR := vmvZero3f;

   if(self.Parent <> nil) then begin
      cur := self.Parent;

      repeat
         cR := cR + cur.vRotation;

         cur := cur.Parent;
      until (cur = nil);
   end;

   vRotation[0] := r[0] - cR[0];
   vRotation[1] := r[1] - cR[1];
   vRotation[2] := r[2] - cR[2];
end;

procedure oxTEntity.SetWorldScale(const s: TVector3f);
var
   cS: TVector3f;
   cur: oxTEntity;

begin
   cS := vmvZero3f;

   if(self.Parent <> nil) then begin
      cur := self.Parent;
      cS := cur.vScale;

      if(cur.Parent <> nil) then begin
         cur := cur.Parent;

         repeat
            cS := cS * cur.vScale;

            cur := cur.Parent;
         until (cur = nil);
      end;
   end;

   vRotation[0] := s[0] / cS[0];
   vRotation[1] := s[1] / cS[1];
   vRotation[2] := s[2] / cS[2];
end;

procedure oxTEntity.LoadComponents();
var
   i: longint;

begin
   for i := 0 to (Components.n - 1) do
      Components.List[i].Load();
end;

procedure oxTEntity.LoadComponentsInChildren();
var
   i: longint;

begin
   LoadComponents();

   for i := 0 to (Children.n - 1) do
      oxTEntity(Children.List[i]).LoadComponentsInChildren();
end;

procedure oxTEntity.StartComponents();
var
   i: longint;

begin
   for i := 0 to (Components.n - 1) do
      Components.List[i].Start();
end;

procedure oxTEntity.StartComponentsInChildren();
var
   i: longint;

begin
   StartComponents();

   for i := 0 to (Children.n - 1) do
      oxTEntity(Children.List[i]).StartComponentsInChildren();
end;

procedure oxTEntity.UpdateComponents();
var
   i: longint;

begin
   for i := 0 to (Components.n - 1) do
      Components.List[i].Update();
end;

procedure oxTEntity.UpdateComponentsInChildren();
var
   i: longint;

begin
   UpdateComponents();

   for i := 0 to (Children.n - 1) do
      oxTEntity(Children.List[i]).UpdateComponentsInChildren();
end;

procedure oxTEntity.Empty();
begin
   Children.Destroy();
   Components.Destroy();
end;

procedure oxTEntity.LoadResources();
var
   i: loopint;

begin
   for i := 0 to Children.n - 1 do begin
      oxTEntity(Children.List[i]).LoadResources();
   end;

   for i := 0 to Components.n - 1 do begin
      Components.List[i].LoadResources();
   end;
end;

destructor oxTEntity.Destroy;
begin
   inherited Destroy;

   oxEntity.OnDestroy.Call(self);
   {$IFDEF OXED}
   FreeObject(Editor);
   {$ENDIF}
   Empty();
end;

{ oxTEntitiesGlobal }

function oxTEntityGlobal.New(const name: string): oxTEntity;
begin
   Result := oxTEntity.Create();
   Result.Name := name;
end;

constructor oxTEntityGlobal.Create;
begin
   OnCreate.Initialize(OnCreate);
   OnDestroy.Initialize(OnDestroy);
   OnAdd.Initialize(OnAdd);
   OnRemove.Initialize(OnRemove);
   OnClone.Initialize(OnClone);

   OnComponentAdd.Initialize(OnComponentAdd);
   OnComponentRemove.Initialize(OnComponentRemove);
end;

{ oxTEntitiesHelper }

function oxTEntitiesHelper.Find(const name: string): oxTEntity;
var
  i: longint;

begin
   for i := 0 to (n - 1) do begin
      if(oxTentity(list[i]).Name = name) then
         exit(oxTEntity(List[i]));
   end;

   Result := nil;
end;

procedure oxTEntitiesHelper.Destroy();
var
   i: longint;

begin
   for i := 0 to (n - 1) do
      FreeObject(List[i]);

   if(List <> nil) then
      Dispose();
end;

procedure init();
begin
   oxEntity.Serialization := oxTSerialization.Create(oxTEntity, @instance);
   oxEntity.Serialization.AddProperty('Name', @oxTEntity(nil).Name, oxSerialization.Types.tString);
   oxEntity.Serialization.AddProperty('Enabled', @oxTEntity(nil).Enabled, oxSerialization.Types.Boolean);
   oxEntity.Serialization.AddProperty('Renderable', @oxTEntity(nil).Renderable, oxSerialization.Types.Boolean);
   oxEntity.Serialization.PropertiesDone();

   oxGlobalInstances.Add(oxTEntityGlobal, @oxEntity, @instanceGlobal)^.CopyOverReference := false;
end;

INITIALIZATION
   init();

FINALIZATION
   FreeObject(oxEntity.Serialization);

END.
