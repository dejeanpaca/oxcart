(*
 * Copyright (C) 2010 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 *)

UNIT android_native_app_glue;

{$packrecords c}

INTERFACE

  USES
     baseunix, unixtype,
     android_log_helper, rect, input, native_activity, looper, configuration, native_window,
     StringUtils, uStd;

  (**
   * The native activity interface provided by <android/native_activity.h>
   * is based on a set of application-provided callbacks that will be called
   * by the Activity's main thread when certain events occur.
   *
   * This means that each one of this callbacks _should_ _not_ block, or they
   * risk having the system force-close the application. This programming
   * model is direct, lightweight, but constraining.
   *
   * The 'android_native_app_glue' static library is used to provide a different
   * execution model where the application can implement its own main event
   * loop in a different thread instead. Here's how it works:
   *
   * 1/ The application must provide a function named "android_main()" that
   *    will be called when the activity is created, in a new thread that is
   *    distinct from the activity's main thread.
   *
   * 2/ android_main() receives a pointer to a valid "android_app" structure
   *    that contains references to other important objects, e.g. the
   *    ANativeActivity obejct instance the application is running in.
   *
   * 3/ the "android_app" object holds an ALooper instance that already
   *    listens to two important things:
   *
   *      - activity lifecycle events (e.g. "pause", "resume"). See APP_CMD_XXX
   *        declarations below.
   *
   *      - input events coming from the AInputQueue attached to the activity.
   *
   *    Each of these correspond to an ALooper identifier returned by
   *    ALooper_pollOnce with values of LOOPER_ID_MAIN and LOOPER_ID_INPUT,
   *    respectively.
   *
   *    Your application can use the same ALooper to listen to additional
   *    file-descriptors.  They can either be callback based, or with return
   *    identifiers starting with LOOPER_ID_USER.
   *
   * 4/ Whenever you receive a LOOPER_ID_MAIN or LOOPER_ID_INPUT event,
   *    the returned data will point to an android_poll_source structure.  You
   *    can call the process() function on it, and fill in app^.onAppCmd
   *    and app^.onInputEvent to be called for your own processing
   *    of the event.
   *
   *    Alternatively, you can call the low-level functions to read and process
   *    the data directly...  look at the process_cmd() and process_input()
   *    implementations in the glue to see how to do this.
   *
   * See the sample named "native-activity" that comes with the NDK with a
   * full usage example.  Also look at the JavaDoc of NativeActivity.
   *)

TYPE
   Pandroid_app = ^android_app;
   Pandroid_poll_source = ^android_poll_source;

   (**
    * Data associated with an ALooper fd that will be returned as the "outData"
    * when that source has data ready.
    *)
   android_poll_source = packed record
      // The identifier of this source.  May be LOOPER_ID_MAIN or
      // LOOPER_ID_INPUT.
      id: cint32;
      // The android_app this ident is associated with.
      app: Pandroid_app;
      // Function to call to perform the standard processing of data from
      // this source.
      process: procedure(app: Pandroid_app; source: Pandroid_poll_source); cdecl;
   end;

   (**
    * This is the interface for the standard glue code of a threaded
    * application.  In this model, the application's code is running
    * in its own thread separate from the main thread of the process.
    * It is not required that this thread be associated with the Java
    * VM, although it will need to be in order to make JNI calls any
    * Java objects.
    *)
   android_app = record
      // The application can place a pointer to its own state object
      // here if it likes.
      userData: pointer;

      // Fill this in with the function to process main app commands (APP_CMD_*)
      onAppCmd: procedure(app: Pandroid_app; cmd: cint32);

      // Fill this in with the function to process input events.  At this point
      // the event has already been pre-dispatched, and it will be finished upon
      // return.  Return 1 if you have handled the event, 0 for any default
      // dispatching.
      onInputEvent: function(app: Pandroid_app; event: PAInputEvent): cint32;

      // The ANativeActivity object instance that this app is running in.
      activity: PANativeActivity;

      // The current configuration the app is running in.
      config: PAConfiguration;

      // This is the last instance's saved state, as provided at creation time.
      // It is NULL if there was no state.  You can use this as you need; the
      // memory will remain around until you call android_app_exec_cmd() for
      // APP_CMD_RESUME, at which point it will be freed and savedState set to NULL.
      // These variables should only be changed when processing a APP_CMD_SAVE_STATE,
      // at which point they will be initialized to NULL and you can malloc your
      // state and place the information here.  In that case the memory will be
      // freed for you later.
      savedState: pointer;
      savedStateSize: csize_t;

      // The ALooper associated with the app's thread.
      looper: PALooper;

      // When non-NULL, this is the input queue from which the app will
      // receive user input events.
      inputQueue,
      pendingInputQueue: PAInputQueue;

      // When non-NULL, this is the window surface that the app can draw in.
      window: PANativeWindow;

      // Current content rectangle of the window; this is the area where the
      // window's content should be placed to be seen by the user.
      contentRect: ARect;

      // Current state of the app's activity.  May be either APP_CMD_START,
      // APP_CMD_RESUME, APP_CMD_PAUSE, or APP_CMD_STOP; see below.
      activityState: cint;

      // This is non-zero when the application's NativeActivity is being
      // destroyed and waiting for the app thread to complete.
      destroyRequested: boolean;

      // -------------------------------------------------
      // Below are "private" implementation of the glue code.

      mutex: pthread_mutex_t;
      cond: pthread_cond_t;

      msgread,
      msgwrite: cint;

      thread: pthread_t;

      cmdPollSource,
      inputPollSource: android_poll_source;

      running,
      stateSaved,
      destroyed,
      redrawNeeded: boolean;

      pendingWindow: PANativeWindow;
      pendingContentRect: PARect;
   end;

CONST
   (**
    * Looper data ID of commands coming from the app's main thread, which
    * is returned as an identifier from ALooper_pollOnce().  The data for this
    * identifier is a pointer to an android_poll_source structure.
    * These can be retrieved and processed with android_app_read_cmd()
    * and android_app_exec_cmd().
    *)
   LOOPER_ID_MAIN = 1;
   (**
    * Looper data ID of events coming from the AInputQueue of the
    * application's window, which is returned as an identifier from
    * ALooper_pollOnce().  The data for this identifier is a pointer to an
    * android_poll_source structure.  These can be read via the inputQueue
    * object of android_app.
    *)
   LOOPER_ID_INPUT = 2;
   (**
    * Start of user-defined ALooper identifiers.
    *)
   LOOPER_ID_USER = 3;


   (**
    * Command from main thread: the AInputQueue has changed.   Upon processing
    * this command, app^.inputQueue will be updated to the new queue
    * (or NULL).
    *)
   APP_CMD_INPUT_CHANGED = 0;

   (**
    * Command from main thread: a new ANativeWindow is ready for use.   Upon
    * receiving this command, app^.window will contain the new window
    * surface.
    *)
   APP_CMD_INIT_WINDOW = 1;

   (**
    * Command from main thread: the existing ANativeWindow needs to be
    * terminated.   Upon receiving this command, app^.window still
    * contains the existing window; after calling android_app_exec_cmd
    * it will be set to NULL.
    *)
   APP_CMD_TERM_WINDOW = 2;

   (**
    * Command from main thread: the current ANativeWindow has been resized.
    * Please redraw with its new size.
    *)
   APP_CMD_WINDOW_RESIZED = 3;

   (**
    * Command from main thread: the system needs that the current ANativeWindow
    * be redrawn.   You should redraw the window before handing this to
    * android_app_exec_cmd() in order to avoid transient drawing glitches.
    *)
   APP_CMD_WINDOW_REDRAW_NEEDED = 4;

   (**
    * Command from main thread: the content area of the window has changed,
    * such as from the soft input window being shown or hidden.   You can
    * find the new content rect in android_app::contentRect.
    *)
   APP_CMD_CONTENT_RECT_CHANGED = 5;

   (**
    * Command from main thread: the app's activity window has gained
    * input focus.
    *)
   APP_CMD_GAINED_FOCUS = 6;

   (**
    * Command from main thread: the app's activity window has lost
    * input focus.
    *)
   APP_CMD_LOST_FOCUS = 7;

   (**
    * Command from main thread: the current device configuration has changed.
    *)
   APP_CMD_CONFIG_CHANGED = 8;

   (**
    * Command from main thread: the system is running low on memory.
    * Try to reduce your memory use.
    *)
   APP_CMD_LOW_MEMORY = 9;

   (**
    * Command from main thread: the app's activity has been started.
    *)
   APP_CMD_START = 10;

   (**
    * Command from main thread: the app's activity has been resumed.
    *)
   APP_CMD_RESUME = 11;

   (**
    * Command from main thread: the app should generate a new saved state
    * for itself, to restore from later if needed.   If you have saved state,
    * allocate it with malloc and place it in android_app.savedState with
    * the size in android_app.savedStateSize.   The will be freed for you
    * later.
    *)
   APP_CMD_SAVE_STATE = 12;

   (**
    * Command from main thread: the app's activity has been paused.
    *)
   APP_CMD_PAUSE = 13;

   (**
    * Command from main thread: the app's activity has been stopped.
    *)
   APP_CMD_STOP = 14;

   (**
    * Command from main thread: the app's activity is being destroyed,
    * and waiting for the app thread to clean up and exit before proceeding.
    *)
   APP_CMD_DESTROY = 15;

(**
 * This is the function that application code must implement, representing
 * the main entry to the app.
 *)
procedure android_main(app: Pandroid_app); cdecl; external;

procedure ANativeActivity_onCreate(activity: PANativeActivity; savedState: pointer; savedStateSize: csize_t); cdecl;

IMPLEMENTATION

USES
   cmem, libc_helper;

function strerror(e: cint): ansistring;
begin
   Result := sf(e);
end;

procedure free_saved_state(app: Pandroid_app);
begin
    pthread_mutex_lock(@app^.mutex);

    if app^.savedState <> nil then begin
        free(app^.savedState);
        app^.savedState := nil;
        app^.savedStateSize := 0;
    end;

    pthread_mutex_unlock(@app^.mutex);
end;

(**
 * Call when ALooper_pollAll() returns LOOPER_ID_MAIN, reading the next
 * app command message.
 *)
function android_app_read_cmd(app: Pandroid_app): cint8;
var
  cmd: cint8;

begin
   cmd := 0;

   if FpRead(app^.msgread, cmd, SizeOf(cmd)) = SizeOf(cmd) then begin
      if cmd = APP_CMD_SAVE_STATE then
         free_saved_state(app);

      exit(cmd);
   end else
      loge('No data on command pipe');

   Result := -1;
end;

procedure print_cur_config(app: Pandroid_app);
var
   lang,
   country: array[0..1] of char;

begin
   AConfiguration_getLanguage(app^.config, lang);
   AConfiguration_getCountry(app^.config, country);

   logv('Config:' +
      ' mcc=' + sf(AConfiguration_getMcc(app^.config)) +
      ' mnc=' + sf(AConfiguration_getMnc(app^.config)) +
      ' lang=' + lang[0] + lang[1] + ' ' + country[0] + country[1] +
      ' orientation=' + sf(AConfiguration_getOrientation(app^.config)) +
      ' touchscreen=' + sf(AConfiguration_getTouchscreen(app^.config)) +
      ' density=' + sf(AConfiguration_getDensity(app^.config)) +
      ' kb=' + sf(AConfiguration_getKeyboard(app^.config)) +
      ' nav=' + sf(AConfiguration_getNavigation(app^.config)) +
      ' keys_hidden=' + sf(AConfiguration_getKeysHidden(app^.config)) +
      ' nav_hidden=' + sf(AConfiguration_getNavHidden(app^.config)) +
      ' sdk_ver=' + sf(AConfiguration_getSdkVersion(app^.config)) +
      ' screen_size=' + sf(AConfiguration_getScreenSize(app^.config)) +
      ' screen_long=' + sf(AConfiguration_getScreenLong(app^.config)) +
      ' ui_mode_type=' + sf(AConfiguration_getUiModeType(app^.config)) +
      ' ui_mode_night=' + sf(AConfiguration_getUiModeNight(app^.config)));
end;

(**
 * Call with the command returned by android_app_read_cmd() to do the
 * initial pre-processing of the given command.  You can perform your own
 * actions for the command after calling this function.
 *)
procedure android_app_pre_exec_cmd(app: Pandroid_app; cmd: cint8);
begin
   case cmd of
      APP_CMD_INPUT_CHANGED: begin
         logv('APP_CMD_INPUT_CHANGED');
         pthread_mutex_lock(@app^.mutex);

         if app^.inputQueue <> nil then
             AInputQueue_detachLooper(app^.inputQueue);

         app^.inputQueue := app^.pendingInputQueue;

         if app^.inputQueue <> nil then begin
            logv('Attaching input queue to looper');
            AInputQueue_attachLooper(app^.inputQueue, app^.looper, LOOPER_ID_INPUT, nil, @app^.inputPollSource);
         end;

          pthread_cond_broadcast(@app^.cond);
          pthread_mutex_unlock(@app^.mutex);
      end;

      APP_CMD_INIT_WINDOW: begin
         logv('APP_CMD_INIT_WINDOW');
         pthread_mutex_lock(@app^.mutex);
         app^.window := app^.pendingWindow;
         pthread_cond_broadcast(@app^.cond);
         pthread_mutex_unlock(@app^.mutex);
      end;

      APP_CMD_TERM_WINDOW: begin
         logv('APP_CMD_TERM_WINDOW');
         pthread_cond_broadcast(@app^.cond);
      end;

      APP_CMD_RESUME,
      APP_CMD_START,
      APP_CMD_PAUSE,
      APP_CMD_STOP: begin
         logv('activityState=' + sf(cmd));
         pthread_mutex_lock(@app^.mutex);
         app^.activityState := cmd;
         pthread_cond_broadcast(@app^.cond);
         pthread_mutex_unlock(@app^.mutex);
      end;

      APP_CMD_CONFIG_CHANGED: begin
         logv('APP_CMD_CONFIG_CHANGED');
         AConfiguration_fromAssetManager(app^.config, app^.activity^.assetManager);
         print_cur_config(app);
      end;

      APP_CMD_DESTROY: begin
         logv('APP_CMD_DESTROY');
         app^.destroyRequested := true;
      end;
   end;
end;

(**
 * Call with the command returned by android_app_read_cmd() to do the
 * final post-processing of the given command.  You must have done your own
 * actions for the command before calling this function.
 *)
procedure android_app_post_exec_cmd(app: Pandroid_app; cmd: cint8);
begin
   case cmd of
      APP_CMD_TERM_WINDOW: begin
         logv('post APP_CMD_TERM_WINDOW');
         pthread_mutex_lock(@app^.mutex);
         app^.window := nil;
         pthread_cond_broadcast(@app^.cond);
         pthread_mutex_unlock(@app^.mutex);
      end;

      APP_CMD_SAVE_STATE: begin
         logv('post APP_CMD_SAVE_STATE');
         pthread_mutex_lock(@app^.mutex);
         app^.stateSaved := true;
         pthread_cond_broadcast(@app^.cond);
         pthread_mutex_unlock(@app^.mutex);
      end;

      APP_CMD_RESUME: begin
         free_saved_state(app);
      end;
   end;
end;

procedure android_app_destroy(app: Pandroid_app);
begin
   logv('Destroy android app!');

   free_saved_state(app);
   pthread_mutex_lock(@app^.mutex);

   if app^.inputQueue <> nil then begin
      AInputQueue_detachLooper(app^.inputQueue);
      app^.inputQueue := nil;
   end;

   AConfiguration_delete(app^.config);
   app^.config := nil;
   app^.destroyed := true;
   pthread_cond_broadcast(@app^.cond);
   pthread_mutex_unlock(@app^.mutex);

   logv('Halting app');
   halt(0);
    // Can't touch android_app object after this.
end;

procedure process_input(app: Pandroid_app; source: Pandroid_poll_source); cdecl;
var
   event: PAInputEvent;
   handled: cint32;

begin
   event := nil;

   while AInputQueue_getEvent(app^.inputQueue, @event) >= 0 do begin
      logv('New input event: type=' + sf(AInputEvent_getType(event)));

      if AInputQueue_preDispatchEvent(app^.inputQueue, event) <> 0 then
         continue;

      handled := 0;

      if app^.onInputEvent <> nil then
         handled := app^.onInputEvent(app, event);

      AInputQueue_finishEvent(app^.inputQueue, event, handled);
   end;
end;

procedure process_cmd(app: Pandroid_app; source: Pandroid_poll_source); cdecl;
var
   cmd: cint8;

begin
   cmd := android_app_read_cmd(app);
   android_app_pre_exec_cmd(app, cmd);

   if app^.onAppCmd <> nil then
      app^.onAppCmd(app, cmd);

   android_app_post_exec_cmd(app, cmd);
end;

function android_app_entry(param: pointer): pointer; cdecl;
var
   app: Pandroid_app;
   looper: PAlooper;

begin
   app := param;

   app^.config := AConfiguration_new();
   AConfiguration_fromAssetManager(app^.config, app^.activity^.assetManager);

   print_cur_config(app);

   app^.cmdPollSource.id := LOOPER_ID_MAIN;
   app^.cmdPollSource.app := app;
   app^.cmdPollSource.process := @process_cmd;
   app^.inputPollSource.id := LOOPER_ID_INPUT;
   app^.inputPollSource.app := app;
   app^.inputPollSource.process := @process_input;

   looper := ALooper_prepare(ALOOPER_PREPARE_ALLOW_NON_CALLBACKS);
   ALooper_addFd(looper, app^.msgread, LOOPER_ID_MAIN, ALOOPER_EVENT_INPUT, nil, @app^.cmdPollSource);
   app^.looper := looper;

   pthread_mutex_lock(@app^.mutex);
   app^.running := true;
   pthread_cond_broadcast(@app^.cond);
   pthread_mutex_unlock(@app^.mutex);

   android_main(app);

   android_app_destroy(app);
   Result := nil;
end;

// --------------------------------------------------------------------
// Native activity interaction (called from main thread)
// --------------------------------------------------------------------

function android_app_create(activity: PANativeActivity; savedState: pointer; savedStateSize: csize_t): Pandroid_app;
var
   app: Pandroid_app;
   msgpipe: array[0..1] of cint;
   attr: pthread_attr_t;

begin
   app := GetMem(SizeOf(android_app));
   ZeroOut(app^, SizeOf(android_app));
   app^.activity := activity;

   pthread_mutex_init(@app^.mutex, nil);
   pthread_cond_init(@app^.cond, nil);

   if savedState <> nil then begin
      app^.savedState := GetMem(savedStateSize);
      app^.savedStateSize := savedStateSize;
      move(app^.savedState^, savedState^, savedStateSize);
   end;

   msgpipe[0] := 0;
   msgpipe[1] := 0;

   if FpPipe(msgpipe) > 0 then begin
      loge('could not create pipe: ' + strerror(errno));
      exit(nil);
   end;

   app^.msgread := msgpipe[0];
   app^.msgwrite := msgpipe[1];

   pthread_attr_init(@attr);
   pthread_attr_setdetachstate(@attr, PTHREAD_CREATE_DETACHED);
   pthread_create(@app^.thread, @attr, @android_app_entry, app);

   // Wait for thread to start.
   pthread_mutex_lock(@app^.mutex);

   while (not app^.running) do begin
      pthread_cond_wait(@app^.cond, @app^.mutex);
   end;

   pthread_mutex_unlock(@app^.mutex);

   Result := app;
end;

procedure android_app_write_cmd(app: Pandroid_app; cmd: cint8);
begin
   if FpWrite(app^.msgwrite, cmd, SizeOf(cmd)) <> SizeOf(cmd) then
      loge('Failure writing android_app cmd: ' + strerror(errno));
end;

procedure android_app_set_input(app: Pandroid_app; inputQueue: PAInputQueue);
begin
   pthread_mutex_lock(@app^.mutex);
   app^.pendingInputQueue := inputQueue;
   android_app_write_cmd(app, APP_CMD_INPUT_CHANGED);

   while (app^.inputQueue <> app^.pendingInputQueue) do begin
      pthread_cond_wait(@app^.cond, @app^.mutex);
   end;

   pthread_mutex_unlock(@app^.mutex);
end;

procedure android_app_set_window(app: Pandroid_app; window: PANativeWindow);
begin
   pthread_mutex_lock(@app^.mutex);

   if app^.pendingWindow <> nil then
      android_app_write_cmd(app, APP_CMD_TERM_WINDOW);

   app^.pendingWindow := window;

   if window <> nil then
      android_app_write_cmd(app, APP_CMD_INIT_WINDOW);

   while (app^.window <> app^.pendingWindow) do begin
      pthread_cond_wait(@app^.cond, @app^.mutex);
   end;

   pthread_mutex_unlock(@app^.mutex);
end;

procedure android_app_set_activity_state(app: Pandroid_app; cmd: cint8);
begin
   pthread_mutex_lock(@app^.mutex);
   android_app_write_cmd(app, cmd);

   while (app^.activityState <> cmd) do begin
      pthread_cond_wait(@app^.cond, @app^.mutex);
   end;

   pthread_mutex_unlock(@app^.mutex);
end;

procedure android_app_free(app: Pandroid_app);
begin
   pthread_mutex_lock(@app^.mutex);
   android_app_write_cmd(app, APP_CMD_DESTROY);

   while (not app^.destroyed) do begin
      pthread_cond_wait(@app^.cond, @app^.mutex);
   end;

   pthread_mutex_unlock(@app^.mutex);

   FpClose(app^.msgread);
   FpClose(app^.msgwrite);
   pthread_cond_destroy(@app^.cond);
   pthread_mutex_destroy(@app^.mutex);
   free(app);
end;

procedure onDestroy(activity: PANativeActivity); cdecl;
begin
    logv('Destroy: ' + sf(activity));
    android_app_free(activity^.instance);
end;

procedure onStart(activity: PANativeActivity); cdecl;
begin
    logv('Start: ' + sf(activity));
    android_app_set_activity_state(activity^.instance, APP_CMD_START);
end;

procedure onResume(activity: PANativeActivity); cdecl;
begin
    logv('Resume: ' + sf(activity));
    android_app_set_activity_state(activity^.instance, APP_CMD_RESUME);
end;

function onSaveInstanceState(activity: PANativeActivity; outLen: Pcsize_t): pointer; cdecl;
var
   app: Pandroid_app;
   savedState: pointer;

begin
   app := activity^.instance;
   savedState := nil;

   outLen^ := 0;

   logv('SaveInstanceState: ' + sf(activity));
   pthread_mutex_lock(@app^.mutex);
   app^.stateSaved := false;
   android_app_write_cmd(app, APP_CMD_SAVE_STATE);

   while (not app^.stateSaved) do begin
      pthread_cond_wait(@app^.cond, @app^.mutex);
   end;

   if app^.savedState <> nil then begin
      savedState := app^.savedState;
      outLen^ := app^.savedStateSize;
      app^.savedState := nil;
      app^.savedStateSize := 0;
   end;

   pthread_mutex_unlock(@app^.mutex);

   Result := savedState;
end;

procedure onPause(activity: PANativeActivity); cdecl;
begin
   logv('Pause: ' + sf(activity));
   android_app_set_activity_state(activity^.instance, APP_CMD_PAUSE);
end;

procedure onStop(activity: PANativeActivity); cdecl;
begin
   logv('Stop: ' + sf(activity));
   android_app_set_activity_state(activity^.instance, APP_CMD_STOP);
end;

procedure onConfigurationChanged(activity: PANativeActivity); cdecl;
begin
   logv('ConfigurationChanged: ' + sf(activity^.instance));
   android_app_write_cmd(activity^.instance, APP_CMD_CONFIG_CHANGED);
end;

procedure onLowMemory(activity: PANativeActivity); cdecl;
begin
   logv('LowMemory: ' + sf(activity^.instance));
   android_app_write_cmd(activity^.instance, APP_CMD_LOW_MEMORY);
end;

procedure onWindowFocusChanged(activity: PANativeActivity; focused: cint); cdecl;
begin
   logv('WindowFocusChanged: ' + sf(activity) + ' -- ' + sf(focused));

   if focused <> 0 then
      android_app_write_cmd(activity^.instance, APP_CMD_GAINED_FOCUS)
   else
      android_app_write_cmd(activity^.instance, APP_CMD_LOST_FOCUS);
end;

procedure onNativeWindowCreated(activity: PANativeActivity; window: PANativeWindow); cdecl;
begin
   logv('NativeWindowCreated: ' + sf(activity) + ' -- ' + sf(window));
   android_app_set_window(activity^.instance, window);
end;

procedure onNativeWindowDestroyed(activity: PANativeActivity; window: PANativeWindow); cdecl;
begin
   logv('NativeWindowDestroyed ' + sf(activity) + ' -- ' + sf(window));
   android_app_set_window(activity^.instance, nil);
end;

procedure onInputQueueCreated(activity: PANativeActivity; queue: PAInputQueue); cdecl;
begin
   logv('InputQueueCreated: ' + sf(activity) + ' -- ' + sf(queue));
   android_app_set_input(activity^.instance, queue);
end;

procedure onInputQueueDestroyed(activity: PANativeActivity; queue: PAInputQueue); cdecl;
begin
   logv('InputQueueDestroyed: ' + sf(activity) + ' -- ' + sf(queue));
   android_app_set_input(activity^.instance, nil);
end;

procedure ANativeActivity_onCreate(activity: PANativeActivity; savedState: pointer; savedStateSize: csize_t); cdecl;
begin
   logv('Creating: ' + sf(activity));

   activity^.callbacks^.onDestroy := @onDestroy;
   activity^.callbacks^.onStart := @onStart;
   activity^.callbacks^.onResume := @onResume;
   activity^.callbacks^.onSaveInstanceState := @onSaveInstanceState;
   activity^.callbacks^.onPause := @onPause;
   activity^.callbacks^.onStop := @onStop;
   activity^.callbacks^.onConfigurationChanged := @onConfigurationChanged;
   activity^.callbacks^.onLowMemory := @onLowMemory;
   activity^.callbacks^.onWindowFocusChanged := @onWindowFocusChanged;
   activity^.callbacks^.onNativeWindowCreated := @onNativeWindowCreated;
   activity^.callbacks^.onNativeWindowDestroyed := @onNativeWindowDestroyed;
   activity^.callbacks^.onInputQueueCreated := @onInputQueueCreated;
   activity^.callbacks^.onInputQueueDestroyed := @onInputQueueDestroyed;

   activity^.instance := android_app_create(activity, savedState, savedStateSize);
end;

END.
