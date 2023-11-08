{
   NAGLAndroidMain
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT NAGLAndroidMain;

INTERFACE

   USES
      looper, android_native_app_glue, baseunix,
      egl, gles,
      android_log_helper, uStd;

procedure android_main(app: Pandroid_app); cdecl;

IMPLEMENTATION

TYPE
   PEngine = ^TEngine;
   TEngine = record
      app: Pandroid_app;

      animating: boolean;
      display: EGLDisplay;
      surface: EGLSurface;
      context: EGLContext;

      width,
      height: int32;

      state: record
         x,
         y,
         angle: single;
      end;
   end;

function engine_init_display(engine: PEngine): boolean;
var
   attribs: array[0..8] of EGLint = (
      EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
      EGL_BLUE_SIZE, 8,
      EGL_GREEN_SIZE, 8,
      EGL_RED_SIZE, 8,
      EGL_NONE
   );

   i: longint;
   w, h, format: EGLint;
   numConfigs: EGLint;
   cfg,
   config: EGLConfig;
   surface: EGLSurface;
   context: EGLContext;
   display: EGLDisplay;
   supportedConfigs: array of EGLConfig;

   r, g, b, d: EGLint;

begin
   Result := false;

   display := eglGetDisplay(EGL_DEFAULT_DISPLAY);
   eglInitialize(display, nil, nil);

   supportedConfigs := nil;

   eglChooseConfig(display, attribs, nil, 0, @numConfigs);
   SetLength(supportedConfigs, numConfigs);
   eglChooseConfig(display, attribs, @supportedConfigs[0], numConfigs, @numConfigs);

   config := nil;

   for i := 0 to numConfigs do begin
       if(i = numConfigs) then
           break;

       cfg := supportedConfigs[i];

       if ((eglGetConfigAttrib(display, cfg, EGL_RED_SIZE, @r) <> 0) and
           (eglGetConfigAttrib(display, cfg, EGL_GREEN_SIZE, @g) <> 0) and
           (eglGetConfigAttrib(display, cfg, EGL_BLUE_SIZE,  @b) <> 0) and
           (eglGetConfigAttrib(display, cfg, EGL_DEPTH_SIZE, @d) <> 0) and
           (r = 8) and (g = 8) and (b = 8) and (d = 0) )  then begin
               config := supportedConfigs[i];
               break;
       end;
   end;

   if i = numConfigs then
      config := supportedConfigs[0];

   if (config = nil) then begin
       logw('Unable to initialize EGLConfig');
       exit(false);
   end;

   eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, @format);
   surface := eglCreateWindowSurface(display, config, engine^.app^.window, nil);
   context := eglCreateContext(display, config, nil, nil);

   if (eglMakeCurrent(display, surface, surface, context) = EGL_FALSE) then begin
       logw('Unable to eglMakeCurrent');
       exit(false);
   end;

   eglQuerySurface(display, surface, EGL_WIDTH, @w);
   eglQuerySurface(display, surface, EGL_HEIGHT, @h);

   engine^.display := display;
   engine^.context := context;
   engine^.surface := surface;
   engine^.width  := w;
   engine^.height := h;

   // Check openGL on the system
   logi('VENDOR: ' + pChar(glGetString(GL_VENDOR)));
   logi('RENDERER: ' + pChar(glGetString(GL_RENDERER)));
   logi('VERSION: ' + pChar(glGetString(GL_VERSION)));
   logi('EXTENSIONS: ' + pChar(glGetString(GL_EXTENSIONS)));

   // Initialize GL state.
   glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
   glEnable(GL_CULL_FACE);
   glShadeModel(GL_SMOOTH);
   glDisable(GL_DEPTH_TEST);

   Result := true;
end;

{ Just the current frame in the display. }
procedure engine_draw_frame(engine: PEngine);
begin
    if engine^.display = nil then
       exit;

    // Just fill the screen with a color.
    glClearColor(engine^.state.x / engine^.width, engine^.state.angle,
                 engine^.state.y / engine^.height, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    eglSwapBuffers(engine^.display, engine^.surface);
end;

{ Tear down the EGL context currently associated with the display. }
procedure engine_term_display(engine: PEngine);
begin
    if engine^.display <> EGL_NO_DISPLAY then begin
        eglMakeCurrent(engine^.display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);

         if engine^.context <> EGL_NO_CONTEXT then
            eglDestroyContext(engine^.display, engine^.context);

        if engine^.surface <> EGL_NO_SURFACE then
            eglDestroySurface(engine^.display, engine^.surface);

        eglTerminate(engine^.display);
    end;

    engine^.animating := false;
    engine^.display := EGL_NO_DISPLAY;
    engine^.context := EGL_NO_CONTEXT;
    engine^.surface := EGL_NO_SURFACE;
end;

procedure engine_handle_cmd(app: Pandroid_app; cmd: cint32);
var
   engine: PEngine;

begin
    engine := app^.userData;

    case cmd of
      APP_CMD_INIT_WINDOW: begin
         if (engine^.app^.window <> nil) then begin
            if(engine_init_display(engine)) then
                engine^.animating := true;
         end;
      end;
      APP_CMD_TERM_WINDOW: begin
         engine_term_display(engine);
      end;
      APP_CMD_LOST_FOCUS: begin
         engine^.animating := false;
      end;
   end;
end;

procedure run(var engine: TEngine);
begin
   if engine.animating then begin
      engine.state.angle := engine.state.angle + 0.01;

      if engine.state.angle > 1 then
         engine.state.angle := 0;

      engine_draw_frame(@engine);
   end;
end;

procedure android_main(app: Pandroid_app); cdecl;
var
   ident,
   nEvents: cint;
   pSource: Pandroid_poll_source;

   engine: TEngine;

begin
   ZeroOut(engine, SizeOf(engine));
   app^.userData := @engine;

   app^.onAppCmd := @engine_handle_cmd;
   engine.app := app;

   nEvents := 0;
   pSource := nil;

   repeat
      ident := ALooper_pollAll(0, nil, @nEvents, @pSource);

      if ident >= 0 then begin
         if pSource <> nil then
            pSource^.process(app, pSource);
      end;

      if app^.destroyRequested then begin
         engine_term_display(@engine);
         exit;
      end;

      run(engine);
   until false;
end;

END.
