{
   oxuComponent, component management
   Copyright (c) 2017. Dejan Boras

   Started On:    17.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuComponentDescriptors;

INTERFACE

   USES
      uStd,
      {ox}
      oxuTransform, oxuSerialization;

TYPE
   oxPComponentDescriptor = ^oxTComponentDescriptor;

   { oxTComponentDescriptor }

   oxTComponentDescriptor = object
      Id,
      Name: string;

      {$IFDEF OX_LIBRARY_SUPPORT}
      {does this component reside in a library}
      InLibrary: boolean;
      {$ENDIF}

      Component: TClass;

      constructor Create(const newId: string; componentType: TClass);
   end;

   { oxTUnknownComponentDescriptor }

   oxTUnknownComponentDescriptor = object(oxTComponentDescriptor)
      constructor CreateUnknown();
   end;

   oxTComponentDescriptorList = specialize TSimpleList<oxPComponentDescriptor>;

   { oxTComponentDescriptors }

   oxTComponentDescriptors = record
      Unknown: oxTUnknownComponentDescriptor;

      List: oxTComponentDescriptorList;

      procedure Add(descriptor: oxPComponentDescriptor);
   end;

VAR
   oxComponentDescriptors: oxTComponentDescriptors;

IMPLEMENTATION

{ oxTComponentDescriptors }

procedure oxTComponentDescriptors.Add(descriptor: oxPComponentDescriptor);
begin
   List.Add(descriptor);
end;


{ oxTComponentDescriptor }

constructor oxTComponentDescriptor.Create(const newId: string; componentType: TClass);
begin
   if(newId = '') then
      Id := 'unknown'
   else
      Id := newId;

   Name := Id;
   Component := componentType;

   {$IFDEF OX_LIBRARY}
   InLibrary := true;
   {$ENDIF}

   {add ourselves immediately to the list}
   oxComponentDescriptors.Add(@Self);
end;

{ oxTUnknownComponentDescriptor }

constructor oxTUnknownComponentDescriptor.CreateUnknown();
begin
   Id := 'unknown';
   Name := Id;
   Component := nil;

   {$IFDEF OX_LIBRARY}
   InLibrary := true;
   {$ENDIF}
end;


INITIALIZATION
   oxTComponentDescriptorList.Initialize(oxComponentDescriptors.List, 1024);
   oxComponentDescriptors.Unknown.CreateUnknown();

END.
