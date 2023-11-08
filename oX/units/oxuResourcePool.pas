{
   oxuShades, oX shader management
   Copyright (C) 2017.. Dejan Boras

   Started On:    25.04.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuResourcePool;

INTERFACE

   USES
      uStd, oxuTypes
      {$IFDEF OX_RESOURCE_DEBUG}, StringUtils, uLog{$ENDIF};

CONST
   oxRESOURCE_POOL_INCREMENT: loopint = 1024;

TYPE
   oxTResourceLoaderRoutine = procedure(resource: oxTResource);

   oxPResourceLoader = ^oxTResourceLoader;
   oxTResourceLoader = record
      ResourceType: oxTResourceClass;
      Load: oxTResourceLoaderRoutine;
   end;

   oxTResourceLoaders = specialize TPreallocatedArrayList<oxTResourceLoader>;

   { oxTResourcePool }

   oxTResourcePool = class(oxTPreallocatedResourceArrayListClass)
      constructor Create; override;
      destructor Destroy; override;

      {mark all resources as used (increase their reference count)}
      procedure MarkAllUsed();
      {dispose of all resources}
      procedure DisposeAll();
      {dispose of all resources, even permanent ones (if you're sure there aren't any other references to these objects)}
      procedure DisposeAllPermanent();

      {find resource by path}
      function FindByPath(const path: string): oxTResource;

      {add resource to pool}
      procedure AddResource(resource: oxTResource);
      {remove specified resource from pool}
      procedure RemoveResource(resource: oxTResource);

      {Load this type of resource, should basically call the loader routine added via oxResource.AddLoader.
      This also exists so we don't need to look for the loader method as well.}
      procedure Load(); virtual;
   end;

   { oxTResourceGlobal }

   oxTResourceGlobal = record
      Loaders: oxTResourceLoaders;

      {load a resource}
      procedure Load(var resource);
      {destroy a resource (destroys the object if reference count 0 or less)}
      procedure Destroy(var resource);
      {free resource object}
      procedure Free(var resource);

      {add a resource loader}
      procedure AddLoader(resourceType: oxTResourceClass; loader: oxTResourceLoaderRoutine);
      {find a resource loader by the given resource type}
      function FindLoader(resourceType: oxTResourceClass): oxPResourceLoader;
   end;

VAR
   oxResource: oxTResourceGlobal;

IMPLEMENTATION

{ oxTResourceGlobal }

procedure oxTResourceGlobal.Load(var resource);
var
   loader: oxPResourceLoader;

begin
   {make sure we're not given any object}
   if(TObject(resource) <> nil) then begin
      assert(TObject(resource).InheritsFrom(oxTResource), 'Tried to load resource which doesn''t inherit from oxTResource');

      if(oxTResource(resource).Pool <> nil) then begin
         {if resource in pool, call the pool method}
         if(oxTResource(resource).Pool <> nil) then
            oxTResourcePool(oxTResource(resource).Pool).Load()
         else begin
            {otherwise we find the loader}
            loader := FindLoader(oxTResourceClass(oxTResource(resource).ClassType));

            assert(loader <> nil, 'Resource loader not found for class type ' + oxTResource(resource).ClassName);

            loader^.Load(oxTResource(resource));
         end;
      end;
   end;
end;

procedure oxTResourceGlobal.Destroy(var resource);
var
   res: oxTResource absolute resource;

begin
   {make sure we're not given any object}
   if(TObject(resource) = nil) then
      exit;

   assert(TObject(resource).InheritsFrom(oxTResource), 'Tried to destroy resource which doesn''t inherit from oxTResource');

   if(res <> nil) and (res.ReferenceCount <> -1) then begin
      {make sure we're not given any object}
      {$IFDEF OX_RESOURCE_DEBUG}
      if(res.ReferenceCount = 0) then begin
         log.W('Tried to dispose resource with a zero reference count ' + res.Path);
         log.w(res.DebugAllocationPoint);
      end;
      {$ELSE}
      assert(res.ReferenceCount > 0, 'Tried to dispose resource with a zero reference count');
      {$ENDIF}

      if(res.ReferenceCount > 0) then
         dec(res.ReferenceCount);

      {$IFNDEF OX_RESOURCE_DEBUG}
      if(res.ReferenceCount <= 0) then begin
         {remove from pool, if any}
         if(res.Pool <> nil) then
            oxTResourcePool(res.Pool).RemoveResource(res);

         Self.Free(oxTResource(res));
      end;
      {$ENDIF}
   end;
end;

procedure oxTResourceGlobal.Free(var resource);
{$IFDEF OX_RESOURCE_DEBUG}
var
   res: oxTResource;
{$ENDIF}
begin
   {make sure we're not given any object}
   if(TObject(resource) = nil) then
      exit;

   assert(TObject(resource).InheritsFrom(oxTResource), 'Tried to free resource which doesn''t inherit from oxTResource');

   {$IFDEF OX_RESOURCE_DEBUG}
   res := oxTResource(resource);

   log.v('Resource freed: ' + res.Path + ' (' + sf(res.ReferenceCount) + ')');

   if(res.DebugFreed) then begin
      log.w('Resource ' + res.Path + ' already freed (' + sf(res.ReferenceCount) + '), ' + res.ClassName);

      if(res.DebugAllocationPoint <> '') then
         log.w('Freed at: ' + res.DebugFreePoint);
   end;

   res.DebugFreed := true;

   if(res.ReferenceCount = 0) then begin
      log.w('Resource ' + res.Path + ' should already have been freed (' + sf(res.ReferenceCount) + ', ' + res.ClassName + ')');

      if(res.DebugAllocationPoint <> '') then
         log.w('Allocated at: ' + res.DebugAllocationPoint);

      log.v('Called at ' + DumpCallStack(1));
   end;

   oxTResource(resource).FreeInResourceMethod := true;
   exit;
   {$ENDIF}

   FreeObject(resource);
end;

procedure oxTResourceGlobal.AddLoader(resourceType: oxTResourceClass; loader: oxTResourceLoaderRoutine);
var
   l: oxTResourceLoader;

begin
   assert(resourceType <> nil, 'Cannot add loader for nil resource type');
   assert(loader <> nil, 'Cannot add nil resource loader routine');

   l.ResourceType := resourceType;
   l.Load := loader;

   Loaders.Add(l);
end;

function oxTResourceGlobal.FindLoader(resourceType: oxTResourceClass): oxPResourceLoader;
var
   i: loopint;
   properType: TClass;

begin
   properType := resourceType;

   {find class type that inherits from oxTResource, as we need to match with the base type instead of anything inherited}
   while(properType.ClassParent.ClassName <> 'oxTResource') do begin
      properType := properType.ClassParent;
   end;

   {find the type in the list}
   for i := 0 to Loaders.n - 1 do begin
      if(Loaders.List[i].ResourceType = oxTResourceClass(properType)) then
         exit(@Loaders.List[i]);
   end;

   Result := nil;
end;

{ oxTResourcePool }

constructor oxTResourcePool.Create;
begin
   Increment := oxRESOURCE_POOL_INCREMENT;
end;

destructor oxTResourcePool.Destroy;
begin
   inherited Destroy;

   DisposeAll();
end;

procedure oxTResourcePool.MarkAllUsed();
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      inc(oxTResource(List[i]).ReferenceCount);
   end;
end;

procedure oxTResourcePool.DisposeAll();
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].ReferenceCount <> -1) then
         oxResource.Free(List[i]);
   end;

   Dispose();
end;

procedure oxTResourcePool.DisposeAllPermanent();
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      oxResource.Free(List[i]);
   end;

   Dispose();
end;


function oxTResourcePool.FindByPath(const path: string): oxTResource;
var
  i: loopint;

begin
   for i := 0 to (n - 1) do begin
      if(List[i].Path = path) then
         exit(List[i]);
   end;

   result := nil;
end;

procedure oxTResourcePool.AddResource(resource: oxTResource);
begin
   assert(resource.Pool = nil, 'resource being added to a pool is already part of some other pool');

   resource.Pool := Self;
   Add(resource);
end;

procedure oxTResourcePool.RemoveResource(resource: oxTResource);
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i] = resource) then begin
         Remove(i);
         exit;
      end;
   end;
end;

procedure oxTResourcePool.Load();
begin
   Assert(true, 'Load method not overriden for resource pool of type ' + ClassName);
end;

INITIALIZATION
   oxResource.Loaders.InitializeValues(oxResource.Loaders);

END.
