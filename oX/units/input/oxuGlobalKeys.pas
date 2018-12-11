{
   oxuGlobalKeys, oX global key management
   Copyright (C) 2010. Dejan Boras

   Started On:    11.04.2010.

   Description:   This unit manages global keys and their handlers. It can
   register a handler for a specified key. These callback routines are called
   whenever a key was unprocessed by the UI (because it was either used by a
   widget or a window control routine) by the oX window control. A good example
   of such a global key handler is the console, which uses the kcTIDLE (by
   default) key to call up the console. The console should be available
   anywhere and therefore it hooks a global key. Note that global keys are
   still processed by the app and UI before they reach the oX window control.
}

{$INCLUDE oxdefines.inc}
UNIT oxuGlobalKeys;

INTERFACE

   USES
      uStd, uLog, appukcNames, appuKeys,
      {oX}
      uOX, oxuWindowTypes;

TYPE
   oxTGlobalKeyHandlerCallback = procedure(wnd: oxTWindow);

   oxPGlobalKeyHandler = ^oxTGlobalKeyHandler;
   oxTGlobalKeyHandler = record
      Key: appTKey;

      Pressed,
      Released: oxTGlobalKeyHandlerCallback; {callback routine}
      Name: string; {handler name}
   end;

   oxTGlobalKey = record
      Key: appTKey;

      h: oxPGlobalKeyHandler; {hooked handler}
   end;

   { oxTGlobalKeysGlobal }

   oxTGlobalKeysGlobal = record
      nKeys: longint;
      List: array of oxTGlobalKey;

      {initialize records}
      procedure Init(out gkh: oxTGlobalKeyHandler);
      procedure Init(out gk: oxTGlobalKey);

      {add a new empty global key entry}
      function Add(): longint;
      {find an empty global key entry}
      function FindEmpty(): longint;
      {find a global key with that matches}
      function Find(keyCode: TKeyCode; keyState: TKeyState): longint;
      {find a global key with that matches}
      function Find(const k: appTKey): longint;

      {hooks a specified key handler, returns false if key already hooked to a handler}
      function Hook(const h: oxTGlobalKeyHandler): boolean;
      {unhooks a specified key handler, returns false if no specified handler found}
      function Unhook(const h: oxTGlobalKeyHandler): boolean;
      {calls a key handler with specified key code and state,
      returns false if no key handler was called}
      function Call(keyCode: longword; keyState: TBitSet; wnd: oxTWindow): boolean;
      function Call(const k: appTKey; wnd: oxTWindow): boolean;

      procedure Dispose();
   end;

VAR
   oxGlobalKeys: oxTGlobalKeysGlobal;

IMPLEMENTATION

procedure oxTGlobalKeysGlobal.Init(out gkh: oxTGlobalKeyHandler);
begin
   ZeroOut(gkh, SizeOf(gkh));
   gkh.Name := '';
end;

procedure oxTGlobalKeysGlobal.Init(out gk: oxTGlobalKey);
begin
   ZeroOut(gk, SizeOf(gk));
end;

function oxTGlobalKeysGlobal.Add(): longint;
var
   n: longint = -1;

begin
   inc(nKeys);

   try
      SetLength(List, nKeys);

      n := nKeys-1;
      Init(List[n]);
   except
      exit(-1);
   end;

   Result := n;
end;

function oxTGlobalKeysGlobal.Find(keyCode: TKeyCode; keyState: TKeyState): longint;
var
   k: appTKey;

begin
   k.Assign(keyCode, keyState);

   Result := Find(k);
end;

function oxTGlobalKeysGlobal.Find(const k: appTKey): longint;
var
   i: longint;

begin
   {look for a key}
   if(nKeys > 0) then begin
      for i := 0 to (nKeys - 1) do begin
         if(k.Equal(List[i].Key.Code, List[i].Key.State)) then
            exit(i);
      end;
   end;

   Result := -1
end;

function oxTGlobalKeysGlobal.FindEmpty(): longint;
var
   i: longint;

begin
   if(nKeys > 0) then
      for i := 0 to (nKeys - 1) do
         if(List[i].Key.Code = 0) then
            exit(i);

   Result := -1;
end;

function oxTGlobalKeysGlobal.Hook(const h: oxTGlobalKeyHandler): boolean;
var
   i: longint;

procedure DoHook();
begin
   List[i].Key.Code := h.Key.Code;
   List[i].Key.State := h.Key.State;
   List[i].h := @h;
end;

begin
   Result := false;

   {first let's see if there is any handler already hooked to the key}
   i := Find(h.Key.Code, h.Key.State);
   if(i = -1) then begin
      {if not then we'll find an empty spot}
      i := FindEmpty();

      if(i = -1) then begin
         {if there are no empty spots}
         i := Add();

         if(i < 0) then
            exit;
      end;

      DoHook();
      Result := true;
   end else begin
      {key already hooked to another handler}
      if(List[i].h = @h) then
         log.i('Global key handler ' + List[i].h^.Name + ' already has global key (' + appkNames.GetCode(h.Key.Code) + ') hooked.')
      else
         log.i('Global key(' + appkNames.GetCode(h.Key.Code) + ') already used by ' + List[i].h^.Name);
   end;
end;

function oxTGlobalKeysGlobal.Unhook(const h: oxTGlobalKeyHandler): boolean;
var
   i: longint;

begin
   i := Find(h.Key.Code, h.Key.State);

   if(i > -1) and (List[i].h = @h) then begin
      List[i].Key.Code := 0;
      Result := true;
   end else
      Result := false;
end;

function oxTGlobalKeysGlobal.Call(keyCode: longword; keyState: TBitSet; wnd: oxTWindow): boolean;
var
   k: appTKey;

begin
   ZeroPtr(@k, SizeOf(k));

   k.Code := keyCode;
   k.State := keyState;

   Result := Call(k, wnd);
end;

function oxTGlobalKeysGlobal.Call(const k: appTKey; wnd: oxTWindow): boolean;
var
   i: longint;

begin
   i := Find(k);

   if(i > -1) then begin
      Result := true;

      if(k.IsPressed()) then begin
         if(List[i].h^.Pressed <> nil) then
            List[i].h^.Pressed(wnd)
      end else if (k.Released()) then begin
         if(List[i].h^.Released <> nil) then
            List[i].h^.Released(wnd);
      end;
   end else
      Result := false;
end;

procedure oxTGlobalKeysGlobal.Dispose();
begin
   SetLength(List, 0);
   nKeys := 0;
end;

procedure DeInitialize();
begin
   oxGlobalKeys.Dispose();
end;

INITIALIZATION
   ox.Init.dAdd('globalkeys', @DeInitialize);

END.

