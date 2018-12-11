{
   oxuAndroidVibrator, oX android media system
   Copyright (C) 2012. Dejan Boras

   Started On:    25.11.2013.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAndroidVibrator;

INTERFACE

   USES jni, jniutils, StringUtils,
     {file}
     uFileUtils, uFile, ypkuFS,
     {oX}
     oxuAndroidJNI, oxuVibrator;

TYPE

   { oxTAndroidVibratorDevice }

   oxTAndroidVibratorDevice = class(oxTVibratorDevice)
      private
         jgobj: jobject;

      public
      constructor Create();
      destructor Destroy; override;

      function supported(): boolean; override;
      procedure vibrate(duration: longint); override;
      procedure stop(); override;
   end;

procedure jnioxAndroidVibratorHandlerInit(env: PJNIEnv; obj: jobject); cdecl;

IMPLEMENTATION

{ JNI }

VAR
   jvidSupported,
   jvidStop,
   jvidVibrate,
   jvidVibratePattern: jmethodID;

   jnih: oxTAndroidJNI;

procedure setHandler();
begin
   oxVibratorDestroyHandler();
   oxVibrator := oxTAndroidVibratorDevice.Create();
end;

procedure jnioxAndroidVibratorHandlerInit(env: PJNIEnv; obj: jobject); cdecl;
begin
   oxAndroidJNIInitialize(jnih, env, 'nVibrator', 'AndroidVibrator');

   if(jnih.ok) then begin
      jnih.getConstructor();
      jvidSupported     := jnih.findMethod('supported', '()Z');
      jvidStop          := jnih.findMethod('stop', '()V');
      jvidVibrate       := jnih.findMethod('vibrate', '(J)V');
   end;

   jnih.setInitialized();
end;

{ oxTAndroidVibratorDevice }

constructor oxTAndroidVibratorDevice.Create;
begin
   inherited;

   if(oxcVibratorEnabled) then
      jgobj := jnih.NewGlobalRef();
end;

destructor oxTAndroidVibratorDevice.Destroy;
begin
   inherited Destroy;

   jnih.DeleteGlobalref(jgobj);
end;

function oxTAndroidVibratorDevice.supported(): boolean;
var
   isSupported: boolean;

begin
   result := false;

   if(oxcVibratorEnabled and jnih.initialized) then
      result := jnih.env^^.CallBooleanMethod(jnih.env, jgobj, jvidSupported) <> 0;
end;

procedure oxTAndroidVibratorDevice.vibrate(duration: longint);
var
   jvalues: array[0..0] of jvalue;

begin
   if(oxcVibratorEnabled and jnih.initialized) then begin
      jvalues[0].j := duration;

      jnih.env^^.CallVoidMethodA(jnih.env, jgobj, jvidVibrate, @jvalues);
   end;
end;

procedure oxTAndroidVibratorDevice.stop();
begin
   if(oxcVibratorEnabled and jnih.initialized) then
      jnih.env^^.CallVoidMethod(jnih.env, jgobj, jvidStop);
end;

function getVibrator(): oxTVibratorDevice;
begin
   result := oxTAndroidVibratorDevice.Create();
end;

INITIALIZATION
   oxonVibratorSetHandler  := @setHandler;
   oxpGetVibrator          := @getVibrator;
END.

