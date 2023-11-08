{
   oxuAndroidMedia, oX android media system
   Copyright (C) 2012. Dejan Boras

   Started On:    29.01.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAndroidMedia;

INTERFACE

   USES jni, jniutils, StringUtils,
     {file}
     uFileUtils, uFile, ypkuFS,
     {oX}
     oxuAndroidJNI, oxuMediaBase, oxuMedia;

TYPE

   { oxTAndroidMediaPlayer }

   oxTAndroidMediaPlayer = class(oxTMediaPlayer)
      private
         jgobj: jobject;

      public
      constructor Create();
      destructor Destroy(); override;

      function load(const fn: string): boolean; override;
      procedure unload(); override;

      procedure play(); override;
      procedure pause(); override;
      procedure resume(); override;
      procedure stop(); override;

      procedure setLoop(lp: boolean); override;
      procedure setVolume(lV, rV: single); override;
   end;

procedure jnioxAndroidMediaHandlerInit(env: PJNIEnv; obj: jobject); cdecl;

IMPLEMENTATION

{ JNI }

VAR
   jvidmLoad,
   jvidmUnload,
   jvidmPlay,
   jvidmPause,
   jvidmStop,
   jvidmSetLoop,
   jvidmSetVolume: jmethodID;

   jnih: oxTAndroidJNI;

procedure jnioxAndroidMediaHandlerInit(env: PJNIEnv; obj: jobject); cdecl;
begin
   oxAndroidJNIInitialize(jnih, env, 'nMediaPlayer', 'AndroidMedia');

   if(jnih.ok) then begin
      jnih.getConstructor();
      jvidmLoad         := jnih.findMethod('load', '(IJJ)Z');;
      jvidmUnload       := jnih.findMethod('unload', '()V');
      jvidmPlay         := jnih.findMethod('play', '()V');
      jvidmPause        := jnih.findMethod('pause', '()V');
      jvidmStop         := jnih.findMethod('stop', '()V');
      jvidmSetVolume    := jnih.findMethod('setVolume', '(FF)V');
      jvidmSetLoop      := jnih.findMethod('setLoop', '(Z)V');
   end;

   jnih.setInitialized();
end;

{ HANDLER }

function getMediaPlayer(): oxTMediaPlayer;
begin
   result := oxTAndroidMediaPlayer.Create();
end;

procedure setHandler();
begin
   oxMedia.pGetPlayer := @getMediaPlayer;
end;

{ MEDIA PLAYER }

{ oxTAndroidMediaPlayer }

constructor oxTAndroidMediaPlayer.Create();

begin
   inherited;

   if(oxMedia.enabled) then begin
      jgobj := jnih.env^^.NewObject(jnih.env, jnih.pClass, jnih.jvidConstructor);

      if(jgobj <> nil) then
         jgobj := jnih.env^^.NewGlobalRef(jnih.env, jgobj);
   end;
end;

destructor oxTAndroidMediaPlayer.Destroy();
begin
   inherited Destroy();

   jnih.DeleteGlobalRef(jgobj);
end;

function oxTAndroidMediaPlayer.load(const fn: string): boolean;
var
   pfs: ypkPFSFile;
   offs, size: fileint;

   jvalues: array[0..2] of jvalue;

begin
   unload();

   result := false;

   if(jnih.initialized) and (jgobj <> nil) then begin
      pfs := ypkfs.GetFS(fn);
      if(pfs <> nil) then begin
         {try to load the stream, and on success return the stream ID}
         if(ypkfs.Find(fn, offs, size)) then begin
            jvalues[0].i := pfs^.f.handleID;
            jvalues[1].j := offs;
            jvalues[2].j := size;
            result := jnih.env^^.CallBooleanMethodA(jnih.env, jgobj, jvidmLoad, @jvalues[0]) <> 0;

            loaded := result;
         end;
      end;
   end;
end;

procedure oxTAndroidMediaPlayer.unload();
begin
   if(loaded) then begin
      jnih.env^^.CallVoidMethod(jnih.env, jgobj, jvidmUnload);
      loaded := false;
   end;
end;

procedure oxTAndroidMediaPlayer.play();
begin
   if(loaded) and (jnih.initialized) and (jgobj <> nil) then
      jnih.env^^.CallVoidMethod(jnih.env, jgobj, jvidmPlay);
end;

procedure oxTAndroidMediaPlayer.pause();
begin
   if(loaded) and (jnih.initialized) and (jgobj <> nil) then
      jnih.env^^.CallVoidMethod(jnih.env, jgobj, jvidmPause);
end;

procedure oxTAndroidMediaPlayer.resume();
begin
   if(loaded) and (jnih.initialized) and (jgobj <> nil) then
      jnih.env^^.CallVoidMethod(jnih.env, jgobj, jvidmPlay);
end;

procedure oxTAndroidMediaPlayer.stop();
begin
   if(loaded) then
      jnih.env^^.CallVoidMethod(jnih.env, jgobj, jvidmStop);
end;

procedure oxTAndroidMediaPlayer.setLoop(lp: boolean);
var
   jvalues: array[0..0] of jvalue;

begin
   inherited setLoop(lp);

   if(jnih.initialized) and (jgobj <> nil) then begin
      jvalues[0].z := byte(loop);
      jnih.env^^.CallVoidMethodA(jnih.env, jgobj, jvidmSetLoop, @jvalues[0]);
   end;
end;

procedure oxTAndroidMediaPlayer.setVolume(lV, rV: single);
var
   jvalues: array[0..1] of jvalue;

begin
   inherited setVolume(lV, rV);

   if(jnih.initialized) and (jgobj <> nil) then begin
      jvalues[0].f := lv;
      jvalues[1].f := lv;
      jnih.env^^.CallVoidMethodA(jnih.env, jgobj, jvidmSetVolume, @jvalues[0]);
   end;
end;

INITIALIZATION
   oxMedia.onSetHandler := @setHandler;

END.

