{
   oxuglRenderTypes, rendering types
   Copyright (C) 2019. Dejan Boras

   Started On:    10.06.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuglRenderTypes;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      oxuOGL, oxuTypes;

CONST
   oglPrimitiveTranslate: array[0..8] of GLenum = (
      {0} oglNONE,
      {1} GL_POINTS,
      {2} GL_LINES,
      {3} GL_LINE_LOOP,
      {4} GL_LINE_STRIP,
      {5} GL_TRIANGLES,
      {6} GL_TRIANGLE_STRIP,
      {7} GL_TRIANGLE_FAN,
      {8} {$IFNDEF GLES}GL_QUADS{$ELSE}GL_ZERO{$ENDIF}
   );

TYPE
   {$IFNDEF GLES}
   oglTBLendRemap = array[0..2] of GLEnum;
   {$ELSE}
   oglTBLendRemap = array[0..1] of GLEnum;
   {$ENDIF}

CONST
   {$IFNDEF GLES}
   oglBlendRemaps: array[0..longint(oxBLEND_MAX)] of oglTBlendRemap = (
      {blend function, left side, right side}
      (GL_FUNC_ADD, GL_ONE, GL_ONE), {none}
      (GL_FUNC_ADD, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA), {alpha}
      (GL_FUNC_ADD, GL_ONE, GL_ONE), {add}
      (GL_FUNC_SUBTRACT, GL_ONE, GL_ONE), {subtract}
      (GL_FUNC_ADD, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)  {filter}
   );
   {$ELSE}
   oglBlendRemaps: array[0..longint(oxBLEND_MAX)] of TBlendRemap = (
      {blend function, left side, right side}
      (GL_ONE, GL_ONE), {none}
      (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA), {alpha}
      (GL_ONE, GL_ONE), {add}
      (GL_ONE, GL_ONE), {subtract}
      (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)  {filter}
   );
   {$ENDIF}

   oglFunctionRemaps: array[0..longint(oxTEST_FUNCTION_ALWAYS)] of GLenum = (
      oglNONE, {oxDEPTH_TEST_NONE}
      GL_NEVER, {oxDEPTH_TEST_NEVER}
      GL_EQUAL, {oxDEPTH_TEST_EQUAL}
      GL_GREATER, {oxDEPTH_TEST_GREATER}
      GL_GEQUAL, {oxDEPTH_TEST_GEQUAL}
      GL_LEQUAL, {oxDEPTH_TEST_LEQUAL}
      GL_LESS, {oxDEPTH_TEST_LESS}
      GL_ALWAYS {oxDEPTH_TEST_ALWAYS}
   );

IMPLEMENTATION

END.
