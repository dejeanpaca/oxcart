{
   oxuShades, oX shader management
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuResourcePool;

INTERFACE

   USES
      {$IFDEF OX_RESOURCE_DEBUG}StringUtils, uLog, {$ENDIF}
      uStd,
      {ox}
      uOX, oxuTypes, oxuResourceLoader;

CONST
   oxRESOURCE_POOL_INCREMENT: loopint = 1024;

TYPE
   { oxTResourcePool }

   oxTResourcePool = class(oxTSimpleResourceListClass)
      Name: string;

      constructor Create(); override;
      destructor Destroy(); override;

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

   oxTResourcePoolList = specialize TSimpleList<oxTResourcePool>;

   { oxTResourceGlobal }

   oxTResourceGlobal = record
      Pools: oxTResourcePoolList;

      {load a resource}
      procedure Load(var resource);
      {destroy a resource (destroys the object if reference count 0 or less)}
      procedure Destroy(var resource);
      {free resource object}
      procedure Free(var resource);


      procedure Add(pool: oxTResourcePool);
      function Find(pool: oxTResourcePool): loopint;
      procedure Remove(pool: oxTResourcePool);
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
      ox.Assert(ox.IsType(TObject(resource), oxTResource), 'Tried to load resource which doesn''t inherit from oxTResource: ' + TObject(resource).ClassName);

      if(oxTResource(resource).Pool <> nil) then begin
         {if resource in pool, call the pool method}
         if(oxTResource(resource).Pool <> nil) then
            oxTResourcePool(oxTResource(resource).Pool).Load()
         else begin
            {otherwise we find the loader}
            loader := oxPResourceLoader(oxTResource(resource).GetLoader());

            ox.Assert(loader <> nil, 'Resource loader not found for class type ' + oxTResource(resource).ClassName);

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

   ox.Assert(ox.IsType(TObject(resource), oxTResource), 'Tried to destroy resource which doesn''t inherit from oxTResource: ' + TObject(resource).ClassName);

   if(res <> nil) and (res.ReferenceCount <> -1) then begin
      {make sure we're not given any object}
      {$IFDEF OX_RESOURCE_DEBUG}
      if(res.ReferenceCount = 0) then begin
         log.w('Tried to dispose resource with a zero reference count ' + res.Path);
         log.w('Allocated at: ' + res.DebugAllocationPoint);

         if(res.DebugFreePoint <> '') then
            log.w('Freed at: ' + res.DebugFreePoint)
         else
            log.w('Current: ' + DumpCallStack(1));
      end;
      {$ELSE}
      ox.Assert(res.ReferenceCount > 0, 'Tried to dispose resource with a zero reference count');
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

   oxTResource(res) := nil;
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

   ox.Assert(ox.IsType(TObject(resource), oxTResource), 'Tried to free resource which doesn''t inherit from oxTResource ' + TObject(resource).ClassName);

   {$IFDEF OX_RESOURCE_DEBUG}
   res := oxTResource(resource);

   log.v('Resource freed: ' + res.Path + ' (' + sf(res.ReferenceCount) + ')');

   if(res.DebugFreed) then begin
      log.w('Resource ' + res.Path + ' already freed (' + sf(res.ReferenceCount) + '), ' + res.ClassName);

      if(res.DebugAllocationPoint <> '') then
         log.w('Allocated at: ' + res.DebugAllocationPoint);

      log.w('Current: ' + DumpCallStack(1));
      exit;
   end;

   if(res.ReferenceCount = 0) then begin
      log.w('Resource ' + res.Path + ' should already have been freed (' + sf(res.ReferenceCount) + ', ' + res.ClassName + ')');

      if(res.DebugAllocationPoint <> '') then
         log.w('Allocated at: ' + res.DebugAllocationPoint);

      if(res.DebugFreePoint <> '') then
         log.w('Freed at: ' + res.DebugFreePoint);

      log.v('Current at: ' + DumpCallStack(1));
   end;

   res.DebugFreed := true;
   res.DebugFreePoint := DumpCallStack(1);
   res.FreeInResourceMethod := true;

   oxTResource(resource) := nil;
   exit;
   {$ENDIF}

   FreeObject(resource);
end;

procedure oxTResourceGlobal.Add(pool: oxTResourcePool);
begin
   Pools.Add(pool);
end;

function oxTResourceGlobal.Find(pool: oxTResourcePool): loopint;
var
   i: loopint;

begin
   for i := 0 to Pools.n - 1 do begin
      if(Pools.List[i] = pool) then
         exit(i);
   end;

   Result := -1;
end;

procedure oxTResourceGlobal.Remove(pool: oxTResourcePool);
var
   i: loopint;

begin
   i := Find(pool);

   if(i > -1) then
      Pools.Remove(i);
end;

{ oxTResourcePool }

constructor oxTResourcePool.Create();
begin
   Increment := oxRESOURCE_POOL_INCREMENT;
   Name := 'unknown';

   oxResource.Add(Self);
end;

destructor oxTResourcePool.Destroy();
begin
   inherited Destroy;

   oxResource.Remove(Self);
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
   ox.Assert(resource.Pool = nil, 'resource being added to a pool is already part of some other pool');

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
   ox.Assert(true, 'Load method not overriden for resource pool of type ' + ClassName);
end;

INITIALIZATION
   oxResource.Pools.InitializeValues(oxResource.Pools);

END.
