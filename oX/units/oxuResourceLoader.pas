{
   oxuShades, oX shader management
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuResourceLoader;

INTERFACE

   USES
      uStd, oxuTypes;

TYPE
   oxPResourceLoader = ^oxTResourceLoader;

   { oxTResourceLoader }

   oxTResourceLoader = object
      Name: StdString;

      constructor Create();

      function Load({%H-}resource: oxTResource): boolean; virtual;
   end;

IMPLEMENTATION

{ oxTResourceLoader }

constructor oxTResourceLoader.Create();
begin
   Name := 'Unknown';
end;

function oxTResourceLoader.Load(resource: oxTResource): boolean;
begin
   Result := false;
end;

END.
