{
   oxuSerialization, object serialization
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}{$M+}
UNIT oxuSerialization;

INTERFACE

   USES
      variants, uStd, sysutils, typinfo, uLog, StringUtils,
      {ox}
      uOX, oxuRunRoutines, oxuGlobalInstances;

TYPE
   TSimpleTypeKyndList = specialize TSimpleList<TTypeKind>;

   { oxTSerializable }

   oxTSerializable = class
      public

      constructor Create(); virtual;
      {called when an object is instanced from deserialized data, after the data is set}
      procedure Deserialized(); virtual;

      class function IsClass(left, right: TClass): boolean; static;
      class function IsClass(what: TClass; const name: string): boolean; static;
   end;

   oxTSerializableClass = class of oxTSerializable;

   oxTSerializationPropertySettings = (
      {element is an array}
      OX_SERIALIZATION_ARRAY,
      {data type is external (do not free)}
      OX_SERIALIZATION_EXTERNAL
   );

   oxTSerializationPropertySettingsSet = set of oxTSerializationPropertySettings;

   oxPSerializationDataType = ^oxTSerializationDataType;
   { oxTSerializationDataType }

   oxTSerializationDataType = record
      Name: string;
      {kind of type}
      Kind: TTypeKind;
      {settings}
      Settings: oxTSerializationPropertySettingsSet;
      {number of elements if this is an array}
      Elements,
      {the size of an element here (applies for primitive types)}
      ElementSize,
      {total size of the type (all array elements)}
      TotalSize: loopint;
      {if a float, what type is it}
      FloatType: TFloatType;
      {if an ordinal, what type is it}
      OrdinalType: TOrdType;

      function GetElementSize(): loopint;
      procedure SetSize();

      class procedure Init(out dt: oxTSerializationDataType); static;

      procedure Init(newKind: TTypeKind; newSettings: oxTSerializationPropertySettingsSet = [OX_SERIALIZATION_EXTERNAL]);
      procedure InitArray(newKind: TTypeKind; newElements: longint; newSettings: oxTSerializationPropertySettingsSet = [OX_SERIALIZATION_ARRAY, OX_SERIALIZATION_EXTERNAL]);
      procedure InitFloat(floatKind: TFloatType; newSettings: oxTSerializationPropertySettingsSet = [OX_SERIALIZATION_EXTERNAL]);
      procedure InitFloatArray(floatKind: TFloatType; newElements: longint; newSettings: oxTSerializationPropertySettingsSet = [OX_SERIALIZATION_ARRAY, OX_SERIALIZATION_EXTERNAL]);
      procedure InitOrd(newKind: TTypeKind; newOrdinalType: TOrdType; newSettings: oxTSerializationPropertySettingsSet = [OX_SERIALIZATION_EXTERNAL]);
      procedure InitOrdArray(newKind: TTypeKind; newOrdinalType: TOrdType; newElements: longint; newSettings: oxTSerializationPropertySettingsSet = [OX_SERIALIZATION_ARRAY, OX_SERIALIZATION_EXTERNAL]);
      procedure InitRecord(newTotalSize: loopint);
   end;

   { oxTSerializationProperty }
   oxPSerializationProperty = ^oxTSerializationProperty;
   oxTSerializationProperty = record
      Name: string;
      {associated serializer}
      Serializer: TObject;
      {offset into the property, -1 means its a published property}
      Offset: PtrInt;
      {data type associated with the property}
      Dt: oxPSerializationDataType;
      {prop info associated with the property}
      PropInfo: PPropInfo;
      {type info associated with the property}
      TypeInfo: PTypeInfo;
      {is the property valid}
      Valid: boolean;

      function GetFromLocation(location: pointer): string;
      function GetWideFromLocation(location: pointer): WideString;
      function GetValue(TypeOf: TClass; ofWhat: TObject): string;
      function GetWideValue(TypeOf: TClass; ofWhat: TObject): WideString;

      procedure SetToLocation(location: pointer; value: string);
      procedure SetValue(TypeOf: TClass; ofWhat: TObject; value: string);
   end;

   oxTSerializationProperties = specialize TSimpleList<oxTSerializationProperty>;

   oxTSerializationInstanceFunction = function(): TObject;

   { oxTSerialization }

   oxTSerialization = class
      public
      {properties that can be serialized}
      Properties: oxTSerializationProperties;
      {class type for serialization}
      TypeOf: TClass;
      {is the structure a record}
      IsRecord: boolean;
      {type name, used only if the type is a record}
      TypeName: string;
      {is this an oxTSerializable based class}
      oxSerializable: Boolean;
      {method to return an instance of this object}
      InstanceMethod: oxTSerializationInstanceFunction;
      {inherited serialization}
      Inherits: oxTSerialization;

      constructor Create(setTypeOf: TClass; instance: oxTSerializationInstanceFunction);
      constructor CreateRecord(const newTypeName: string);

      destructor Destroy(); override;

      class procedure InitProp(out prop: oxTSerializationProperty); static;

      {add a published property with name and datatype}
      procedure AddPublishedProperty(const name: string; const t: oxTSerializationDataType);

      {add a published property}
      procedure AddCharProperty(const name: string);
      {add a published property}
      procedure AddShortstringProperty(const name: string);
      {add a published property}
      procedure AddAnsistringProperty(const name: string);

      {add a published property}
      procedure AddBoolProperty(const name: string);
      {add a published property}
      procedure AddWordBoolProperty(const name: string);
      {add a published property}
      procedure AddLongBoolProperty(const name: string);

      {add a published property}
      procedure AddShortintProperty(const name: string);
      {add a published property}
      procedure AddSmallintProperty(const name: string);
      {add a published property}
      procedure AddLongintProperty(const name: string);
      {add a published property}
      procedure AddInt64Property(const name: string);

      {add a published property}
      procedure AddByteProperty(const name: string);
      {add a published property}
      procedure AddWord(const name: string);
      {add a published property}
      procedure AddDWordProperty(const name: string);
      {add a published property}
      procedure AddQWordProperty(const name: string);

      {add an object property}
      procedure AddObjectProperty(const name: string; offset: PtrInt);
      procedure AddObjectProperty(const name: string; offset: pointer);
      procedure AddObjectProperty(const name: string; offset: pointer; const objectType: string);
      procedure AddRecordProperty(const name: string; offset: pointer; const recordType: string);

      {dynamic array property}
      procedure AddDynArrayProperty(const name: string; ti: PTypeInfo);

      {add a unpublished property}
      function AddProperty(const name: string; offset: PtrInt; const dt: oxTSerialization): oxPSerializationProperty;
      {add a unpublished property}
      function AddProperty(const name: string; offset: PtrInt; const dt: oxTSerializationDataType): oxPSerializationProperty;
      {add a unpublished property}
      function AddProperty(const name: string; offset: PtrInt; const dt: oxTSerializationDataType; newTypeInfo: PTypeInfo): oxPSerializationProperty;
      {add a unpublished property}
      function AddProperty(const name: string; offset: pointer; const dt: oxTSerializationDataType): oxPSerializationProperty;
      {add a unpublished property}
      function AddProperty(const name: string; offset: pointer; const dt: oxTSerializationDataType; newTypeInfo: PTypeInfo): oxPSerializationProperty;
      {finalize adding of serializable properties, and gather information on properties}
      procedure PropertiesDone();

      {get serializable property count}
      function GetPropCount(): loopint;
      {get the specified prop value as string}
      function GetPropValue(ofWhat: TObject; const prop: string): string;
      {get the specified prop value as string}
      function GetPropValue(ofWhat: TObject; propIndex: loopint): string;

      function Find(const prop: string): longint;

      {set a property}
      procedure SetProp(ofWhat: TObject; const prop, value: string);
   end;

   oxTSerializers = specialize TSimpleList<oxTSerialization>;

   { oxTSerializationManager }

   oxTSerializationManager = record
      public
      Types: record
         Char,
         WideChar,
         ShortString,
         AnsiString,
         tString,

         Boolean,
         WordBool,
         LongBool,

         Shortint,
         Smallint,
         Longint,
         Int64,

         Byte,
         Word,
         DWord,
         QWord,

         Single,
         Double,
         Extended,
         Comp,
         Currency,

         Color3ub,
         Color4ub,
         Color3f,
         Color4f,

         Vector2ub,
         Vector3ub,
         Vector4ub,

         Vector2i,
         Vector3i,
         Vector4i,

         Vector2f,
         Vector3f,
         Vector4f,

         TSet,
         Enum,
         DynamicArray,
         tObject,
         tRecord,
         Pointer: oxTSerializationDataType;
      end;

      Serializers: oxTSerializers;

      procedure Initialize();

      procedure Add(serializer: oxTSerialization);
      procedure Remove(serializer: oxTSerialization);

      function Get(const name: string): oxTSerialization;
      function Get(typeOf: TClass): oxTSerialization;

      procedure CloneAllProperties(source: TObject; target: TObject; serializer: oxTSerialization = nil);
      procedure CloneProperties(serializer: oxTSerialization; source: TObject; target: TObject);
      function Clone(what: TObject): TObject;

      {gets the size for a given type in bytes}
      class function GetSize(typeKind: TTypeKind; ordinalType: TOrdType = otULong; floatType: TFloatType = ftSingle): loopint; static;
   end;

VAR
   oxSerialization: oxTSerializationManager;

IMPLEMENTATION

procedure oxTSerializationManager.Initialize();
begin
   Serializers.Initialize(Serializers);
end;

procedure oxTSerializationManager.Add(serializer: oxTSerialization);
begin
   Serializers.Add(serializer);
end;

procedure oxTSerializationManager.Remove(serializer: oxTSerialization);
var
   index: loopint;

begin
   index := Serializers.Find(serializer);

   if(index > -1) then
      Serializers.Remove(index);
end;

function oxTSerializationManager.Get(const name: string): oxTSerialization;
var
   i: loopint;

begin
   for i := 0 to Serializers.n - 1 do begin
      if(Serializers.List[i].TypeName = name) then
         exit(Serializers.List[i]);
   end;

   Result := nil;
end;

function oxTSerializationManager.Get(typeOf: TClass): oxTSerialization;
var
   i: loopint;

begin
   for i := 0 to Serializers.n - 1 do begin
      if(Serializers.List[i].TypeOf = typeOf) then
         exit(Serializers.List[i]);
   end;

   Result := nil;
end;

procedure oxTSerializationManager.CloneAllProperties(source: TObject; target: TObject; serializer: oxTSerialization);
var
   cur: TClass;

begin
   serializer := oxSerialization.Get(source.ClassName);

   if(serializer <> nil) then
      CloneProperties(serializer, source, target);

   cur := source.ClassParent;

   { clone properties }
   repeat
      if(cur <> nil) then begin
         if(serializer <> nil) then
            CloneProperties(serializer, source, target);
      end else
         break;

      cur := cur.ClassParent;
   until (cur = nil) or (cur.ClassName = 'TObject');

   {call inherited serializer}
   if(serializer <> nil) and (serializer.Inherits <> nil) then
      CloneProperties(serializer.Inherits, source, target);
end;

procedure oxTSerializationManager.CloneProperties(serializer: oxTSerialization; source: TObject; target: TObject);
var
   i: loopint;
   obj: TObject;
   prop: oxTSerializationProperty;
   sourceProp,
   targetProp: Pointer;

   daSize: tdynarrayindex;
   daBounds: system.TBoundArray;

begin
   if(serializer <> nil) then begin
      {TODO: Clone properties}
      for i := 0 to serializer.Properties.n - 1 do begin
         prop := serializer.Properties.List[i];

         sourceProp := @(pointer(source)^) + prop.Offset;
         targetProp := @(pointer(target)^) + prop.Offset;

         if(prop.Dt^.Kind = tkPointer) then
            pointer(targetProp^) := pointer(sourceProp^)
         else if(prop.Dt^.Kind = tkObject) then begin
            {if not created}
            if(TObject(targetProp^) = nil) then begin
               obj := TObject(sourceProp^);

               if(obj <> nil) then begin
                  TObject(targetProp^) :=
                     oxSerialization.Clone(TObject(sourceProp^));
               end else
                  log.w('serialization > Cannot clone object property ' + prop.Name + ' as the reference is nil in source ' + source.ClassName);
            end;

            if(TObject(targetProp^) = nil) then
               CloneAllProperties(source, target, oxTSerialization(prop.Serializer));
         end else if(prop.Dt^.Kind = tkRecord) then begin
            {TODO: Clone record}
         end else if(prop.Dt^.Kind = tkAString) then begin
            if(prop.PropInfo <> nil) then
               SetPropValue(target, prop.PropInfo, GetPropValue(source, prop.PropInfo))
            else begin
               AnsiString(targetProp^) := AnsiString(sourceProp^);
               UniqueString(AnsiString(targetProp^));
            end;
         end else if(prop.Dt^.Kind = tkAString) then begin
            ShortString(targetProp^) := ShortString(sourceProp^);
         end else if(prop.Dt^.Kind = tkDynArray) then begin
            daSize := DynArraySize(prop.TypeInfo);
            daBounds := DynArrayBounds(pointer(sourceProp^), prop.TypeInfo);

            if(daSize > 0) then begin
               DynArraySetLength(pointer(targetProp^), prop.TypeInfo, Length(daBounds), @daBounds[0]);

               // TODO: Clone the array objects (if any)
               CopyArray(pointer(sourceProp^), pointer(targetProp^), prop.TypeInfo, daSize);
            end else
               DynArrayClear(pointer(targetProp^), prop.TypeInfo);
         end else begin
            {for everything else, we'll just move memory}
            if(prop.Dt^.TotalSize > 0) then begin
               sourceProp := @(pointer(source)^) {%H-}+ prop.Offset;
               targetProp := @(pointer(target)^) {%H-}+ prop.Offset;

               move(sourceProp^, targetProp^, prop.Dt^.TotalSize);
            end else
               log.w('serialization > Cannot clone property, unsupported data type: ' + prop.Name + ' (' + prop.Dt^.Name + ')');
         end;
      end;
   end;
end;

function oxTSerializationManager.Clone(what: TObject): TObject;
var
   serializer: oxTSerialization;

begin
   serializer := Get(what.ClassName);

   { instance appropriate object }

   if(serializer <> nil) then begin
      if(serializer.InstanceMethod <> nil) then
         Result := serializer.InstanceMethod()
      else
         Result := what.ClassType.Create();
   end else
      Result := what.ClassType.Create();

   CloneAllProperties(what, Result, serializer);

   if(serializer <> nil) and (serializer.oxSerializable) then
      oxTSerializable(Result).Deserialized();
end;

class function oxTSerializationManager.GetSize(typeKind: TTypeKind; ordinalType: TOrdType = otULong; floatType: TFloatType = ftSingle): loopint;
begin
   Result := 0;

   if(typeKind = tkObject) or (typeKind = tkPointer) then begin
      Result := SizeOf(Pointer);
   end else if(typeKind = tkInteger) or (typeKind = tkBool) or (typeKind = tkChar) then begin
      if(ordinalType = otSByte) or (ordinalType = otUByte) then
         Result := SizeOf(Byte)
      else if(ordinalType = otSWord) or (ordinalType = otUWord) then
         Result := SizeOf(Word)
      else if(ordinalType = otSLong) or (ordinalType = otULong) then
         Result := SizeOf(LongInt)
   end else if(typeKind = tkInt64) or (typeKind = tkQWord) then
      Result := SizeOf(int64)
   else if(typeKind = tkFloat) then begin
      if(floatType = ftSingle) then
         Result := SizeOf(Single)
      else if(floatType = ftDouble) then
         Result := SizeOf(Double)
      else if(floatType = ftExtended) then
         Result := SizeOf(Extended)
      else if(floatType = ftComp) then
         Result := SizeOf(Comp)
      else if(floatType = ftCurr) then
         Result := SizeOf(Currency)
   end else if(typeKind = tkWChar) then
      Result := SizeOf(WideChar)
   else if(typeKind = tkFile) then
      Result := SizeOf(File)
   else if(typeKind = tkEnumeration) then begin
      {TODO: This may be a hack, and we shoul figure out the proper size of the enum}
      Result := SizeOf(loopint);
   end else if(typeKind = tkSet) then
      {TODO: This is a hack. Figure out if the set is more than 32 elements and return proper size}
      Result := 4;
end;

{ oxTSerializable }

constructor oxTSerializable.Create();
begin

end;

procedure oxTSerializable.Deserialized();
begin

end;

class function oxTSerializable.IsClass(left, right: TClass): boolean;
{$IFNDEF OX_LIBRARY_SUPPORT}
var
   cur: TClass;
{$ENDIF}

begin
   {$IFDEF OX_LIBRARY_SUPPORT}
   Result := IsClass(left, right.ClassName);
   {$ELSE}
   cur := left;

   repeat
     if(cur = right) then
        exit(true);

     cur := cur.ClassParent;
   until (cur = nil) or (cur = TObject);

   Result := false;
   {$ENDIF}
end;

class function oxTSerializable.IsClass(what: TClass; const name: string): boolean;
var
   cur: TClass;

begin
   cur := what.ClassType;

   repeat
     if(cur.ClassName = name) then
        exit(true);

     cur := cur.ClassParent;
   until (cur = nil) or (cur = TObject);

   Result := false;
end;

{ oxTSerializationProperty }

function oxTSerializationProperty.GetFromLocation(location: pointer): string;
begin
   if(Dt^.Kind = tkInteger) then begin
      if(Dt^.OrdinalType = otSByte) then
         exit(sf(ShortInt(location^)))
      else if(Dt^.OrdinalType = otSWord) then
         exit(sf(SmallInt(location^)))
      else if(Dt^.OrdinalType = otSLong) then
         exit(sf(LongInt(location^)))
      else if(Dt^.OrdinalType = otUByte) then
         exit(sf(Byte(location^)))
      else if(Dt^.OrdinalType = otUWord) then
         exit(sf(Word(location^)))
      else if(Dt^.OrdinalType = otULong) then
         exit(sf(Dword(location^)));
   end else if(Dt^.Kind = tkInt64) then
      exit(sf(Int64(location^)))
   else if(Dt^.Kind = tkQWord) then
      exit(sf(QWord(location^)))
   else if(Dt^.Kind = tkChar) then
      exit(Char(location^))
   else if(Dt^.Kind = tkSet) then begin
      if(TypeInfo <> nil) then
         exit(SetToString(TypeInfo, integer(location^) , true))
      else
         exit(sf(integer(location^)));
   end else if(Dt^.Kind = tkEnumeration) then begin
      if(TypeInfo <> nil) then
         exit(GetEnumName(TypeInfo, integer(location^)))
      else
         exit(sf(integer(location^)))
   end else if(Dt^.Kind = tkAString) then begin
      exit(PAnsiString(location)^)
   end else if(Dt^.Kind = tkSString) then
      exit(ShortString(location^))
   else if(Dt^.Kind = tkFloat) then begin
      if(Dt^.FloatType = ftSingle) then
         exit(sf(Single(location^)))
      else if(Dt^.FloatType = ftDouble) then
         exit(sf(Double(location^)))
      else if(Dt^.FloatType = ftExtended) then
         exit(sf(Extended(location^)))
      else if(Dt^.FloatType = ftCurr) then
         exit(sf(Currency(location^)))
      else if(Dt^.FloatType = ftComp) then
         exit(sf(Comp(location^)));
   end;

   Result := '';
end;

function oxTSerializationProperty.GetWideFromLocation(location: pointer): WideString;
begin
   if(Dt^.Kind = tkWString) then
      exit(WideString(location^))
   else if(Dt^.Kind = tkWChar) then
      exit(WideChar(location^));

   Result := '';
end;

function oxTSerializationProperty.GetValue(TypeOf: TClass; ofWhat: TObject): string;
var
   location: pointer;
   ordProp: int64;
   i: loopint;

begin
   if(not Valid) then
      exit('');

   if(PropInfo = nil) then begin
      location := pointer(pointer(ofWhat) + Offset);

      {SINGLE ELEMENT}
      if(not (OX_SERIALIZATION_ARRAY in Dt^.Settings)) then begin
         exit(GetFromLocation(location));
      {ARRAY}
      end else begin
         if(Dt^.Elements > 0) then begin
            Result := '[';

            for i := 0 to (Dt^.Elements - 1) do begin
               if(i < Dt^.Elements - 1) then
                  Result := Result + GetFromLocation(location) +  ','
               else
                  Result := Result + GetFromLocation(location);

               inc(location, Dt^.ElementSize);
            end;

            exit(Result + ']');
         end;
      end;
   end else begin
      try
         if(Dt^.Kind = tkInteger) then begin
            ordProp := GetOrdProp(ofWhat, PropInfo);

            if(Dt^.OrdinalType = otSByte) then
               exit(sf(ShortInt(ordProp)))
            else if(Dt^.OrdinalType = otSWord) then
               exit(sf(SmallInt(ordProp)))
            else if(Dt^.OrdinalType = otSLong) then
               exit(sf(Longint(ordProp)))
            else if(Dt^.OrdinalType = otUByte) then
               exit(sf(Byte(ordProp)))
            else if(Dt^.OrdinalType = otUWord) then
               exit(sf(Word(ordProp)))
            else if(Dt^.OrdinalType = otULong) then
               exit(sf(DWord(ordProp)));
         end else if (Dt^.Kind = tkInt64) then
            exit(sf(GetInt64Prop(ofWhat, PropInfo)))
         else if (Dt^.Kind = tkQWord) then
            exit(sf(qword(GetInt64Prop(ofWhat, PropInfo))))
         else if(Dt^.Kind = tkChar) then
            exit(char(GetOrdProp(ofWhat, PropInfo)))
         else if(Dt^.Kind = tkSet) then
            exit(GetSetProp(ofwhat, PropInfo, true))
         else if(Dt^.Kind = tkEnumeration) then
            exit(GetEnumProp(ofWhat, PropInfo))
         else if(Dt^.Kind = tkAString) then
            exit(GetStrProp(ofWhat, PropInfo))
         else if(Dt^.Kind = tkSString) then
            exit(GetStrProp(ofWhat, PropInfo))
         else if(Dt^.Kind = tkFloat) then
            exit(sf(GetFloatProp(ofWhat, PropInfo)))
         else if(Dt^.Kind = tkRecord) then
            exit('Record');
      except
         log.e('serialization > Failed to get property ' + Name + ' of ' + TypeOf.ClassName);
      end;
   end;

   Result := '';
end;

function oxTSerializationProperty.GetWideValue(TypeOf: TClass; ofWhat: TObject): WideString;
var
   location: pointer;

begin
   if(PropInfo = nil) then begin
      location := pointer(pointer(ofWhat) + Offset);

      {not an array}
      if(not (OX_SERIALIZATION_ARRAY in Dt^.Settings)) then begin
         exit(GetWideFromLocation(location));
      end else begin
         if(Dt^.Elements > 0) then begin
            {TODO: Implement array support for primitives}
         end;
      end;
   end else begin
      try
         if(Dt^.Kind = tkWString) then
            exit(GetWideStrProp(ofWhat, PropInfo))
         else if(Dt^.Kind = tkWChar) then
            exit(WideChar(GetOrdProp(ofWhat, PropInfo)));
      except
         log.e('serialization > Failed to get property ' + Name + ' of ' + TypeOf.ClassName);
      end;
   end;

   Result := '';
end;

procedure oxTSerializationProperty.SetToLocation(location: pointer; value: string);
var
   ordValue: int64;

begin
   try
      if(Dt^.Kind = tkInteger) then begin
         ordValue := StrToInt(value);

         if(Dt^.OrdinalType = otSByte) then
            ShortInt(location^) := ordValue
         else if(Dt^.OrdinalType = otSWord) then
            SmallInt(location^) := ordValue
         else if(Dt^.OrdinalType = otSLong) then
            LongInt(location^) := ordValue
         else if(Dt^.OrdinalType = otUByte) then
            Byte(location^) := ordValue
         else if(Dt^.OrdinalType = otUWord) then
            Word(location^) := ordValue
         else if(Dt^.OrdinalType = otULong) then
            DWord(location^) := ordValue
      end else if(Dt^.Kind = tkInt64) then
         Int64(location^) := StrToInt64(value)
      else if(Dt^.Kind = tkQWord) then
         Int64(location^) := StrToQWord(value)
      else if(Dt^.Kind = tkChar) then
         Char(location^) := value[1]
      else if(Dt^.Kind = tkSet) then begin
         if(TypeInfo <> nil) then
            Longint(location^) := StringToSet(TypeInfo, value)
         else
            Longint(location^) := StrToInt(value);
      end else if(Dt^.Kind = tkEnumeration) then begin
         if(TypeInfo <> nil) then
            Longint(location^) := GetEnumValue(TypeInfo, value)
         else
            Longint(location^) := StrToInt(value);
      end else if(Dt^.Kind = tkAString) then
         AnsiString(location^) := value
      else if(Dt^.Kind = tkSString) then begin
         if(Dt^.Elements = 0) then
            ShortString(location^) := value;
         {TODO: Copy only as many characters as fits}
      end else if(Dt^.Kind = tkFloat) then begin
         if(Dt^.FloatType = ftSingle) then
            Single(location^) := StrToFloat(value)
         else if(Dt^.FloatType = ftDouble) then
            Double(location^) := StrToFloat(value)
         else if(Dt^.FloatType = ftDouble) then
            Extended(location^) := StrToFloat(value)
         else if(Dt^.FloatType = ftDouble) then
            Comp(location^) := StrToInt(value)
         else if(Dt^.FloatType = ftDouble) then
            Currency(location^) := StrToCurr(value);
      end;
   except
      log.e('serialization > Failed to assign prop ' + Name + ' the value ' + value);
   end;
end;

procedure oxTSerializationProperty.SetValue(TypeOf: TClass; ofWhat: TObject; value: string);
var
   location: pointer;
   ordProp: int64;

begin
   if(PropInfo = nil) then begin
      location := pointer(pointer(ofWhat) + Offset);

      {SINGLE ELEMENT}
      if(not (OX_SERIALIZATION_ARRAY in Dt^.Settings)) then begin
         SetToLocation(location, value);
      end;
   end else begin
      try
         if(Dt^.Kind = tkInteger) then begin
            ordProp := value.ToInt64();
            SetOrdProp(ofWhat, PropInfo, ordProp);
         end else if (Dt^.Kind = tkInt64) then
            SetInt64Prop(ofWhat, PropInfo, value.ToInt64())
         else if (Dt^.Kind = tkQWord) then
            SetInt64Prop(ofWhat, PropInfo, value.ToInt64())
         else if(Dt^.Kind = tkChar) then
            SetOrdProp(ofWhat, PropInfo, byte(value[1]))
         else if(Dt^.Kind = tkAString) then
            SetStrProp(ofWhat, PropInfo, value)
         else if(Dt^.Kind = tkSString) then
            SetStrProp(ofWhat, PropInfo, value)
         else if(Dt^.Kind = tkFloat) then
            SetFloatProp(ofWhat, PropInfo, value.ToExtended)
         else if(Dt^.Kind = tkSet) then
            SetSetProp(ofWhat, PropInfo, value)
         else if(Dt^.Kind = tkEnumeration) then
            SetEnumProp(ofWhat, PropInfo, value);
      except
         log.e('serialization > Failed to assign prop ' + Name + ' the value ' + value + ' of class ' + TypeOf.ClassName );
      end;
   end;
end;


{ oxTSerializationDataType }

function oxTSerializationDataType.GetElementSize(): loopint;
begin
   If(Kind = tkRecord) then
      Result := TotalSize
   else
      Result := oxSerialization.GetSize(Kind, OrdinalType, FloatType);
end;

procedure oxTSerializationDataType.SetSize();
begin
   ElementSize := GetElementSize();

   if(Elements = 0) then
      TotalSize := ElementSize
   else
      TotalSize := ElementSize * Elements;
end;

class procedure oxTSerializationDataType.Init(out dt: oxTSerializationDataType);
begin
   ZeroOut(dt, SizeOf(dt));
end;

procedure oxTSerializationDataType.Init(newKind: TTypeKind; newSettings: oxTSerializationPropertySettingsSet);
begin
   Init(Self);

   Kind := newKind;
   Settings := newSettings;

   SetSize();
end;

procedure oxTSerializationDataType.InitArray(newKind: TTypeKind; newElements: longint; newSettings: oxTSerializationPropertySettingsSet);
begin
   Init(Self);

   Kind := newKind;
   Settings := newSettings;
   Elements := newElements;

   SetSize();
end;

procedure oxTSerializationDataType.InitFloat(floatKind: TFloatType; newSettings: oxTSerializationPropertySettingsSet);
begin
   Init(Self);

   Kind := tkFloat;
   Settings := newSettings;
   FloatType := floatKind;

   SetSize();
end;

procedure oxTSerializationDataType.InitFloatArray(floatKind: TFloatType; newElements: longint; newSettings: oxTSerializationPropertySettingsSet);
begin
   Init(Self);

   Kind := tkFloat;
   Settings := newSettings;
   FloatType := floatKind;
   Elements := newElements;

   SetSize();
end;

procedure oxTSerializationDataType.InitOrd(newKind: TTypeKind;
   newOrdinalType: TOrdType; newSettings: oxTSerializationPropertySettingsSet);
begin
   Init(Self);

   Kind := newKind;
   Settings := newSettings;
   OrdinalType := newOrdinalType;

   SetSize();
end;

procedure oxTSerializationDataType.InitOrdArray(newKind: TTypeKind;
   newOrdinalType: TOrdType; newElements: longint;
   newSettings: oxTSerializationPropertySettingsSet);
begin
   Init(Self);

   Kind := newKind;
   Settings := newSettings;
   Elements := newElements;
   OrdinalType := newOrdinalType;

   SetSize();
end;

procedure oxTSerializationDataType.InitRecord(newTotalSize: loopint);
begin
   Init(Self);

   Kind := tkRecord;
   TotalSize := newTotalSize;
end;

{ oxTSerialization }

constructor oxTSerialization.Create(setTypeOf: TClass; instance: oxTSerializationInstanceFunction);
var
   cur: TClass;

begin
   TypeOf := setTypeOf;
   TypeName := TypeOf.ClassName;
   InstanceMethod := instance;

   oxTSerializationProperties.Initialize(Properties);

   cur := setTypeOf;
   repeat
      if(cur.ClassName = 'oxTSerializable') then begin
         oxSerializable := true;
         Break;
      end;

      cur := cur.ClassParent;
   until cur = nil;

   oxSerialization.Add(Self);

end;

constructor oxTSerialization.CreateRecord(const newTypeName: string);
begin
   IsRecord := true;
   TypeName := newTypeName;

   oxTSerializationProperties.Initialize(Properties);

   oxSerialization.Add(Self);
end;

destructor oxTSerialization.Destroy();
begin
   inherited Destroy;

   oxSerialization.Remove(Self);
end;

class procedure oxTSerialization.InitProp(out prop: oxTSerializationProperty);
begin
   ZeroOut(prop, SizeOf(prop));

   prop.Valid := true;
   prop.Offset := -1;
end;

procedure oxTSerialization.AddPublishedProperty(const name: string; const t: oxTSerializationDataType);
var
   prop: oxTSerializationProperty;

begin
   InitProp(prop);

   prop.name := name;
   prop.Dt := @t;

   Properties.Add(prop);
end;

procedure oxTSerialization.AddCharProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.Char);
end;

procedure oxTSerialization.AddShortstringProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.ShortString);
end;

procedure oxTSerialization.AddAnsistringProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.AnsiString);
end;

procedure oxTSerialization.AddBoolProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.Boolean);
end;

procedure oxTSerialization.AddWordBoolProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.WordBool);
end;

procedure oxTSerialization.AddLongBoolProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.LongBool);
end;

procedure oxTSerialization.AddShortintProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.Shortint);
end;

procedure oxTSerialization.AddSmallintProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.Smallint);
end;

procedure oxTSerialization.AddLongintProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.Longint);
end;

procedure oxTSerialization.AddInt64Property(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.Int64);
end;

procedure oxTSerialization.AddByteProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.Byte);
end;

procedure oxTSerialization.AddWord(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.Word);
end;

procedure oxTSerialization.AddDWordProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.DWord);
end;

procedure oxTSerialization.AddQWordProperty(const name: string);
begin
   AddPublishedProperty(name, oxSerialization.Types.QWord);
end;

procedure oxTSerialization.AddObjectProperty(const name: string; offset: PtrInt);
begin
   AddProperty(name, offset, oxSerialization.Types.tObject);
end;

procedure oxTSerialization.AddObjectProperty(const name: string; offset: pointer);
var
   poffset: PtrInt absolute offset;

begin
   AddProperty(name, poffset, oxSerialization.Types.tObject);
end;

procedure oxTSerialization.AddObjectProperty(const name: string; offset: pointer; const objectType: string);
var
   poffset: PtrInt absolute offset;
   prop: oxPSerializationProperty;

begin
   prop := AddProperty(name, poffset, oxSerialization.Types.tObject);
   prop^.Serializer := oxSerialization.Get(objectType);

   if(prop^.Serializer = nil) then
      log.w('Could not find serializer for object type: ' + objectType);
end;

procedure oxTSerialization.AddRecordProperty(const name: string; offset: pointer; const recordType: string);
var
   poffset: PtrInt absolute offset;
   prop: oxPSerializationProperty;

begin
   prop := AddProperty(name, poffset, oxSerialization.Types.tRecord);
   prop^.Serializer := oxSerialization.Get(recordType);

   if(prop^.Serializer = nil) then
      log.w('Could not find serializer for record type: ' + recordType);
end;

procedure oxTSerialization.AddDynArrayProperty(const name: string; ti: PTypeInfo);
var
   prop: oxTSerializationProperty;

begin
   InitProp(prop);
   prop.Name := name;
   prop.Dt := @oxSerialization.Types.DynamicArray;
   prop.TypeInfo := ti;
end;

function oxTSerialization.AddProperty(const name: string; offset: PtrInt; const dt: oxTSerialization): oxPSerializationProperty;
var
   prop: oxTSerializationProperty;

begin
   InitProp(prop);

   prop.Name := name;
   prop.Serializer := dt;
   prop.Offset := offset;

   Properties.Add(prop);
   Result := Properties.GetLast();
end;

{unpublished properties}

function oxTSerialization.AddProperty(const name: string; offset: PtrInt; const dt: oxTSerializationDataType): oxPSerializationProperty;
var
   prop: oxTSerializationProperty;

begin
   InitProp(prop);

   prop.Name := name;
   prop.Dt := @dt;
   prop.Offset := offset;
   prop.PropInfo := nil;

   Properties.Add(prop);
   Result := Properties.GetLast();
end;

function oxTSerialization.AddProperty(const name: string; offset: PtrInt; const dt: oxTSerializationDataType; newTypeInfo: PTypeInfo): oxPSerializationProperty;
var
   prop: oxTSerializationProperty;

begin
   InitProp(prop);

   prop.Name := name;
   prop.Dt := @dt;
   prop.Offset := offset;
   prop.TypeInfo := newTypeInfo;

   Properties.Add(prop);
   Result := Properties.GetLast();
end;

function oxTSerialization.AddProperty(const name: string; offset: pointer; const dt: oxTSerializationDataType): oxPSerializationProperty;
var
   prop: oxTSerializationProperty;
   poffset: PtrInt absolute offset;

begin
   InitProp(prop);

   prop.Name := name;
   prop.Dt := @dt;
   prop.Offset := poffset;
   prop.PropInfo := nil;

   Properties.Add(prop);
   Result := Properties.GetLast();
end;

function oxTSerialization.AddProperty(const name: string; offset: pointer; const dt: oxTSerializationDataType; newTypeInfo: PTypeInfo): oxPSerializationProperty;
var
   prop: oxTSerializationProperty;
   poffset: PtrInt absolute offset;

begin
   InitProp(prop);

   prop.Name := name;
   prop.Dt := @dt;
   prop.Offset := poffset;
   prop.TypeInfo := newTypeInfo;

   Properties.Add(prop);
   Result := Properties.GetLast();
end;

procedure oxTSerialization.PropertiesDone();
var
   i: loopint;
   propName: string;

begin
   {get info for all published properties}
   for i := 0 to (Properties.n - 1) do begin
      Properties.List[i].PropInfo := nil;

      if(Properties.List[i].Offset = -1) then begin
         propName := Properties.List[i].Name;

         try
            Properties.List[i].PropInfo := GetPropInfo(TypeOf, propName);
         except
            Properties.List[i].PropInfo := nil;
         end;

         if(Properties.List[i].PropInfo = nil) then begin
            Properties.List[i].Valid := false;

            log.w('serialization > Property info for ' + propName + ' not found in class ' + TypeOf.ClassName);
         end;
      end;
   end;
end;

function oxTSerialization.GetPropCount(): loopint;
begin
   Result := Properties.n;
end;

function oxTSerialization.GetPropValue(ofWhat: TObject; const prop: string): string;
var
   index: loopint;

begin
   index := Find(prop);

   if(index >= 0) then
      exit(GetPropValue(ofWhat, index))
   else
      log.e('serialization > Property ' + prop + ' not found for ' + TypeOf.ClassName);

   Result := '';
end;

function oxTSerialization.GetPropValue(ofWhat: TObject; propIndex: loopint): string;
var
   p: oxTSerializationProperty;

begin
   if(propIndex >= 0) and (propIndex < Properties.n) then begin
      p := Properties.List[propIndex];

      exit(p.GetValue(TypeOf, ofWhat));
   end;

   Result := '';
end;

function oxTSerialization.Find(const prop: string): longint;
var
   i: loopint;

begin
   for i := 0 to (Properties.n - 1) do begin
      if(Properties.List[i].Name = prop) then
         exit(i);
   end;

   Result := -1;
end;

procedure oxTSerialization.SetProp(ofWhat: TObject; const prop, value: string);
var
   index: loopint;

begin
   index := Find(prop);

   if(index >= 0) then
      Properties.List[index].SetValue(TypeOf, ofWhat, value)
   else
      log.e('serialization > Property ' + prop + ' not found for ' + TypeOf.ClassName);
end;

procedure init();
begin
   oxSerialization.Initialize();

   oxSerialization.Types.Char.Init(tkChar);
   oxSerialization.Types.Char.Name := 'Char';
   oxSerialization.Types.WideChar.Init(tkWChar);
   oxSerialization.Types.WideChar.Name := 'WChar';
   oxSerialization.Types.ShortString.Init(tkSString);
   oxSerialization.Types.ShortString.Name := 'ShortString';
   oxSerialization.Types.AnsiString.Init(tkAString);
   oxSerialization.Types.AnsiString.Name := 'AnsiString';
   oxSerialization.Types.tString := oxSerialization.Types.AnsiString;
   oxSerialization.Types.tString.Name := 'String(Ansistring)';

   oxSerialization.Types.Boolean.InitOrd(tkBool, otSByte);
   oxSerialization.Types.Boolean.Name := 'Boolean';
   oxSerialization.Types.WordBool.InitOrd(tkBool, otSWord);
   oxSerialization.Types.Wordbool.Name := 'WordBool';
   oxSerialization.Types.LongBool.InitOrd(tkBool, otSLong);
   oxSerialization.Types.Longbool.Name := 'LongBool';

   oxSerialization.Types.Shortint.InitOrd(tkInteger, otSByte);
   oxSerialization.Types.Shortint.Name := 'Shortint';
   oxSerialization.Types.Smallint.InitOrd(tkInteger, otSWord);
   oxSerialization.Types.Smallint.Name := 'Smallint';
   oxSerialization.Types.Longint.InitOrd(tkInteger, otSLong);
   oxSerialization.Types.Longint.Name := 'Longint';
   oxSerialization.Types.Int64.Init(tkInt64);
   oxSerialization.Types.Int64.Name := 'Int64';

   oxSerialization.Types.Byte.InitOrd(tkInteger, otUByte);
   oxSerialization.Types.Byte.Name := 'Byte';
   oxSerialization.Types.Word.InitOrd(tkInteger, otUWord);
   oxSerialization.Types.Word.Name := 'Word';
   oxSerialization.Types.DWord.InitOrd(tkInteger, otULong);
   oxSerialization.Types.DWord.Name := 'DWord';
   oxSerialization.Types.QWord.Init(tkQWord);
   oxSerialization.Types.Int64.Name := 'QWord';

   oxSerialization.Types.Single.InitFloat(ftSingle);
   oxSerialization.Types.Single.Name := 'Single';
   oxSerialization.Types.Double.InitFloat(ftDouble);
   oxSerialization.Types.Double.Name := 'Double';
   oxSerialization.Types.Extended.InitFloat(ftExtended);
   oxSerialization.Types.Extended.Name := 'Extended';
   oxSerialization.Types.Comp.InitFloat(ftComp);
   oxSerialization.Types.Comp.Name := 'Comp';
   oxSerialization.Types.Currency.InitFloat(ftCurr);
   oxSerialization.Types.Currency.Name := 'Currency';

   oxSerialization.Types.Color3ub.InitOrdArray(tkInteger, otUByte, 3);
   oxSerialization.Types.Color3ub.Name := 'Color3ub';
   oxSerialization.Types.Color4ub.InitOrdArray(tkInteger, otUByte, 4);
   oxSerialization.Types.Color4ub.Name := 'Color4ub';
   oxSerialization.Types.Color3f.InitFloatArray(ftSingle, 3);
   oxSerialization.Types.Color3f.Name := 'Color3f';
   oxSerialization.Types.Color4f.InitFloatArray(ftSingle, 4);
   oxSerialization.Types.Color4f.Name := 'Color4f';

   oxSerialization.Types.Vector2ub.InitOrdArray(tkInteger, otUByte, 2);
   oxSerialization.Types.Vector2ub.Name := 'Vector2ub';
   oxSerialization.Types.Vector3ub.InitOrdArray(tkInteger, otUByte, 3);
   oxSerialization.Types.Vector3ub.Name := 'Vector3ub';
   oxSerialization.Types.Vector4ub.InitOrdArray(tkInteger, otUByte, 4);
   oxSerialization.Types.Vector4ub.Name := 'Vector4ub';

   oxSerialization.Types.Vector2f.InitFloatArray(ftSingle, 2);
   oxSerialization.Types.Vector2f.Name := 'Vector2f';
   oxSerialization.Types.Vector3f.InitFloatArray(ftSingle, 3);
   oxSerialization.Types.Vector3f.Name := 'Vector3f';
   oxSerialization.Types.Vector4f.InitFloatArray(ftSingle, 4);
   oxSerialization.Types.Vector4f.Name := 'Vector4f';

   oxSerialization.Types.Vector2i.InitOrdArray(tkInteger, otSLong, 2);
   oxSerialization.Types.Vector2i.Name := 'Vector2i';
   oxSerialization.Types.Vector3i.InitOrdArray(tkInteger, otSLong, 3);
   oxSerialization.Types.Vector3i.Name := 'Vector3i';
   oxSerialization.Types.Vector4i.InitOrdArray(tkInteger, otSLong, 4);
   oxSerialization.Types.Vector4i.Name := 'Vector4i';

   oxSerialization.Types.TSet.Init(tkSet);
   oxSerialization.Types.TSet.Name := 'Set';
   oxSerialization.Types.Enum.Init(tkEnumeration);
   oxSerialization.Types.Enum.Name := 'Enumeration';
   oxSerialization.Types.DynamicArray.Init(tkDynArray);
   oxSerialization.Types.DynamicArray.Name := 'DynamicArray';

   oxSerialization.Types.tObject.Init(tkObject);
   oxSerialization.Types.tObject.Name := 'Object';

   oxSerialization.Types.tRecord.Init(tkRecord);
   oxSerialization.Types.tRecord.Name := 'Record';

   oxSerialization.Types.Pointer.Init(tkPointer);
end;

procedure initSerialization();
var
   i: loopint;

begin
   for i := 0 to oxSerialization.Serializers.n - 1 do begin
      oxSerialization.Serializers.List[i].PropertiesDone();
   end;
end;
 
INITIALIZATION
   init();

   ox.Init.Add('ox.serialization', @initSerialization);

   oxGlobalInstances.Add('oxTSerializationManager', @oxSerialization);

END.
