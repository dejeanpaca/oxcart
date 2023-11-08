{
   uPreallocatedArray, preallocated array list class
   Copyright (C) Dejan Boras 2017.

   Started on:    15.05.2017.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}{$MODESWITCH TYPEHELPERS}
UNIT uPreallocatedArray;

INTERFACE

   USES
      sysutils, uStd;

TYPE
   { TPreallocatedArrayListClass }

   {helps to maintain a list of elements in an array}
   generic TPreallocatedArrayListClass<T> = class
      {step to increment the list size by}
      Increment: loopint;
      {should memory be initialized when allocation is done}
      InitializeMemory: boolean;

      {elements in the list}
      n,
      {total number of allocated elements}
      a: longint;
      {array(list) of the elements}
      List: array of T;

      {allocate specified number of elements (allocates to the multiple of Increment)}
      procedure Allocate(count: loopint);
      {increase allocated number of elements by specified count (allocates to the multiple of Increment)}
      procedure AllocateInc(count: loopint);
      {allocates memory to insert count elements at given index, and moves out other elements to free the space}
      procedure InsertRange(index, count: loopint);

      {add a single value to the array}
      function AddTo(var p: T): boolean;
      function Add(p: T): boolean;
      {add two values}
      function AddTo(var p, z: T): boolean;
      function Add(p, z: T): boolean;
      {dispose of the array}
      procedure Dispose();

      {remove an elements from the array, and stack the others down}
      procedure Remove(index: loopint);
      {remove a range of elements}
      procedure RemoveRange(index, count: loopint);

      {find the specified element in the array, or returns -1 if nothing foun d (uses CompareMem)}
      function Find(const what: T): loopint;
      {check if the specified element already exists in the array (uses CompareMem)}
      function Exists(const what: T): boolean;

      {set the size of the array (will set both n and a to the same size)}
      procedure SetSize(size: longint);
      {get a pointer to the last element}
      function GetLast(): pointer;
   end;

   TPreallocatedObjectsArrayListObject = specialize TPreallocatedArrayListClass<TObject>;

IMPLEMENTATION

{ TPreallocatedArrayListClass }

procedure TPreallocatedArrayListClass.Allocate(count: loopint);
var
   pa,
   remainder: loopint;

begin
   assert(Increment <> 0, 'Increment is zero for preallocated list');
   pa := a;
   a := count;

   if(Increment > 0) then begin
      remainder := a mod Increment;

      if(remainder <> 0) then
         a := a + Increment - remainder;
   end;

   if(n > a) then
      n := a;

   SetLength(List, a);

   {initialize memory}
   if(InitializeMemory) then begin
      if(pa = 0) then
         ZeroPtr(@List[0], SizeOf(T) * (count))
      else if(pa < a) then
         ZeroPtr(@List[pa], SizeOf(T) * (a - pa))
   end;
end;

procedure TPreallocatedArrayListClass.AllocateInc(count: loopint);
var
   pa,
   remainder: loopint;

begin
   assert(Increment <> 0, 'Increment is zero for preallocated list');
   pa := a;
   inc(a, count);

   if(Increment > 0) then begin
      remainder := a mod Increment;

      if(remainder <> 0) then
         a := a + Increment - remainder;
   end;

   SetLength(List, a);

   {initialize memory}
   if(InitializeMemory) then
      ZeroPtr(@List[pa], SizeOf(T) * (a - pa));
end;

procedure TPreallocatedArrayListClass.InsertRange(index, count: loopint);
var
   i: loopint;

begin
   {allocate more memory if needed}
   if(a < n + count) then
      AllocateInc(n + count - a);

   inc(n, count);

   {move existing items out of way if required}
   if(index < n) then begin
      for i := (n - 1) downto index do begin
         List[i + count] := List[i];
      end;
   end;
end;

function TPreallocatedArrayListClass.AddTo(var p: T): boolean;
begin
   assert(Increment <> 0, 'Increment is zero for preallocated list');

   inc(n);

   if(a < n) then
      AllocateInc(1);

   List[n - 1] := p;
   Result := true;
end;

function TPreallocatedArrayListClass.Add(p: T): boolean;
begin
   assert(Increment <> 0, 'Increment is zero for preallocated list');

   inc(n);

   if(a < n) then
      AllocateInc(Increment);

   List[n - 1] := p;
   Result := true;
end;

function TPreallocatedArrayListClass.AddTo(var p, z: T): boolean;
begin
   result := AddTo(p);

   if(result) then
      result := AddTo(z);
end;

function TPreallocatedArrayListClass.Add(p, z: T): boolean;
begin
   result := Add(p);

   if(result) then
      result := Add(z);
end;

procedure TPreallocatedArrayListClass.Dispose();
begin
   SetLength(list, 0);
   a := 0;
   n := 0;
end;

procedure TPreallocatedArrayListClass.Remove(index: loopint);
var
   i: loopint;

begin
   if(index < n) then begin
      {move all items above below}
      if(index < n - 1) then begin
         for i := index to (n - 2) do
            Move(List[i + 1], List[i], SizeOf(T));
      end;

      dec(n);
   end;
end;

procedure TPreallocatedArrayListClass.RemoveRange(index, count: loopint);
var
   i: loopint;

begin
   {move any items after the removed ones back over the removed items}
   if(count > 0) and (index < n) then begin
      if(index + count >= n) then
         count := n - index;

      for i := (index + count) to (n - 1) do begin
         List[i - count] := List[i];
      end;

      n := n - count;
   end;
end;

function TPreallocatedArrayListClass.Find(const what: T): loopint;
var
   i: loopint;

begin
   for i := 0 to (n - 1) do begin
      if (CompareMem(@list[i], @what, SizeOf(T))) then
         exit(i);
   end;

   Result := -1;
end;

function TPreallocatedArrayListClass.Exists(const what: T): boolean;
begin
   result := Find(what) > -1;
end;

procedure TPreallocatedArrayListClass.SetSize(size: longint);
begin
   n := size;
   a := size;

   SetLength(list, n);
end;

function TPreallocatedArrayListClass.GetLast(): pointer;
begin
   if(n > 0) then
      Result := @List[n - 1]
   else
      Result := nil;
end;


END.
