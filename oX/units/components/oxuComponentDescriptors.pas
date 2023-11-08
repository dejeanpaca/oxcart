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

      constructor Create(const newId: string);
   end;

   oxTComponentDescriptorList = specialize TPreallocatedArrayList<oxPComponentDescriptor>;

   { oxTComponentDescriptors }

   oxTComponentDescriptors = record
      Unknown: oxTComponentDescriptor;

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

constructor oxTComponentDescriptor.Create(const newId: string);
begin
   if(newId = '') then
      Id := 'unknown'
   else
      Id := newId;

   Name := Id;
   Component := nil;

   {$IFDEF OX_LIBRARY}
   FromLibrary := true;
   {$ENDIF}

   {add ourselves immediately to the list}
   oxComponentDescriptors.Add(@Self);
end;

INITIALIZATION
   oxTComponentDescriptorList.Initialize(oxComponentDescriptors.List, 1024);
   oxComponentDescriptors.Unknown.Create('unknown');

END.
