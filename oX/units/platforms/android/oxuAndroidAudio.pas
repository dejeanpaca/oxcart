{
   oxuAndroidAudio oX android system
   Copyright (C) 2012. Dejan Boras

   Started On:    23.01.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAndroidAudio;

INTERFACE

   USES jni, jniutils, sysutils, StringUtils,
     uFileUtils, uFile, ypkuFS,
     oxuAudioBase, oxuAudio, oxuAndroidJNI;

CONST
   ANDROID_AUDIO_MAX_LOAD_CHECK_CYCLES: longint    = 25;
   ANDROID_AUDIO_LOAD_CHECK_CYCLE_SLEEP: longint   = 20;

TYPE
   { oxTAndroidAudioHandler }
   oxTAndroidAudioHandler = class(oxTAudioHandler)
      private
         jgobj: jobject;

      public
      constructor Create();
      destructor Destroy(); override;

      function load(const fn: string): longint; override;
      function play(sID: longint): boolean; override;
      function pause(sID: longint): boolean; override;
      function resume(sID: longint): boolean; override;
      function stop(sID: longint): boolean; override;

      procedure setPriority(sID: longint; priority: longint); override;
      procedure setLoop(sID: longint; loop: longint); override;
      procedure setRate(sID: longint; rate: single); override;
      procedure setVolume(sID: longint; lV, rV: single); override;

      procedure destroyStream(sID: longint); override;
   end;

procedure jnioxAndroidAudioHandlerInit(env: PJNIEnv; obj: jobject); cdecl;

IMPLEMENTATION

{ JNI }

VAR
   jnih: oxTAndroidJNI;

   jvidLoad,
   jvidPlay,
   jvidPlayDefault,
   jvidPause,
   jvidResume,
   jvidStop,
   jvidUnload,
   jvidSetPriority,
   jvidSetLoop,
   jvidSetRate,
   jvidSetVolume,
   jvidSoundLoaded: jmethodID;

{initializes the jni interface}
procedure jnioxAndroidAudioHandlerInit(env: PJNIEnv; obj: jobject); cdecl;
begin
   oxAndroidJNIInitialize(jnih, env, 'nSoundPool', 'AndroidAudio');

   if(jnih.ok) then begin
      jnih.getConstructor();
      jvidLoad          := jnih.findMethod('load', '(IJJI)I');
      jvidPlay          := jnih.findMethod('play', '(IFFIIF)V');
      jvidPlayDefault   := jnih.findMethod('playDefault', '(I)V');
      jvidPause         := jnih.findMethod('pause', '(I)V');
      jvidResume        := jnih.findMethod('resume', '(I)V');
      jvidStop          := jnih.findMethod('stop', '(I)V');
      jvidUnload        := jnih.findMethod('unload', '(I)Z');
      jvidSetPriority   := jnih.findMethod('setPriority', '(II)V');
      jvidSetLoop       := jnih.findMethod('setLoop', '(II)V');
      jvidSetRate       := jnih.findMethod('setRate', '(IF)V');
      jvidSetVolume     := jnih.findMethod('setVolume', '(IFF)V');
      jvidSoundLoaded   := jnih.findMethod('soundLoaded', '(I)Z');
   end;

   jnih.setInitialized();
end;

{ AUDIO HANDLER }

constructor oxTAndroidAudioHandler.Create();
begin
   inherited;

   if(oxAudio.enabled) then
      jgobj := jnih.NewGlobalRef();
end;

destructor oxTAndroidAudioHandler.Destroy;
begin
   inherited Destroy;

   jnih.DeleteGlobalref(jgobj);
end;

function oxTAndroidAudioHandler.load(const fn: string): longint;
var
   e: longint;
   pfs: ypkPFSFile;
   offs, size: fileint;
   loaded: boolean = false;
   cycles: longint;
   esID: longint;

   jvalues: array[0..3] of jvalue;

begin
   e := getNewStream();

   if(e > -1) then begin
      pfs := ypkfs.GetFS(fn);
      if(pfs <> nil) then
         {try to load the stream, and on success return the stream ID}
         if(ypkfs.Find(fn, offs, size)) then begin
            result := 0;
            esID := 0;
            if(jnih.initialized) then begin
               jvalues[0].i := pfs^.f.handleID;
               jvalues[1].j := offs;
               jvalues[2].j := size;
               jvalues[3].i := 1;
               esID := jnih.env^^.CallIntMethodA(jnih.env, jgobj, jvidLoad, @jvalues);
            end;

            if(esID > 0) then begin
               streams[e]^.esID := esID;

               {check if the file has loaded}
               cycles := 0;
               jvalues[0].i := esID;
               repeat
                  sleep(ANDROID_AUDIO_LOAD_CHECK_CYCLE_SLEEP);

                  loaded := jnih.env^^.CallBooleanMethodA(jnih.env, jgobj, jvidSoundLoaded, @jvalues) <> 0;

                  inc(cycles);
               until (loaded) or (cycles >= ANDROID_AUDIO_MAX_LOAD_CHECK_CYCLES);
               {done}
               exit(e);
            end;
         end;

      {if failed to load the stream destroy it}
      destroyStream(e);
   end;

   result := -1;
end;

function oxTAndroidAudioHandler.play(sID: longint): boolean;
var
   pStream: oxPAudioStream;
   jvalues: array[0..5] of jvalue;

begin
   result := false;
   if(validStreamID(sID) and  jnih.initialized) then begin
      pStream := streams[sID];

      jvalues[0].i := streams[sID]^.esID;
      jvalues[1].f := pStream^.leftVolume;
      jvalues[2].f := pStream^.rightVolume;
      jvalues[3].i := pStream^.priority;
      jvalues[4].i := pStream^.loop;
      jvalues[5].f := pStream^.rate;
      jnih.env^^.CallVoidMethodA(jnih.env, jgobj, jvidPlay, @jvalues);

      result := true;
   end;
end;

function oxTAndroidAudioHandler.pause(sID: longint): boolean;
var
   jvalues: array[0..0] of jvalue;

begin
   result := false;
   if(validStreamID(sID) and jnih.initialized) then begin
      result := true;
      jvalues[0].i := streams[sID]^.esID;
      jnih.env^^.CallVoidMethodA(jnih.env, jgobj, jvidPause, @jvalues);
   end;
end;

function oxTAndroidAudioHandler.resume(sID: longint): boolean;
var
   jvalues: array[0..1] of jvalue;

begin
   result := false;
   if(validStreamID(sID) and jnih.initialized) then begin
      result := true;
      jvalues[0].i := streams[sID]^.esID;
      jnih.env^^.CallVoidMethodA(jnih.env, jgobj, jvidResume, @jvalues);
   end;
end;

function oxTAndroidAudioHandler.stop(sID: longint): boolean;
var
   jvalues: array[0..0] of jvalue;

begin
   result := false;

   if(validStreamID(sID) and jnih.initialized) then begin
      result := true;
      jvalues[0].i := streams[sID]^.esID;
      jnih.env^^.CallVoidMethodA(jnih.env, jgobj, jvidStop, @jvalues);
   end;
end;

procedure oxTAndroidAudioHandler.setPriority(sID: longint; priority: longint);
var
   jvalues: array[0..1] of jvalue;

begin
   inherited;

   if(validStreamID(sID) and jnih.initialized) then begin
      jvalues[0].i := streams[sID]^.esID;
      jvalues[1].i := priority;
      jnih.env^^.CallVoidMethodA(jnih.env, jgobj, jvidSetPriority, @jvalues);
   end;
end;

procedure oxTAndroidAudioHandler.setLoop(sID: longint; loop: longint);
var
   jvalues: array[0..1] of jvalue;

begin
   inherited;

   if(validStreamID(sID) and jnih.initialized) then begin
      jvalues[0].i := streams[sID]^.esID;
      jvalues[1].i := loop;
      jnih.env^^.CallVoidMethodA(jnih.env, jgobj, jvidSetLoop, @jvalues);
   end;
end;

procedure oxTAndroidAudioHandler.setRate(sID: longint; rate: single);
var
   jvalues: array[0..1] of jvalue;

begin
   if(validStreamID(sID) and jnih.initialized) then begin
      streams[sID]^.rate := rate;

      jvalues[0].i := streams[sID]^.esID;
      jvalues[1].f := rate;
      jnih.env^^.CallVoidMethodA(jnih.env, jgobj, jvidSetRate, @jvalues);
   end;
end;

procedure oxTAndroidAudioHandler.setVolume(sID: longint; lV, rV: single);
var
   jvalues: array[0..2] of jvalue;

begin
   inherited;

   if(validStreamID(sID) and jnih.initialized) then begin
      jvalues[0].i := streams[sID]^.esID;
      jvalues[1].f := lV;
      jvalues[2].f := rV;
      jnih.env^^.CallVoidMethodA(jnih.env, jgobj, jvidSetVolume, @jvalues);
   end;
end;

procedure oxTAndroidAudioHandler.destroyStream(sID: longint);
var
   jvalues: array[0..0] of jvalue;
   result: boolean;

begin
   if(validStreamID(sID)) then begin
      if((streams[sID]^.esID > 0) and jnih.initialized) then begin
         jvalues[0].i := streams[sID]^.esID;
         result := jnih.env^^.CallBooleanMethodA(jnih.env, jgobj, jvidUnload, @jvalues) <> 0;
      end;
   end;

   inherited destroyStream(sID);
end;

procedure setHandler();
begin
   oxAudio.DestroyHandler();
   oxa := oxTAndroidAudioHandler.Create();
end;


INITIALIZATION
   oxAudio.onSetHandler := @setHandler;
END.

