{
   Commmon tools for tests.
   Copyright (C) 2011. Dejan Boras
}


{$INCLUDE oxheader.inc}
UNIT uTestTools;

INTERFACE

   USES
     uLog,
     {app}
     appuKeys, appuActionEvents,
     {ox}
     uOX, oxuTypes, oxuWindowTypes, oxuTexture, oxuTextureGenerate, oxuRunRoutines,
     oxuKeyboardControl, oxuTimer, vmVector, oxuTransform,
     uiuUI;

CONST
   rotSpeed: TVector3f = (20, 30, 40);

   lightAmbient:  array[0..2] of single  = (0.2, 0.2, 0.2);
   lightDiffuse:  array[0..2] of single  = (1.0, 1.0, 1.0);
   lightPosition: array[0..3] of single  = (0.0, 0.0, 10.0, 1.0);

TYPE
   TTestTools = record
      rot: TVector3f;

      procedure RotateXYZ(x, y, z: single);
      procedure RotateXYZ();
      procedure dtRotateXYZ();
      function LoadTexture(const name: string; var t: oxTTextureID): boolean;

      class function DefaultKeyUp(oxui: uiTUI; var key: appTKeyEvent; {%H-}wnd: oxTWindow): boolean; static;
   end;

VAR
   tt: TTestTools;


IMPLEMENTATION

procedure TTestTools.RotateXYZ(x, y, z: single);
begin
   oxTransform.Rotate(x, y, z);
   oxTransform.Apply();
end;

procedure TTestTools.RotateXYZ();
begin
   RotateXYZ(rot[0], rot[1], rot[2])
end;

procedure TTestTools.dtRotateXYZ();
begin
   rot[0] := rot[0] + rotSpeed[0] * oxTime.Flow;
   rot[1] := rot[1] + rotSpeed[1] * oxTime.Flow;
   rot[2] := rot[2] + rotSpeed[2] * oxTime.Flow;
end;

function TTestTools.loadTexture(const name: string; var t: oxTTextureID): boolean;
begin
   log.i('loading texture: ' + name + ' ...');
   Result := oxTextureGenerate.Generate(name, t) <> 0;

   if(Result) then
      log.i('ok');
end;

class function TTestTools.DefaultKeyUp(oxui: uiTUI; var key: appTKeyEvent; wnd: oxTWindow): boolean;
begin
   if(key.Key.Equal(kcESC)) then begin
      if(key.Key.Released()) then
         appActionEvents.QueueQuitEvent();

      exit(True);
   end;

   Result := False;
end;

procedure init();
begin
   oxKey.UpRoutine := @TTestTools.DefaultKeyUp;
end;

INITIALIZATION
   ox.OnInitialize.Add('test_tools', @init);

END.
