{
   appukcNames, keycode name routines
   Copyright (C) 2008. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT appukcNames;

INTERFACE

   USES uStd;

CONST
   {$INCLUDE kcNames.inc}

TYPE
   appTKeyNamesGlobal = record
      {returns a pointer to a string containing the keycode name,
      returns nil if there is none}
      class function pGetCode(kc: longint): pshortstring; static;
      {returns a string containing the keycode name, returns empty if there is none}
      class function GetCode(kc: longint): string; static;
      {returns the key name, returns empty if there is none}
      class function Get(kc: longint): string; static;
      {finds a keycode by it's name, returns 0 if nothing found}
      class function FindCode(const keycode: string): longint; static;
   end;

VAR
   appkNames: appTKeyNamesGlobal;

IMPLEMENTATION

class function appTKeyNamesGlobal.pGetCode(kc: longint): pshortstring;
begin
   if(kc < appkcKeyCodeNames) then
      result := kcKeyCodeNames[kc]
   else 
      result := @EmptyShortString;
end;

class function appTKeyNamesGlobal.GetCode(kc: longint): string;
var
   pName: pshortstring = nil;

begin
   if(kc < appkcKeyCodeNames) then 
      pName := kcKeyCodeNames[kc];

   if(pName <> nil) then
      result := pName^
   else 
      result := '';
end;

class function appTKeyNamesGlobal.Get(kc: longint): string;
var
   pName: pshortstring = nil;

begin
   if(kc < appkcKeyCodeNames) then
      pName := kcKeyCodeNames[kc];

   if(pName <> nil) then
      result := copy(pName^, 3, 255)
   else 
      result := '';
end;

class function appTKeyNamesGlobal.FindCode(const keycode: string): longint;
var
   i: longint;
   kc: string;

begin
   kc := LowerCase(keycode);

   for i := 0 to (appkcKeyCodeNames-1) do begin
      if(kcKeyCodeNames[i] <> nil) then
         if(kc = LowerCase(kcKeyCodeNames[i]^)) then
            exit(i);
   end;

   result := 0;
end;

END.
