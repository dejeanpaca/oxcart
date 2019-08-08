{
   uiuControl, Basis for all ui controls (windows and widgets)
   Copyright (C) 2016. Dejan Boras

   Started On:    27.05.2016.
}

{$INCLUDE oxdefines.inc}
UNIT uiuControls;

INTERFACE

   USES
      uStd,
      {ui}
      uiuControl, uiuTypes, uiuZOrder;

TYPE
   { uiTControls }

   uiTControls = record
      public
      s: loopint;
      w: uiTPreallocatedControlList;
      z: uiTZOrder;

      procedure Initialize();
      class procedure Initialize(out control: uiTControls); static;

      procedure Insert(child: uiTControl);
      procedure Remove(index: longint);
      procedure Remove(child: uiTControl);

      function GetTop(): loopint;
      function GetBottom(): loopint;
      function GetTotalHeight(): loopint;

      {returns the level of a control if it exists, otherwise -1}
      function Exists(what: uiTControl): loopint;
   end;

   uiTPreallocatedControlList = specialize TSimpleList<uiTControl>;

IMPLEMENTATION

{ uiTControls }

procedure uiTControls.Initialize();
begin
   s := -1;
   z.Entries.InitializeValues(z.Entries);
   w.InitializeValues(w);
end;

class procedure uiTControls.Initialize(out control: uiTControls);
begin
   ZeroPtr(@control, SizeOf(control));
   control.Initialize();
end;

procedure uiTControls.Insert(child: uiTControl);
begin
   w.Add(child);
   z.Add(child);
end;

procedure uiTControls.Remove(index: longint);
begin
   if(index > -1) and (index < w.n) then begin
      z.Remove(w.List[index]);
      w.Remove(index);
   end;
end;

procedure uiTControls.Remove(child: uiTControl);
var
   i: loopint;

begin
   for i := 0 to (w.n - 1) do begin
      if(w[i] = child) then begin
         Remove(i);
         exit;
      end;
   end;
end;

function uiTControls.GetTop(): loopint;
var
   i: loopint;

begin
   Result := 0;

   if(w.n > 0) then begin
      Result := w.List[0].Position.y;

      for i := 0 to (w.n - 1) do begin
         if(w.List[i].Position.y > Result) then
            Result := w.List[i].Position.y;
      end;
   end;
end;

function uiTControls.GetBottom(): loopint;
var
   i: loopint;

begin
   Result := 0;

   if(w.n > 0) then begin
      Result := w.List[0].Position.y - w.List[0].Dimensions.h + 1;

      for i := 0 to (w.n - 1) do begin
         if((w.List[i].Position.y - w.List[i].Dimensions.h + 1) < Result) then
            Result := w.List[i].Position.y - w.List[i].Dimensions.h + 1;
      end;
   end;
end;

function uiTControls.GetTotalHeight(): loopint;
begin
   Result := GetTop() - GetBottom();
end;

function uiTControls.Exists(what: uiTControl): loopint;
var
   i: loopint;

begin
   Result := -1;

   {try to find in the current window}
   if(w.n > 0) then begin
      for i := 0 to (w.n - 1) do
         if(w[i] = what) then
            exit(w[i].Level);
   end;
end;

END.
