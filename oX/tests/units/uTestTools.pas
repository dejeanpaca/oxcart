{
   Commmon tools for tests.

   Started On:    18.02.2011.
}


{$INCLUDE oxdefines.inc}
UNIT uTestTools;

INTERFACE

   USES uLog,
     appuKeys, appuActionEvents,
     uOX, oxuTypes, oxuWindowTypes, oxuTexture, oxuTextureGenerate, oxuRunRoutines,
     oxuKeyboardControl, oxuTimer, vmVector, oxuTransform;

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

      class function DefaultKeyUp(var key: appTKeyEvent; {%H-}wnd: oxTWindow): boolean; static;
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

class function TTestTools.DefaultKeyUp(var key: appTKeyEvent; wnd: oxTWindow): boolean;
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

VAR
   initRoutine: oxTRunRoutine;

INITIALIZATION
   ox.OnInitialize.Add(initRoutine, 'test_tools', @init);

END.
