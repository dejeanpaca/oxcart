{
   oxuWorld, world
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuWorld;

INTERFACE

   USES
      uStd, uColors,
      {ox}
      {$IFNDEF OX_LIBRARY}
      uOX, oxuRunRoutines,
      {$ENDIF}
      oxuSerialization, oxuGlobalInstances;

TYPE
   { oxTWorld }

   oxTWorld = class(oxTSerializable)
      public
      ClearColor: TColor4f;

      constructor Create(); override;
   end;

VAR
   {current scene world}
   oxWorld: oxTWorld;

IMPLEMENTATION

VAR
   serialization: oxTSerialization;

function instance(): TObject;
begin
   Result := oxTWorld.Create();
end;

{$IFNDEF OX_LIBRARY}
procedure init();
begin
   oxWorld := oxTWorld.Create();
end;

procedure deinit();
begin
   FreeObject(oxWorld);
end;
{$ENDIF}

{ oxTWorld }

constructor oxTWorld.Create();
begin
   ClearColor := cBlue4f;
end;

INITIALIZATION
   {$IFNDEF OX_LIBRARY}
   ox.Init.Add('ox.world', @init, @deinit);
   {$ENDIF}

   serialization := oxTSerialization.Create(oxTWorld, @instance);
   serialization.AddProperty('ClearColor', @oxTWorld(nil).ClearColor, oxSerialization.Types.Color4f);

   oxGlobalInstances.Add(oxTWorld, @oxWorld, @instance)^.Allocate := false;

FINALIZATION
   FreeObject(serialization);

END.
