{
   oxuLight, light management
   Copyright (C) 2018. Dejan Boras

   Started On:    26.11.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuLight;

INTERFACE

   USES
      uStd, vmMath, vmVector,
      {app}
      appuMouse,
      {ox}
      oxuTransform, oxuSerialization;

TYPE
   {light type}
   oxTLightType = (
      oxLIGHT_TYPE_NONE,
      oxLIGHT_TYPE_DIRECTIONAL,
      oxLIGHT_TYPE_POINT
   );

   { oxTLight }

   oxTLight = record
      LightType: oxTLightType;

      Position,
      Direction: TVector3f;

      Radius: single;

      class procedure Initialize(out l: oxTLight); static;
   end;

VAR
   {default light}
   oxDefaultLight: oxTLight;

IMPLEMENTATION

VAR
   serialization: oxTSerialization;

{ oxTLight }

class procedure oxTLight.Initialize(out l: oxTLight);
begin
   ZeroPtr(@l, SizeOf(l));

   l.LightType := oxLIGHT_TYPE_DIRECTIONAL;
   l.Direction := vmvRight;
end;

INITIALIZATION
   serialization := oxTSerialization.CreateRecord('oxTLight');

   serialization.AddProperty('LightType', @oxTLight(nil^).LightType, oxSerialization.Types.Enum);
   serialization.AddProperty('Position', @oxTLight(nil^).Position, oxSerialization.Types.Vector3f);
   serialization.AddProperty('Direction', @oxTLight(nil^).Direction, oxSerialization.Types.Vector3f);
   serialization.AddProperty('Radius', @oxTLight(nil^).Radius, oxSerialization.Types.Single);

FINALIZATION
   FreeObject(serialization);

END.
