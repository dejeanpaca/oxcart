{
   uiuZOrder, dUI Z order handling
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT uiuZOrder;

INTERFACE

USES
   uStd, uiuControl;

CONST
   uiwzcDefaultZIndex: longint   = 0;

TYPE
   uiTZOrderEntries = specialize TPreallocatedArrayList<uiTControl>;

   { uiTZOrder }

   uiTZOrder = record
      Entries: uiTZOrderEntries;

      {will put the selected window in the z order to the top(front) of the z order}
      procedure MoveToTop(idx: longint);
      procedure MoveToTop(p: TObject);
      {add a new control to the z order}
      procedure Add(p: uiTControl);
      {remove the specified window from the z order}
      procedure Remove(idx: longint);
      procedure Remove(p: uiTControl);
      {find Z of the specified control}
      function GetZ(p: uiTControl): longint;
      {dispose a z order}
      procedure Dispose();
      {rotates the Z order}
      procedure Rotate();

      {initialize the record}
      procedure Init(out z: uiTZOrder);
   end;

IMPLEMENTATION

procedure uiTZOrder.Init(out z: uiTZOrder);
begin
   ZeroPtr(@z, SizeOf(z));
end;

procedure uiTZOrder.MoveToTop(idx: longint);
var
   i,
   count,
   max: longint;

   t: uiTControl;

begin
   {make sure the specified entry index(w) is in range}
   if(Entries.n > 1) and (idx < (Entries.n - 1)) then begin
      {maximum (top) is the index of the highest entry in the array with the same or lower z index}
      max := idx;

      if(idx < Entries.n - 1) then begin
         for i := (idx + 1) to Entries.n - 1 do begin
            if(Entries.List[i].ZIndex <= Entries.List[idx].ZIndex) then
               max := i
            else
               break;
         end;
      end;

      {determine range of numbers in-between}
      count := max - idx + 1;

      {swap the entries}

      {if 2 entries or more}
      if(count > 1) then begin
         t := Entries.List[idx];

         {move all windows from top to (specified + 1) backwards by one position}
         for i := idx to (max - 1) do
            Entries.List[i] := Entries.List[i + 1];

         {put the selected entry on top}
         Entries.List[max] := t;
      end;
   end;
end;

procedure uiTZOrder.MoveToTop(p: TObject);
var
   i: longint;

begin
   for i := 0 to (Entries.n - 1) do begin
      if(Entries[i] = p) then begin
         {if found move it to top}
         MoveToTop(i);
         exit;
      end;
   end;
end;

procedure uiTZOrder.Add(p: uiTControl);
var
   i: longint;
   j: longint;

begin
   Entries.Add(p);

   {find the position for this entry}
   i := 0;

   for i := 0 to (Entries.n - 1) do begin
      if(p.ZIndex < Entries.List[i].ZIndex) then
         break;
   end;

   {move the rest to the right of the position}
   if(i < Entries.n - 1) then begin
      for j := Entries.n - 1 downto (i + 1) do
         Entries.List[j] := Entries.List[j - 1];
   end;

   {insert this entry}
   Entries.List[i] := p;
end;

procedure uiTZOrder.Remove(idx: longint);
var
   j: longint;

begin
   if(idx >= 0) and (idx < Entries.n) then begin
      Entries.List[idx] := nil;

      {move the specified entry to top of array and 'remove' it by shrinking the array length by 1 entry}
      if(idx < Entries.n - 1) then
         for j := idx to Entries.n - 2 do
            Entries.List[j] := Entries.List[j + 1];

      dec(Entries.n);
   end;
end;

procedure uiTZOrder.Remove(p: uiTControl);
var
   w,
   i: longint;

begin
   if(Entries.n > 0) then begin
      w := -1;

      {first find the window}
      for i := 0 to (Entries.n - 1) do begin
         if(Entries.List[i] = p) then begin
            w := i;
            break;
         end;
      end;

      {then remove it if found}
      if(w > -1) then
         Remove(w);
   end;
end;

function uiTZOrder.GetZ(p: uiTControl): longint;
var
   i: longint;

begin
   {first find the window}
   for i := 0 to (Entries.n - 1) do begin
      if(Entries.List[i] = p) then
         exit(Entries.List[i].ZIndex);
   end;

   Result := 0;
end;

procedure uiTZOrder.Dispose();
begin
   Entries.Dispose();
end;

procedure uiTZOrder.Rotate();
var
   i: longint;
   t: uiTControl;

begin
   if(Entries.n > 1) then begin
      {get the top window}
      t := Entries.List[Entries.n - 1];

      {move all windows up}
      for i := (Entries.n - 1) downto 1 do
         Entries.List[i] := Entries.List[i - 1];

      {put the top window to bottom}
      Entries.List[0] := t;
   end;
end;

END.
