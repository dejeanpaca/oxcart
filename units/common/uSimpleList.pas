{
   uSimpleList, simple list class
   Copyright (C) Dejan Boras 2017.
}

{$INCLUDE oxheader.inc}
UNIT uSimpleList;

INTERFACE

   USES
      sysutils, uStd;

TYPE
   {helps to maintain a list of elements in an array}

   { TSimpleListClass }

   generic TSimpleListClass<T> = class
      {step to increment the list size by}
      Increment: loopint;

      {elements in the list}
      n,
      {total number of allocated elements}
      a: longint;
      {array(list) of the elements}
      List: array of T;

      constructor Create(); virtual;

      {allocate specified number of elements (allocates to the multiple of Increment)}
      procedure Allocate(count: loopint);
      {increase allocated number of elements by specified count (allocates to the multiple of Increment)}
      procedure AllocateInc(count: loopint);
      {increase allocated number of elements by specified count (allocates to the multiple of Increment)}
      procedure RequireAllocate(count: loopint);
      {allocates memory to insert one element at given index}
      procedure Insert(index: loopint);
      {insert element at the given index}
      procedure Insert(index: loopint; var p: T);
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

      {remove all elements}
      procedure RemoveAll();
      {remove last element}
      procedure RemoveFirst();
      {remove last element}
      procedure RemoveLast();
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

   TSimpleObjectsList = specialize TSimpleListClass<TObject>;

IMPLEMENTATION

{ TSimpleListClass }

constructor TSimpleListClass.Create();
begin
   Increment := 32;
end;

procedure TSimpleListClass.Allocate(count: loopint);
begin
   assert(Increment <> 0, 'Increment is zero for simple list');
   assert(count <> 0, 'Tried to allocate 0 elements');

   a := count;

   if(n > a) then
      n := a;

   SetLength(List, a);
end;

procedure TSimpleListClass.AllocateInc(count: loopint);
var
   remainder: loopint;

begin
   assert(Increment <> 0, 'Increment is zero for simple list');
   assert(count <> 0, 'Tried to allocate 0 elements');

   inc(a, count);

   if(Increment > 0) then begin
      remainder := a mod Increment;

      if(remainder <> 0) then
         a := a + Increment - remainder;
   end;

   SetLength(List, a);

   assert((a = Length(List)) and (a <> 0), 'Simple list has invalid length');
end;

procedure TSimpleListClass.RequireAllocate(count: loopint);
begin
   if(count > a) then
      Allocate(count);
end;

procedure TSimpleListClass.Insert(index: loopint);
var
   i: loopint;

begin
   {allocate more memory if needed}
   if(a < n + 1) then
      AllocateInc(n + 1 - a);

   {move existing items out of way if required}
   if(index < n) then begin
      for i := n downto index do begin
         List[i + 1] := List[i];
      end;
   end;

   inc(n, 1);
end;

procedure TSimpleListClass.Insert(index: loopint; var p: T);
begin
   Insert(index);

   List[index] := p;
end;

procedure TSimpleListClass.InsertRange(index, count: loopint);
var
   i: loopint;

begin
   {allocate more memory if needed}
   if(a < n + count) then
      AllocateInc(n + count - a);

   {move existing items out of way if required}
   if(index < n) then begin
      for i := n - 1 downto index do begin
         List[i + count] := List[i];
      end;
   end;

   inc(n, count);
end;

function TSimpleListClass.AddTo(var p: T): boolean;
begin
   assert(Increment <> 0, 'Increment is zero for simple list');

   inc(n);

   if(a < n) then
      AllocateInc(1);

   List[n - 1] := p;
   Result := true;
end;

function TSimpleListClass.Add(p: T): boolean;
begin
   assert(Increment <> 0, 'Increment is zero for simples list');

   inc(n);

   if(a < n) then
      AllocateInc(Increment);

   List[n - 1] := p;
   Result := true;
end;

function TSimpleListClass.AddTo(var p, z: T): boolean;
begin
   Result := AddTo(p);

   if(Result) then
      Result := AddTo(z);
end;

function TSimpleListClass.Add(p, z: T): boolean;
begin
   Result := Add(p);

   if(Result) then
      Result := Add(z);
end;

procedure TSimpleListClass.Dispose();
begin
   SetLength(list, 0);
   a := 0;
   n := 0;
end;

procedure TSimpleListClass.RemoveAll();
begin
   n := 0;
end;

procedure TSimpleListClass.RemoveFirst();
begin
   if(n > 0) then
      Remove(0);
end;

procedure TSimpleListClass.RemoveLast();
begin
   if(n > 0) then
      Remove(n - 1);
end;

procedure TSimpleListClass.Remove(index: loopint);
var
   i: loopint;

begin
   if(index < n) then begin
      {move all items above below}
      if(index < n - 1) then begin
         for i := index to (n - 2) do
            List[i] := List[i + 1];
      end;

      dec(n);
   end;
end;

procedure TSimpleListClass.RemoveRange(index, count: loopint);
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

function TSimpleListClass.Find(const what: T): loopint;
var
   i: loopint;

begin
   for i := 0 to (n - 1) do begin
      if (CompareMem(@list[i], @what, SizeOf(T))) then
         exit(i);
   end;

   Result := -1;
end;

function TSimpleListClass.Exists(const what: T): boolean;
begin
   Result := Find(what) > -1;
end;

procedure TSimpleListClass.SetSize(size: longint);
begin
   assert(size >= 0, 'Allocation cannot be set to negative value');

   n := size;
   a := size;

   SetLength(list, n);
end;

function TSimpleListClass.GetLast(): pointer;
begin
   if(n > 0) then
      Result := @List[n - 1]
   else
      Result := nil;
end;

END.
