{
   Serialization, tests serialization

   Started On:    16.05.2017.
}

{$INCLUDE oxdefines.inc}{$M+}
PROGRAM Serialization;

   USES
      uStd, uTest, uLog, vmVector, typinfo,
      {ox}
      oxuSerialization, oxuSerializationFile;

TYPE
   TExampleEnum = (EXAMPLE_ENUM_ONE, EXAMPLE_ENUM_TWO, EXAMPLE_ENUM_THREE);
   TExampleSet = set of TExampleEnum;

   TExampleSerializable = class(oxTSerializable)
      public
         {properties not serializable via published properties}
         oxChar: char;
         oxLongint: longint;
         oxVector3f: TVector3f;
         oxEnum: TExampleEnum;
         oxSet: TExampleSet;
         oxString: AnsiString;
         oxShortString: ShortString;

      published
         property PublishedChar: char read oxChar write oxChar;
         property PublishedLongint: longint read oxLongint write oxLongint;
         property PublishedEnum: TExampleEnum read oxEnum write oxEnum;
         property PublishedSet: TExampleSet read oxSet write oxSet;
         property PublishedAnsiString: AnsiString read oxString write oxString;
         property PublishedShortString: ShortString read oxShortString write oxShortString;

   end;

VAR
   example: TExampleSerializable;
   exampleSerializer: oxTSerialization;

procedure test_prop_count();
begin
   UnitTests.Assert(exampleSerializer.GetPropCount() = 11);
end;

procedure test_get_props();
var
   i: loopint;
   value: string;

begin
   for i := 0 to exampleSerializer.GetPropCount() - 1 do begin
      value := exampleSerializer.GetPropValue(example, i);
      log.v(exampleSerializer.Properties.List[i].Name + ' = ' + value);

      if(not UnitTests.Assert(value <> '')) then begin
         log.e('Failed deserializing ' + exampleSerializer.Properties.List[i].Name);
         exit;
      end;
   end;
end;

procedure test_set_props();
var
   i: loopint;
   value: string;

function testProp(const prop, setValue: string): boolean;
begin
   exampleSerializer.SetProp(example, prop, setValue);

   value := exampleSerializer.GetPropValue(example, prop);
   result := UnitTests.Assert(value = setValue,
      prop + ' property mismatching: ' + value + ', expected ' + setValue);
end;

begin
   if(not testProp('oxChar', 'A')) then
      exit;

   if(not testProp('oxLongint', '8192')) then
      exit;

   if(not testProp('oxVector3f', '[ 1.000000000E+00, 1.000000000E+00, 1.000000000E+00]')) then
      exit;

   if(not testProp('oxSet', '[EXAMPLE_ENUM_TWO]')) then
      exit;

   if(not testProp('oxEnum', 'EXAMPLE_ENUM_THREE')) then
      exit;

   if(not testProp('oxString', 'set ansistring')) then
      exit;

   if(not testProp('oxShortString', 'set shortstring')) then
      exit;

   for i := 0 to exampleSerializer.GetPropCount() - 1 do begin
      value := exampleSerializer.GetPropValue(example, i);

      log.v(exampleSerializer.Properties.List[i].Name + ' = ' + value);
   end;
end;

function instance(): TObject;
begin
   result := TExampleSerializable.Create();
end;

BEGIN
   example := TExampleSerializable.Create();

   example.oxChar := '@';
   example.oxLongint:= 1023;
   example.oxVector3f.Assign(1, 2, 3);
   example.oxSet := [EXAMPLE_ENUM_ONE, EXAMPLE_ENUM_THREE];
   example.oxString := 'oxcart';
   example.oxEnum := EXAMPLE_ENUM_ONE;
   example.oxShortString := 'oxcart_shortstring';

   exampleSerializer := oxTSerialization.Create(TExampleSerializable, @instance);

   {published properties}
   exampleSerializer.AddCharProperty('PublishedChar');
   exampleSerializer.AddLongintProperty('PublishedLongint');
   exampleSerializer.AddAnsistringProperty('PublishedAnsiString');
   exampleSerializer.AddShortstringProperty('PublishedShortString');

   {ox properties}
   exampleSerializer.AddProperty('oxChar', @TExampleSerializable(nil).oxChar, oxSerialization.Types.Char);
   exampleSerializer.AddProperty('oxLongint', @TExampleSerializable(nil).oxLongint, oxSerialization.Types.Longint);
   exampleSerializer.AddProperty('oxVector3f', @TExampleSerializable(nil).oxVector3f, oxSerialization.Types.Vector3f);
   exampleSerializer.AddProperty('oxSet', @TExampleSerializable(nil).oxSet, oxSerialization.Types.TSet, TypeInfo(TExampleSet));
   exampleSerializer.AddProperty('oxEnum', @TExampleSerializable(nil).oxEnum, oxSerialization.Types.Enum, TypeInfo(TExampleEnum));
   exampleSerializer.AddProperty('oxString', @TExampleSerializable(nil).oxString, oxSerialization.Types.AnsiString);
   exampleSerializer.AddProperty('oxShortString', @TExampleSerializable(nil).oxShortString, oxSerialization.Types.ShortString);

   exampleSerializer.PropertiesDone();

   UnitTests.Initialize('ox.serialization');
   UnitTests.Add('prop_count', 'Get property count', @test_prop_count);
   UnitTests.Add('get_props', 'Get properties', @test_get_props);
   UnitTests.Add('set_props', 'Set properties', @test_set_props);

   UnitTests.Run();

   FreeObject(example);
   FreeObject(exampleSerializer);
END.
