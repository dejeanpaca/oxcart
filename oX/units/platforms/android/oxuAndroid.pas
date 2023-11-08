{
   oxuAndroid, android interface for oX
   Copyright (c) 2011. Dejan Boras

   Started On:    11.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAndroid;

INTERFACE

   USES
      androidlog, jni, jniutils, baseunix, uStd, uAppInfo, uApp, uPropertySection,
      {std}
      uLog, ulogAndroid, StringUtils,
      {app}
      appuEvents, appuMouse, appuMouseEvents, appuKeys, appuKeyEvents, appuAndroidKey,
      appuApplicationEvents, appuLog, oxuOGL,
      {oX}
      uOX, oxuInit, oxuWindow, oxuWindows, oxuWindowTools, oxuRun, appuPathsPropertySection;

CONST
   oxcAndroidExtLogging: boolean          = true;
   oxcAndroidExtLoggingFilename: string   = 'ox';

TYPE
   oxTAndroidData = record
      width,
      height: longint;
   end;

VAR
   oxcAndroidExtLogHandler: PLogHandler;
   oxAndroid: oxTAndroidData;
   oxnClass: PJClass;
   oxnEnv: PJNIEnv;

{initialize the android interface}
procedure androidInit();
{pre-initialization procedures, such as setting up logging, etc.}
procedure androidPreInit();
{change of surface}
procedure androidSurfaceChange(w, h: longint);
{run a cycle}
function androidRunCycle(): longint;
{destroy oX}
procedure androidDestroy();
{a touch event}
procedure androidTouch(x, y: single; action: longint);
{a key event}
procedure androidKey(keyCode, action: longint);
{quit from the application}
procedure androidQuit();
{terminate the application}
procedure androidTerminate();

procedure jniAndroidInit(env: PJNIEnv; obj: jobject); cdecl;
procedure jniAndroidPreInit(env: PJNIEnv; obj: jobject); cdecl;
procedure jniAndroidSurfaceChange(env: PJNIEnv; obj: jobject; w, h: jint); cdecl;
function jniAndroidRunCycle(env: PJNIEnv; obj: jobject): longint; cdecl;
procedure jniAndroidDestroy(env: PJNIEnv; obj: jobject); cdecl;
procedure jniAndroidTouch(env: PJNIEnv; obj: jobject; x, y: jfloat; action: jint); cdecl;
procedure jniAndroidKey(env: PJNIEnv; obj: jobject; keyCode, action: jint); cdecl;
procedure jniAndroidQuit(env: PJNIEnv; obj: jobject); cdecl;
procedure jniAndroidTerminate(env: PJNIEnv; obj: jobject); cdecl;

{ PROPERTY SECTIONS }

procedure jniAndroidSetStringProperty(env: PJNIEnv; obj: jobject; section: jstring; code: jint; prop: jstring); cdecl;
procedure jniAndroidSetIntProperty(env: PJNIEnv; obj: jobject; section: jstring; code: jint; prop: jint); cdecl;
procedure jniAndroidSetBooleanProperty(env: PJNIEnv; obj: jobject; section: jstring; code: jint; prop: jboolean); cdecl;

{ JNI }

procedure oxnInitialize(env: PJNIEnv; obj: jobject); cdecl;

IMPLEMENTATION

CONST
   LOG_TAG = 'oX';

VAR
   inited: boolean = false;
   extlog: TLog;

procedure androidInit();
begin
end;

procedure androidPreInit();
begin
   if(not inited) then begin
      {initialize standard log}
      stdlog.tag := LOG_TAG;
      android_log_tag := LOG_TAG;
      android_logi('Initializing logging...');
      stdlog.Handler := @loghAndroid;
      log.InitStd('oxAndroid', '', logcREWRITE);

      if(stdlog.error = 0) then begin
         {initialize external(sdcard) log and chain it with stdlog}
         if(oxcAndroidExtLogging) then begin
            log.Init(extlog);
            extlog.Handler := oxcAndroidExtLogHandler;
            extlog.Initialize('/mnt/sdcard/' + oxcAndroidExtLoggingFilename, 'oX', logcREWRITE);

            extlog.Open();
            if(extlog.error <> 0) then
               android_loge('Error(' + sf(extlog.error) + ') initializing external logging.')
            else
               android_logi('External logging initialized. File: ' + extlog.FileName);

            stdlog.chainLog := @extlog;
         end;

         log.i('Logging initialized.');
      end else
         android_loge('Failed to initialize logging.');

      inited := true;
   end else
      android_loge('Already called Native.Init');
end;

VAR
   cX, cY: longint;

procedure CreateWindows();
begin
   oxSetupWindows(1);
   oxWindows.w[0].SetDimensions(cX, cY);

   oxWindows.w[0].SetTitle('oX Android');
end;

procedure androidSurfaceChange(w, h: longint);
begin
   if(inited) then begin
      cX := w;
      cY := h;

      if(not ox.initialized) then begin
         oxWindows.onCreate := @CreateWindows;
         if(not oxRun.Initialize()) then begin
            android_loge('failed to initialize oX');
            androidTerminate();
         end;
      end;


      log.i('Surface change: ' + sf(w) + 'x' + sf(h));
   end;
end;

function androidRunCycle(): longint;
begin
   if(not inited) then begin
      android_logw('Quitting. Not initialized');
      exit(-1);
   end;

   result := 0;

   if(ox.initialized) then
      oxRun.GoCycle();

   if(not app.active) then begin
      log.i('App no longer active');
      androidTerminate();
   end;
end;

procedure androidDestroy();
begin
   if(inited) then begin
      log.i('Request for destruction.');

      oxDeInitialize();

      inited := false;
   end;
end;

procedure androidTouch(x, y: single; action: longint);
var
   mEvent: appTMouseEvent;
   e: appPEvent;

begin
   Zero(mEvent, SizeOf(mEvent));

   case action of
      0: mEvent.Action := appmcPRESSED;
      1: mEvent.Action := appmcRELEASED;
      2: mEvent.Action := appmcMOVED;
   end;

   if(action <> 1) then
      mEvent.bState  := appmcLEFT;
   mEvent.Button     := appmcLEFT;
   mEvent.x          := x;
   mEvent.y          := y;

   e        := appQueueMouseEvent(appMOUSE_EVENT, mEvent);
   e^.wnd   := oxWindows.w[0];
end;

procedure androidKey(keyCode, action: longint);
var
   e: appPEvent;

begin
   e        := androidQueueKeyEvent(keyCode, action);
   e^.wnd   := oxWindows.w[0];
end;

procedure androidQuit();
begin
   appQueueQuitEvent();
end;

procedure androidTerminate();
begin
   androidDestroy();
end;

{ }

procedure jniAndroidInit(env: PJNIEnv; obj: jobject); cdecl;
begin
   androidInit();
end;

procedure jniAndroidPreInit(env: PJNIEnv; obj: jobject); cdecl;
begin
   androidPreInit();
end;

procedure jniAndroidSurfaceChange(env: PJNIEnv; obj: jobject; w, h: jint); cdecl;
begin
   androidSurfaceChange(w, h);
end;

function jniAndroidRunCycle(env: PJNIEnv; obj: jobject): longint; cdecl;
begin
   result := androidRunCycle();
end;

procedure jniAndroidDestroy(env: PJNIEnv; obj: jobject); cdecl;
begin
   androidDestroy();
end;

procedure jniAndroidTouch(env: PJNIEnv; obj: jobject; x, y: jfloat; action: jint); cdecl;
begin
   androidTouch(x, y, action);
end;

procedure jniAndroidKey(env: PJNIEnv; obj: jobject; keyCode, action: jint); cdecl;
begin
   androidKey(keyCode, action);
end;

procedure jniAndroidQuit(env: PJNIEnv; obj: jobject); cdecl;
begin
   androidQuit();
end;

procedure jniAndroidTerminate(env: PJNIEnv; obj: jobject); cdecl;
begin
   halt(0);
end;

{ PROPERTY SECTIONS }

procedure jniAndroidSetStringProperty(env: PJNIEnv; obj: jobject; section: jstring; code: jint; prop: jstring); cdecl;
begin
   propertySections.SetString(jniJStringToString(env, section), code, jniJStringToString(env, prop));
end;

procedure jniAndroidSetIntProperty(env: PJNIEnv; obj: jobject; section: jstring; code: jint; prop: jint); cdecl;
begin
   propertySections.SetInt(jniJStringToString(env, section), code, prop);
end;

procedure jniAndroidSetBooleanProperty(env: PJNIEnv; obj: jobject; section: jstring; code: jint; prop: jboolean); cdecl;
begin
   propertySections.SetBoolean(jniJStringToString(env, section), code, prop <> 0);
end;

{ JNI }

procedure oxnInitialize(env: PJNIEnv; obj: jobject); cdecl;
begin
   oxnClass := env^^.FindClass(env, 'dbx/oX/Native/oxn');
   oxnEnv   := env;

   android_logi('oxn initialized');
end;

INITIALIZATION
   log.Init(extlog);

   appLog.skipInit := true;
   oxcAndroidExtLogHandler := @log.handler.Standard;
END.
