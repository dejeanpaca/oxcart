{
   oxuSceneManagement, scene management
   Copyright (c) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuSceneManagement;

INTERFACE

   USES
      uStd,
      {ox}
      {$IFNDEF OX_LIBRARY}
      uOX, oxuRunRoutines,
      {$ENDIF}
      oxuGlobalInstances, oxuEntity, oxuSerialization, oxuScene;

TYPE
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

function instanceGlobal(): TObject;
begin
   Result := oxSceneManagement.Instance();
end;

function instance(): TObject;
begin
   Result := oxTScene.Create();
end;

INITIALIZATION
   oxSceneManagement.Enabled := True;

   oxGlobalInstances.Add(oxTScene, @oxScene, @instanceGlobal)^.Allocate := false;
   oxGlobalInstances.Add('oxTSceneManagement', @oxSceneManagement);

   TProcedures.Initialize(oxSceneManagement.OnSceneChange);

   oxSceneManagement.Serialization := oxTSerialization.Create(oxTScene, @instance);
   oxSceneManagement.Serialization.Inherits := oxEntity.Serialization;

   {$IFNDEF OX_LIBRARY}
   ox.Init.Add('ox.scene', @init, @deinit);
   {$ENDIF}

FINALIZATION
   FreeObject(oxSceneManagement.Serialization);

END.
