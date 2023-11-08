{
   stdDataTypeCodeNames, standard data type code names
   Copyright (c) 2010. Dejan Boras

   This is a list of standardised data type codes used within many of my 
   programs and libraries. Instead of using multiple list of codes that do the
   same thing I've created a standardised list.
}

{$MODE OBJFPC}{$H+}
UNIT stdDataTypeCodeNames;

INTERFACE

   USES uStd;

CONST
   {$INCLUDE stdDataTypeCodeNames.inc}

{gets the data type code name for the specified code}
function  stdGetDTCodeName(code: longint): pshortstring;
procedure stdGetDTCodeName(code: longint; var name: string);
procedure stdGetDTCodeNameWP(code: longint; var s: string);
{gets the data type code for the specified name}
function stdGetDTCode(const name: string): longint;
function stdGetDTCodeWP(const name: string): longint;

IMPLEMENTATION

function stdGetDTCodeName(code: longint): pshortstring;
begin
   result := nil;
   if(code >= 0) and (code < dtcDataTypeCodeNames) then begin
      result := cDataTypeCodeNames[code];
   end;
end;

procedure stdGetDTCodeName(code: longint; var name: string);
begin
   name := '';
   if(code >= 0) and (code < dtcDataTypeCodeNames) then begin
      if(cDataTypeCodeNames[code] <> nil) then
         name := cDataTypeCodeNames[code]^;
   end;
end;

procedure stdGetDTCodeNameWP(code: longint; var s: string);
var
   p: pshortstring;

begin
   s := '';

   p := stdGetDTCodeName(code);
   if(p <> nil) then 
      s := 'dtc'+p^;
end;

function stdGetDTCode(const name: string): longint;
var
   i: longint;
   s: string;


begin
   result := -1;
   if(Length(name) <> 0) then begin
      s := UpCase(name);

      for i := 0 to (dtcDataTypeCodeNames-1) do
         if(cDataTypeCodeNames[i] <> nil) then
            if(s = cDataTypeCodeNames[i]^) then 
               exit(i);
   end;
end;

function stdGetDTCodeWP(const name: string): longint;
begin
   result := stdGetDTCode(copy(name, 1, 3));
end;

END.
