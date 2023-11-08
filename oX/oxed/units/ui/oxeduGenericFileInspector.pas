{
   oxeduFileInspectors, handles file inspectors
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduGenericFileInspector;

INTERFACE

   USES
      uStd,
      {oxed}
      uOXED,
      oxeduInspectFile, oxeduFileInspectors;

TYPE
   oxedTGenericFileInspector = class(oxedTInspectFile)
   end;

VAR
   oxedGenericFileInspector: oxedTGenericFileInspector;

IMPLEMENTATION

procedure init();
begin
   oxedGenericFileInspector := oxedTGenericFileInspector.Create();
   oxedInspectFile.GenericInspector := oxedGenericFileInspector;
end;

procedure deinit();
begin
   if(oxedInspectFile.GenericInspector = oxedGenericFileInspector) then
      oxedInspectFile.GenericInspector := nil;

   FreeObject(oxedGenericFileInspector);
end;

INITIALIZATION
   oxed.Init.Add('inspector.file.generic', @init, @deinit);

END.
