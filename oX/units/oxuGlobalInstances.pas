{
   oxuGlobalInstances, handles global instances
   Copyright (C) 2017. Dejan Boras

   Started On:    12.06.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuGlobalInstances;

INTERFACE

   USES
      uStd;

TYPE
   oxTGlobalInstanceMethod = function(): TObject;

   oxPGlobalInstance = ^oxTGlobalInstance;
   oxTGlobalInstance = record
      InstanceType: TClass;
      InstanceName: String;
      InstanceMethod: oxTGlobalInstanceMethod;
      Location: pointer;
      Allocate,
      CopyOverReference,
      External: boolean;
   end;

   oxTGlobalInstancesList = specialize TPreallocatedArrayList<oxTGlobalInstance>;

   oxTGlobalInstancesReferenceChangeCallback = procedure(const instanceType: string; newReference: Pointer);
   oxTGlobalInstancesReferenceChangeCallbacks = specialize TPreallocatedArrayList<oxTGlobalInstancesReferenceChangeCallback>;

   { oxTGlobalInstancesReferenceChangeCallbacksHelper }

   oxTGlobalInstancesReferenceChangeCallbacksHelper = record helper for oxTGlobalInstancesReferenceChangeCallbacks
      procedure Call(const instanceType: string; newReference: pointer);
   end;

   { oxTGlobalInstances }

   oxTGlobalInstances = class
      List: oxTGlobalInstancesList;
      OnReferenceChange: oxTGlobalInstancesReferenceChangeCallbacks;

      constructor Create; virtual;

      {add class based instance}
      function Add(instanceType: TClass; location: pointer; method: oxTGlobalInstanceMethod = nil): oxPGlobalInstance;
      {add instance of other type (record)}
      function Add(const instanceName: string; location: pointer): oxPGlobalInstance;

      procedure Initialize();
      procedure Deinitialize();

      {find an instance reference by classname, and return the index, or -1 if nothing found}
      function FindReference(const cName: string): loopint;
      {find an instance reference by classname, and return the instance reference, or -1 if nothing found}
      function FindInstance(const cName: string): TObject;
      {find an instance reference by type name, and return pointer to the instance, or -1 if nothing found}
      function FindInstancePtr(const typeName: string): pointer;

      procedure CopyOver(target: oxTGlobalInstances);
      procedure CopyOverReferences(target: oxTGlobalInstances);
   end;

VAR
   oxGlobalInstances,

   oxExternalGlobalInstances: oxTGlobalInstances;

IMPLEMENTATION

{ oxTGlobalInstancesReferenceChangeCallbacksHelper }

procedure oxTGlobalInstancesReferenceChangeCallbacksHelper.Call(const instanceType: string; newReference: pointer);
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      List[i](instanceType, newReference);
   end;
end;

{ oxTGlobalInstances }

constructor oxTGlobalInstances.Create;
begin
   oxTGlobalInstancesList.Initialize(List);
   OnReferenceChange.Initialize(OnReferenceChange);
end;

function oxTGlobalInstances.Add(instanceType: TClass; location: pointer; method: oxTGlobalInstanceMethod): oxPGlobalInstance;
var
   instance: oxTGlobalInstance;

begin
   ZeroOut(instance, SizeOf(instance));
   instance.InstanceType := instanceType;
   instance.InstanceName := instanceType.ClassName;
   instance.Location := location;
   instance.Allocate := true;
   instance.InstanceMethod := method;

   List.Add(instance);

   result := List.GetLast();
end;

function oxTGlobalInstances.Add(const instanceName: string; location: pointer): oxPGlobalInstance;
var
   instance: oxTGlobalInstance;

begin
   ZeroOut(instance, SizeOf(instance));
   instance.InstanceName := instanceName;
   instance.Location := location;

   List.Add(instance);

   result := List.GetLast();
end;

procedure oxTGlobalInstances.Initialize();
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].Allocate) and (TObject(List.List[i].Location^) = nil) then begin
         if(List.List[i].InstanceMethod <> nil) then
            TObject(List.List[i].Location^) := List.List[i].InstanceMethod()
         else
            TObject(List.List[i].Location^) := List.List[i].InstanceType.Create();
      end;
   end;
end;

procedure oxTGlobalInstances.Deinitialize();
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].Allocate) and (not List.List[i].External) then
         FreeObject(List.List[i].Location^);
   end;
end;

function oxTGlobalInstances.FindReference(const cName: string): loopint;
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].InstanceName = cName) then
        exit(i);
   end;

   result := -1;
end;

function oxTGlobalInstances.FindInstance(const cName: string): TObject;
var
   ref: longint;
   instance: oxPGlobalInstance;

begin
   ref := FindReference(cName);

   if(ref > -1) then begin
      instance := @List.List[ref];

      exit(TObject(instance^.Location^));
   end;

   result := nil;
end;

function oxTGlobalInstances.FindInstancePtr(const typeName: string): pointer;
var
   ref: longint;
   instance: oxPGlobalInstance;

begin
   ref := FindReference(typeName);

   if(ref > -1) then begin
      instance := @List.List[ref];

      exit(instance^.Location);
   end;

   result := nil;
end;

procedure oxTGlobalInstances.CopyOver(target: oxTGlobalInstances);
var
   i: loopint;

begin
   target.List.Allocate(List.n);

   for i := 0 to List.n - 1 do begin
      target.List.List[i] := List.List[i];
   end;
end;

procedure oxTGlobalInstances.CopyOverReferences(target: oxTGlobalInstances);
var
   i,
   ref: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].CopyOverReference) then begin
         ref := target.FindReference(List.List[i].InstanceType.ClassName);

         if(ref > -1) then begin
            target.List.List[ref].External := true;
            TObject(target.List.List[ref].Location^) := TObject(List.List[i].Location^);

            target.OnReferenceChange.Call(List.List[i].InstanceType.ClassName, pointer(target.List.List[ref].Location^));
         end;
      end;
   end;
end;

function instanceGlobal(): TObject;
begin
   Result := oxTGlobalInstances.Create();
end;

INITIALIZATION
   oxGlobalInstances := oxTGlobalInstances.Create();

   oxGlobalInstances.Add(oxTGlobalInstances, @oxGlobalInstances, @instanceGlobal)^.Allocate := False;

FINALIZATION
   FreeObject(oxGlobalInstances);

END.
