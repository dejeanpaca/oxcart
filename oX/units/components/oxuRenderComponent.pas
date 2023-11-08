{
   oxuRenderComponent, primitive model component
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuRenderComponent;

INTERFACE

   USES
      {ox}
      oxuComponent, oxuComponentDescriptors;

TYPE
   { oxTRenderComponent }

   oxTRenderComponent = class(oxTComponent)
      public
      procedure Render(); virtual;
      function GetDescriptor(): oxPComponentDescriptor; override;
   end;

IMPLEMENTATION

VAR
   descriptor: oxTComponentDescriptor;

{ oxTRenderComponent }

procedure oxTRenderComponent.Render();
begin

end;

function oxTRenderComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @descriptor;
end;

INITIALIZATION
   descriptor.Create('render', oxTRenderComponent);
   descriptor.Name := 'Render (Unknown)';

END.
