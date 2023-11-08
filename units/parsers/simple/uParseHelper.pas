{
   uParseHelper, helps with parsing strings
   Copyright (C) 2010. Dejan Boras

   Started On:    01.05.2010.
}

{$MODE OBJFPC}{$H+}
UNIT uParseHelper;

INTERFACE

   USES StringUtils;

{parses an array of strings and returns an array of single precision floats}
function strParseSingle(n: longint; s: TAnsiStringArray; var f: single): boolean;
{parses an array of strings and returns an array of ints}
function strParseInt32(n: longint; s: TAnsiStringArray; var int: longint): boolean;
function strParseUInt32(n: longint; s: TAnsiStringArray; var uint: longword): boolean;

IMPLEMENTATION

function strParseSingle(n: longint; s: TAnsiStringArray; var f: single): boolean;
var   
   i, code: longint;
   a: array[0..65535] of single absolute f;

begin
   result := false;

   for i := 0 to (n-1) do begin
      val(s[i], a[i], code);
      if(code <> 0) then
         exit;
   end;

   result := true;
end;

function strParseInt32(n: longint; s: TAnsiStringArray; var int: longint): boolean;
var   
   i,
   code: longint;
   a: array[0..65535] of longint absolute int;

begin
   result := false;

   for i := 0 to (n-1) do begin
      val(s[i], a[i], code);
      if(code <> 0) then
         exit;
   end;

   result := true;
end;

function strParseUInt32(n: longint; s: TAnsiStringArray; var uint: longword): boolean;
var   
   i,
   code: longint;
   a: array[0..65535] of longword absolute uint;

begin
   result := false;

   for i := 0 to (n-1) do begin
      val(s[i], a[i], code);
      if(code <> 0) then
         exit;
   end;

   result := true;
end;

END.
