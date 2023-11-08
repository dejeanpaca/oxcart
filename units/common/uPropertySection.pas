{
   uPropertySection.pas
   Copyright (C) 2011. Dejan Boras

   Started On:    24.12.2011.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uPropertySection;

INTERFACE

TYPE
   {property section callbacks}
   TSetStringPropertyRoutine     = procedure(code: longint; const prop: string);
   TSetIntPropertyRoutine        = procedure(code: longint; prop: longint);
   TSetBooleanPropertyRoutine    = procedure(code: longint; prop: boolean);

   TGetStringPropertyRoutine     = function(code: longint): string;
   TGetIntPropertyRoutine        = function(code: longint): longint;
   TGetBooleanPropertyRoutine    = function(code: longint): boolean;

   {a property section}
   PPropertySection = ^TPropertySection;
   TPropertySection = record
      Name: string;

      {set property}
      setString: TSetStringPropertyRoutine;
      setInt: TSetIntPropertyRoutine;
      setBoolean: TSetBooleanPropertyRoutine;

      {get property}
      getString: TGetStringPropertyRoutine;
      getInt: TGetIntPropertyRoutine;
      getBoolean: TGetBooleanPropertyRoutine;

      Next: PPropertySection;
   end;

   {contains a list of registered property sections}
   TPropertySections = record
      s,
      e: PPropertySection;
   end;

   TPropertySectionGlobal = record
      list: TPropertySections;
      dummy: TPropertySection;

      {finds and returns a property section by name, returns nil if not found}
      function Get(const Name: string): PPropertySection;
      {registers a property section}
      procedure Register(var section: TPropertySection);

      {sets a string property}
      procedure SetString(const section: string; code: longint; const prop: string);
      {sets a integer property}
      procedure SetInt(const section: string; code: longint; prop: longint);
      {sets a boolean property}
      procedure SetBoolean(const section: string; code: longint; prop: boolean);

      function GetString(const section: string; code: longint): string;
      function GetInt(const section: string; code: longint): longint;
      function GetBoolean(const section: string; code: longint): boolean;
   end;

VAR
   propertySections: TPropertySectionGlobal;

IMPLEMENTATION

{ PROPERTY SECTIONS }

function TPropertySectionGlobal.Get(const name: string): PPropertySection;
var
   cur: PPropertySection = nil;

begin
   cur := list.s;
   if(cur <> nil) then repeat
      if(cur^.Name = name) then
         exit(cur);

      cur := cur^.Next;
   until (cur = nil);

   result := nil;
end;

procedure TPropertySectionGlobal.Register(var section: TPropertySection);
begin
   section.Next := nil;

   if(list.s = nil) then
      list.s := @section
   else
      list.e^.Next := @section;

   list.e := @section;
end;

{ SETTING PROPERTIES }

procedure TPropertySectionGlobal.SetString(const section: string; code: longint; const prop: string);
var
   pSection: PPropertySection;

begin
   pSection := Get(section);

   if(pSection <> nil) then
      pSection^.setString(code, prop);
end;

procedure TPropertySectionGlobal.SetInt(const section: string; code: longint; prop: longint);
var
   pSection: PPropertySection;

begin
   pSection := Get(section);

   if(pSection <> nil) then
      pSection^.setInt(code, prop);
end;

procedure TPropertySectionGlobal.SetBoolean(const section: string; code: longint; prop: boolean);
var
   pSection: PPropertySection;

begin
   pSection := Get(section);

   if(pSection <> nil) then
      pSection^.setBoolean(code, prop);
end;

{ GETTING PROPERTIES }

function TPropertySectionGlobal.GetString(const section: string; code: longint): string;
var
   pSection: PPropertySection;

begin
   pSection := Get(section);

   if(pSection <> nil) then begin
      result := pSection^.getstring(code)
   end else
      result := '';
end;

function TPropertySectionGlobal.GetInt(const section: string; code: longint): longint;
var
   pSection: PPropertySection;

begin
   pSection := Get(section);

   if(pSection <> nil) then begin
      result := pSection^.getInt(code)
   end else
      result := 0;
end;

function TPropertySectionGlobal.GetBoolean(const section: string; code: longint): boolean;
var
   pSection: PPropertySection;

begin
   pSection := Get(section);

   if(pSection <> nil) then begin
      result := pSection^.getBoolean(code)
   end else
      result := false;
end;

{ DUMMY PROPERTY SECTION }
{$PUSH}{$HINTS OFF}
procedure dummySetString (code: longint; const prop: string); begin end;
procedure dummySetInt (code: longint; prop: longint); begin end;
procedure dummySetBoolean (code: longint; prop: boolean); begin end;

function dummyGetString (code: longint): string; begin result := ''; end;
function dummyGetInt (code: longint): longint; begin result := 0; end;
function dummyGetBoolean (code: longint): boolean; begin result := false; end;
{$POP}

INITIALIZATION
   propertySections.dummy.Name         := 'dummy';

   propertySections.dummy.setString    := @dummySetString;
   propertySections.dummy.setInt       := @dummySetInt;
   propertySections.dummy.setBoolean   := @dummySetBoolean;

   propertySections.dummy.getString    := @dummyGetString;
   propertySections.dummy.getInt       := @dummyGetInt;
   propertySections.dummy.getBoolean   := @dummyGetBoolean;

   propertySections.dummy.Next         := nil;
END.
