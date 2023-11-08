{
   oxuLight, light management
   Copyright (C) 2018. Dejan Boras

   Started On:    26.11.2018..
}

{$INCLUDE oxdefines.inc}
UNIT oxuLight;

INTERFACE

   USES
      uStd, vmMath,
      {app}
      appuMouse,
      {ox}
      oxuTransform, oxuSerialization;

TYPE
   {light type}
   oxTLightType = (
      oxLIGHT_TYPE_NONE
   );

   { oxTLight }

   oxTLight = class(oxTSerializable)
      public
      LightType: oxTLightType;
   end;

VAR
   {default light}
   oxDefaultLight: oxTLight;

IMPLEMENTATION

VAR
   serialization: oxTSerialization;

{ oxTLight }

function instance(): TObject;
begin
   Result := oxTLight.Create();
end;

INITIALIZATION
   serialization := oxTSerialization.Create(oxTLight, @instance);
   serialization.AddProperty('LightType', @oxTLight(nil).LightType, oxSerialization.Types.Enum);

FINALIZATION
   FreeObject(serialization);

END.
