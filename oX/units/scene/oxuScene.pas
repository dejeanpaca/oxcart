{
   oxuScene, scene object
   Copyright (c) 2011. Dejan Boras

   Started On:    05.11.2013.
}

{$INCLUDE oxdefines.inc}
UNIT oxuScene;

INTERFACE

   USES
      {ox}
      oxuEntity, oxuWorld;

TYPE
   { oxTScene }

   oxTScene = class(oxTEntity)
      public
      World: oxTWorld;

      constructor Create(); override;

      {empty the scene (destroy all objects)}
      destructor Destroy(); override;

      procedure OnLoad(); virtual;

      procedure CallOnLoaded();
      procedure CallAwake();
   end;

   oxTSceneClass = class of oxTScene;

VAR
   {current scene}
   oxScene: oxTScene;

IMPLEMENTATION

{ oxTScene }

constructor oxTScene.Create();
begin
   inherited;

   World := oxWorld;
end;

destructor oxTScene.Destroy();
begin
   inherited;
end;

procedure oxTScene.OnLoad();
begin

end;

procedure oxTScene.CallOnLoaded();
begin
   OnLoad();
end;

procedure oxTScene.CallAwake();
begin
end;

END.
