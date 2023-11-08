{
   oxuScene, scene object
   Copyright (c) 2011. Dejan Boras

   Started On:    05.11.2013.
}

{$INCLUDE oxdefines.inc}
UNIT oxuScene;

INTERFACE

   USES
      uStd,
      {ox}
      {$IFNDEF OX_LIBRARY}
      uOX, oxuRunRoutines,
      {$ENDIF}
      oxuGlobalInstances, oxuEntity, oxuWorld, oxuSerialization;

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


   oxPSceneManagement = ^oxTSceneManagement;

   { oxTSceneManagement }

   oxTSceneManagement = record
      {is scene functionality enabled (disable with care)}
      Enabled: boolean;

      InstanceType: oxTSceneClass;
      OnSceneChange: TProcedures;

      Serialization: oxTSerialization;

      class function Instance(): oxTScene; static;
      class procedure SetScene(newScene: oxTScene); static;
   end;

VAR
   {current scene}
   oxScene: oxTScene;
   oxSceneManagement: oxTSceneManagement;

IMPLEMENTATION

{$IFNDEF OX_LIBRARY}
procedure init();
begin
   oxSceneManagement.SetScene(oxSceneManagement.Instance());
end;

procedure deinit();
begin
   FreeObject(oxScene);
end;
{$ENDIF}

{ oxTSceneGlobal }

class function oxTSceneManagement.Instance(): oxTScene;
begin
  if(oxSceneManagement.InstanceType <> nil) then
     Result := oxSceneManagement.InstanceType.Create()
  else
     Result := oxTScene.Create();
end;

class procedure oxTSceneManagement.SetScene(newScene: oxTScene);
begin
   oxScene := newScene;

   oxSceneManagement.OnSceneChange.Call();
end;

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

function instanceGlobal(): TObject;
begin
   Result := oxSceneManagement.Instance();
end;

function instance(): TObject;
begin
   Result := oxTScene.Create();
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxSceneManagement.Enabled := True;

   oxGlobalInstances.Add(oxTScene, @oxScene, @instanceGlobal)^.Allocate := false;
   oxGlobalInstances.Add('oxTSceneManagement', @oxSceneManagement);

   TProcedures.Initialize(oxSceneManagement.OnSceneChange);

   oxSceneManagement.Serialization := oxTSerialization.Create(oxTScene, @instance);
   oxSceneManagement.Serialization.Inherits := oxEntity.Serialization;

   {$IFNDEF OX_LIBRARY}
   ox.Init.Add(initRoutines, 'ox.scene', @init, @deinit);
   {$ENDIF}

FINALIZATION
   FreeObject(oxSceneManagement.Serialization);

END.
