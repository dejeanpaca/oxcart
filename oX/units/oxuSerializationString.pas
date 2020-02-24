{
   oxuSerializationString, object serialization string support
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuSerializationString;

INTERFACE

   USES
      uStd, StringUtils, vmVector;

CONST
   OX_SERIALIZATION_SEPARATOR = ' ';

TYPE
   { oxTSerializationString }

   oxTSerializationString = record
      class function DeserializeArray(const st: string; f: PSingle; count: loopint): boolean; static;
      class function DeserializeArray(const st: string; f: PDouble; count: loopint): boolean; static;
      class function DeserializeArray(const st: string; out f: TSingleArray): boolean; static;
      class function DeserializeArray(const st: string; out f: TDoubleArray): boolean; static;

      class function DeserializeArray(const st: string; f: PSingle; count: loopint; separator: char): boolean; static;
      class function DeserializeArray(const st: string; f: PDouble; count: loopint; separator: char): boolean; static;
      class function DeserializeArray(const st: string; out f: TSingleArray; separator: char): boolean; static;
      class function DeserializeArray(const st: string; out f: TDoubleArray; separator: char): boolean; static;

      class function Deserialize(const st: string; out v: TVector2f): boolean; static; inline;
      class function Deserialize(const st: string; out v: TVector3f): boolean; static; inline;
      class function Deserialize(const st: string; out v: TVector4f): boolean; static; inline;
      class function SerializeFloatArray(f: psingle; n: loopint): string; static;
      class function SerializeFloatArray(f: pdouble; n: loopint): string; static;
      class function SerializeFloatArray(f: psingle; n: loopint; separator: char): string; static;
      class function SerializeFloatArray(f: pdouble; n: loopint; separator: char): string; static;
      class function Serialize(var v: TVector2f): string; static; inline;
      class function Serialize(var v: TVector3f): string; static; inline;
      class function Serialize(var v: TVector4f): string; static; inline;
   end;

VAR
   oxsSerialization: oxTSerializationString;

IMPLEMENTATION

{ oxTSerializationString }

class function oxTSerializationString.DeserializeArray(const st: string;
   f: PSingle; count: loopint): boolean;
const
   separator = OX_SERIALIZATION_SEPARATOR;
var
   value: single;
{$INCLUDE ./deserialize_array_count.inc}

class function oxTSerializationString.DeserializeArray(const st: string; f: PDouble; count: loopint): boolean;
const
   separator = OX_SERIALIZATION_SEPARATOR;
var
   value: single;
{$INCLUDE ./deserialize_array_count.inc}

class function oxTSerializationString.DeserializeArray(const st: string; out f: TSingleArray): boolean;
const
   separator = OX_SERIALIZATION_SEPARATOR;
var
   value: single;
{$INCLUDE ./deserialize_array.inc}

class function oxTSerializationString.DeserializeArray(const st: string; out f: TDoubleArray): boolean;
const
   separator = OX_SERIALIZATION_SEPARATOR;
var
   value: double;
{$INCLUDE ./deserialize_array.inc}

class function oxTSerializationString.DeserializeArray(const st: string;
   f: PSingle; count: loopint; separator: char): boolean;
var
   value: single;
{$INCLUDE ./deserialize_array_count.inc}

class function oxTSerializationString.DeserializeArray(const st: string; f: PDouble; count: loopint; separator: char): boolean;
var
   value: single;
{$INCLUDE ./deserialize_array_count.inc}

class function oxTSerializationString.DeserializeArray(const st: string; out f: TSingleArray; separator: char): boolean;
var
   value: single;
{$INCLUDE ./deserialize_array.inc}

class function oxTSerializationString.DeserializeArray(const st: string; out f: TDoubleArray; separator: char): boolean;
var
   value: double;
{$INCLUDE ./deserialize_array.inc}

class function oxTSerializationString.Deserialize(const st: string; out v: TVector2f): boolean;
begin
   Result := DeserializeArray(st, psingle(@v[0]), 2);
end;

class function oxTSerializationString.Deserialize(const st: string; out v: TVector3f): boolean;
begin
   Result := DeserializeArray(st, psingle(@v[0]), 3);
end;

class function oxTSerializationString.Deserialize(const st: string; out v: TVector4f): boolean;
begin
   Result := DeserializeArray(st, psingle(@v[0]), 4);
end;


class function oxTSerializationString.SerializeFloatArray(f: psingle; n: loopint): string;
const
   separator = OX_SERIALIZATION_SEPARATOR;
{$INCLUDE serialize_array.inc}

class function oxTSerializationString.SerializeFloatArray(f: pdouble; n: loopint): string;
const
   separator = OX_SERIALIZATION_SEPARATOR;
{$INCLUDE serialize_array.inc}

class function oxTSerializationString.SerializeFloatArray(f: psingle; n: loopint; separator: char): string;
{$INCLUDE serialize_array.inc}

class function oxTSerializationString.SerializeFloatArray(f: pdouble; n: loopint; separator: char): string;
{$INCLUDE serialize_array.inc}

class function oxTSerializationString.Serialize(var v: TVector2f): string; inline;
begin
   Result := oxsSerialization.SerializeFloatArray(psingle(@v[0]), 2);
end;

class function oxTSerializationString.Serialize(var v: TVector3f): string; inline;
begin
   Result := oxsSerialization.SerializeFloatArray(psingle(@v[0]), 3);
end;

class function oxTSerializationString.Serialize(var v: TVector4f): string; inline;
begin
   Result := oxsSerialization.SerializeFloatArray(psingle(@v[0]), 4);
end;



END.
