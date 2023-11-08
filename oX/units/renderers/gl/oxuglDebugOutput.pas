{
   oxuglDebugOutput, handle ARB_debug_output
   Copyright (C) 2017. Dejan Boras

   https://www.khronos.org/registry/OpenGL/extensions/ARB/ARB_debug_output.txt
}

{$INCLUDE oxheader.inc}
UNIT oxuglDebugOutput;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uLog, StringUtils,
      {ox}
      uOX, {$IFNDEF OX_LIBRARY}oxuRunRoutines,{$ENDIF}
      {gl}
      oxuglRenderer, oxuOGL, oxuglExtensions;

IMPLEMENTATION

Threadvar
   lastOutput: string;

procedure debugOutput(source, typ: GLenum; id: GLuint; severity: GLuint; {%H-}length: GLsizei; const message: PGLchar;
   {%H-}userParam: PGLvoid);  {$IFDEF WINDOWS}stdcall; {$ELSE}cdecl; {$ENDIF}
var
   sourceString,
   typeString,
   severityString,
   logString: string;

begin
   sourceString := 'other';

   if(source = GL_DEBUG_SOURCE_API) then
      sourceString := 'api'
   else if(source = GL_DEBUG_SOURCE_WINDOW_SYSTEM) then
      sourceString := 'window system'
   else if(source = GL_DEBUG_SOURCE_SHADER_COMPILER) then
      sourceString := 'shader compiler'
   else if(source = GL_DEBUG_SOURCE_THIRD_PARTY) then
      sourceString := 'third party'
   else if(source = GL_DEBUG_SOURCE_APPLICATION) then
      sourceString := 'application';

   typeString := 'other';

   if(typ = GL_DEBUG_TYPE_ERROR) then
      typeString := 'error'
   else if(typ = GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR) then
      typeString := 'deprecated behavior'
   else if(typ = GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR) then
      typeString := 'undefined behavior'
   else if(typ = GL_DEBUG_TYPE_PORTABILITY) then
      typeString := 'portability'
   else if(typ = GL_DEBUG_TYPE_PERFORMANCE) then
      typeString := 'performance';

   severityString := 'low';

   if(severity = GL_DEBUG_SEVERITY_MEDIUM) then
      severityString := 'medium'
   else if(severity = GL_DEBUG_SEVERITY_HIGH) then
      severityString := 'high';

   logString := 'gl(' + sf(id) + ', ' + severityString + ', ' + sourceString + ', ' + typeString + ') > ' + message;

   if(logString = lastOutput) then
      exit;

   lastOutput := logString;

   if(severity = GL_DEBUG_SEVERITY_LOW) then
      log.v(logString)
   else if(severity = GL_DEBUG_SEVERITY_MEDIUM) then
      log.w(logString)
   else if(severity = GL_DEBUG_SEVERITY_HIGH) then
      log.e(logString);
end;

VAR
   initRoutine: oxTRunRoutine;

procedure initDebug();
begin
   if oglExtensions.Supported(cGL_ARB_debug_output) then begin
      log.i('gl > Using debug output');
      glDebugMessageCallback(@debugOutput, nil);

      if(ogl.eRaise() <> 0) then
         log.e('gl > Failed to set debug output callback');
   end;
end;

procedure init();
begin
   oxglRenderer.AfterInit.Add(initRoutine, 'gl_debug_output', @initDebug);
end;

INITIALIZATION
   {$IFNDEF OX_LIBRARY}
   ox.PreInit.Add('gl.debug_output', @init);
   {$ENDIF}

END.
