{
   uLazXMLUtils, helper utilities for lazarus xml
   Copyright (C) 2017. Dejan Boras

   Started On:    13.06.2019.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uLazXMLUtils;

INTERFACE

   USES
      sysutils,
      {LazUtils}
      Laz2_DOM;

TYPE

   { TLazXMLDOMHelper }

   TLazXMLDOMHelper = class helper for TDOMNode
      procedure RemoveAttribute(const name: string);
      procedure SetAttributeValue(const name: string; const value: string);
      procedure SetAttributeValue(const name: string; value: boolean);

      function GetAttributeValue(const name: string): string;
      function GetAttributeValue(const name: string; out exists: boolean): string;
      function GetAttributeValue(const name: string; const defaultValue: string): string;
      function GetAttributeBool(const name: string; defaultValue: Boolean): Boolean;
      function GetAttributeInt(const name: string; defaultValue: Int32 = 0): Int32;

      function AttributeExists(const name: string): Boolean;

      function CreateChild(const name: string): TDOMNode;
   end;

IMPLEMENTATION

{ TLazXMLDOMHelper }

procedure TLazXMLDOMHelper.RemoveAttribute(const name: string);
begin
  if(Attributes.GetNamedItem(name) <> nil) then
     Attributes.RemoveNamedItem(name);
end;

procedure TLazXMLDOMHelper.SetAttributeValue(const name: string; const value: string);
var
   attr: TDOMNode;

begin
   attr := Attributes.GetNamedItem(name);

   if(attr = nil) then begin
      attr := OwnerDocument.CreateAttribute(name);
      Attributes.SetNamedItem(attr);
   end;

   attr.NodeValue := value;
end;

procedure TLazXMLDOMHelper.SetAttributeValue(const name: string; value: boolean);
begin
   if(value) then
      SetAttributeValue(name, 'True')
   else
      SetAttributeValue(name, 'False');
end;

function TLazXMLDOMHelper.GetAttributeValue(const name: string): string;
var
   attr: TDOMNode;

begin
   attr := Attributes.GetNamedItem(name);
   Result := '';

   if(attr <> nil) then
      Result := attr.NodeValue;
end;

function TLazXMLDOMHelper.GetAttributeValue(const name: string; out exists: boolean): string;
var
   attr: TDOMNode;

begin
   attr := Attributes.GetNamedItem(name);

   if(attr <> nil) then begin
      Result := attr.NodeValue;
      exists := true;
   end else begin
     Result := '';
     exists := false;
   end;
end;

function TLazXMLDOMHelper.GetAttributeValue(const name: string; const defaultValue: string): string;
var
   attr: TDOMNode;

begin
   attr := Attributes.GetNamedItem(name);

   if(attr <> nil) then
      Result := attr.NodeValue
   else
      Result := defaultValue;
end;

function TLazXMLDOMHelper.GetAttributeBool(const name: string; defaultValue: Boolean): Boolean;
var
   value: string;
   attr: TDOMNode;

begin
   attr := Attributes.GetNamedItem(name);

   if(attr <> nil) then begin
      value := attr.NodeValue;
      Result := LowerCase(value) = 'true';
   end else
      Result := defaultValue;
end;

function TLazXMLDOMHelper.GetAttributeInt(const name: string; defaultValue: Int32): Int32;
var
   value: string;
   attr: TDOMNode;

begin
   attr := Attributes.GetNamedItem(name);

   if(attr <> nil) then begin
      value := attr.NodeValue;
      longint.TryParse(value, Result);
   end else
      Result := defaultValue;
end;

function TLazXMLDOMHelper.AttributeExists(const name: string): Boolean;
begin
   Result := Attributes.GetNamedItem(name) <> nil;
end;

function TLazXMLDOMHelper.CreateChild(const name: string): TDOMNode;
begin
   {add new item}
   Result := Self.OwnerDocument.CreateElement(name);

   Self.AppendChild(Result);
end;

END.
