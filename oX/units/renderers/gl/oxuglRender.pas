{
   oxuRender, rendering
   Copyright (C) 2011. Dejan Boras

   Started On:    21.02.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxuglRender;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uColors, vmVector,
      {oX}
      uOX, oxuRenderer, oxuRender, oxuTypes, oxuRunRoutines,
      {ogl}
      oxuglRenderer, oxuOGL;

TYPE

   { oglTRender }

   oglTRender = class(oxTRender)
      procedure BlendFunction(blendFunc: oxTBlendFunction); override;

      procedure DepthTest(test: oxTTestFunction); override;
      procedure DepthWrite(on: boolean); override;

      procedure AlphaTest(test: oxTTestFunction; alpha: single); override;

      procedure CullFace(cull: oxTCullFace); override;

      { SETUP }
      procedure PointSize(size: single); override;
      procedure LineWidth(pixels: single); override;

      { RENDERING }
      procedure Vertex(var v: TVector2f); override;
      procedure Vertex(var v: TVector3f); override;

      procedure Color(var v: TColor3f); override;
      procedure Color(var v: TColor4f); override;
      procedure Color(var v: TColor3ub); override;
      procedure Color(var v: TColor4ub); override;
      procedure DisableColor(); override;

      procedure Normals(var v: array of TVector3f); override;
      procedure DisableNormals(); override;

      procedure TextureCoords(var v: TVector2f); override;

      procedure Lines(var v: array of TVector2f); override;
      procedure Lines(var v: array of TVector3f); override;

      procedure LineLoop(var v: array of TVector2f); override;
      procedure LineLoop(var v: array of TVector3f); override;

      procedure LineStrip(var v: array of TVector2f); override;
      procedure LineStrip(var v: array of TVector3f); override;

      procedure Points(var v: array of TVector2f); override;
      procedure Points(var v: array of TVector3f); override;

      procedure Primitives(primitive: oxTPrimitives; count: longint; indices: PWord); override;
      procedure Primitives(primitive: oxTPrimitives; count: longint; indices: PLongWord); override;
      procedure DrawArrays(primitive: oxTPrimitives; count: longint); override;

      procedure CheckError; override;

      {SCISSOR}
      {set the scissor test boundaries}
      procedure Scissor(x, y, w, h: longint); override;
      procedure DisableScissor(); override;
   end;

IMPLEMENTATION

VAR
   oglRender: oglTRender;

   primitive_translate: array[0..8] of GLenum = (
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
   TBLendRemap = array[0..2] of GLEnum;
   {$ELSE}
   TBLendRemap = array[0..1] of GLEnum;
   {$ENDIF}

CONST
   {$IFNDEF GLES}
   blendRemaps: array[0..longint(oxBLEND_MAX)] of TBlendRemap = (
      {blend function, left side, right side}
      (GL_FUNC_ADD, GL_ONE, GL_ONE), {none}
      (GL_FUNC_ADD, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA), {alpha}
      (GL_FUNC_ADD, GL_ONE, GL_ONE), {add}
      (GL_FUNC_SUBTRACT, GL_ONE, GL_ONE), {subtract}
      (GL_FUNC_ADD, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)  {filter}
   );
   {$ELSE}
   blendRemaps: array[0..longint(oxBLEND_MAX)] of TBlendRemap = (
      {blend function, left side, right side}
      (GL_ONE, GL_ONE), {none}
      (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA), {alpha}
      (GL_ONE, GL_ONE), {add}
      (GL_ONE, GL_ONE), {subtract}
      (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)  {filter}
   );
   {$ENDIF}

   functionRemap: array[0..longint(oxTEST_FUNCTION_ALWAYS)] of GLenum = (
      oglNONE, {oxDEPTH_TEST_NONE}
      GL_NEVER, {oxDEPTH_TEST_NEVER}
      GL_EQUAL, {oxDEPTH_TEST_EQUAL}
      GL_GREATER, {oxDEPTH_TEST_GREATER}
      GL_GEQUAL, {oxDEPTH_TEST_GEQUAL}
      GL_LEQUAL, {oxDEPTH_TEST_LEQUAL}
      GL_LESS, {oxDEPTH_TEST_LESS}
      GL_ALWAYS {oxDEPTH_TEST_ALWAYS}
   );

procedure oglTRender.BlendFunction(blendFunc: oxTBlendFunction);
begin
   if(blendFunc <> oxBLEND_NONE) then begin
      glEnable(GL_BLEND);
      {$IFNDEF GLES}
      glBlendFunc(blendRemaps[longint(blendFunc)][1], blendRemaps[longint(blendFunc)][2]);
      glBlendEquation(blendRemaps[longint(blendFunc)][0]);
      {$ELSE}
      glBlendFunc(blendRemaps[longint(blendFunc)][0], blendRemaps[longint(blendFunc)][1]);
      {$ENDIF}
   end else
      glDisable(GL_BLEND);
end;

procedure oglTRender.DepthTest(test: oxTTestFunction);
begin
   if(test <> oxTEST_FUNCTION_NONE) then begin
      glEnable(GL_DEPTH_TEST);

      glDepthFunc(functionRemap[longint(test)]);
   end else
      glDisable(GL_DEPTH_TEST);
end;

procedure oglTRender.DepthWrite(on: boolean);
begin
   if(on) then
      glDepthMask(GL_TRUE)
   else
      glDepthMask(GL_FALSE);
end;

procedure oglTRender.AlphaTest(test: oxTTestFunction; alpha: single);
begin
   if(test <> oxTEST_FUNCTION_NONE) then begin
      glEnable(GL_ALPHA_TEST);

      glAlphaFunc(functionRemap[longint(test)], alpha);
   end else
      glDisable(GL_ALPHA_TEST);
end;


procedure oglTRender.CullFace(cull: oxTCullFace);
begin
   if(cull = oxCULL_FACE_NONE) then
      glDisable(GL_CULL_FACE)
   else begin
      glEnable(GL_CULL_FACE);

      if(cull = oxCULL_FACE_BACK) then
         glCullFace(GL_BACK)
      else
         glCullFace(GL_FRONT);
   end;

end;

procedure oglTRender.PointSize(size: single);
begin
   glPointSize(size);
end;

procedure oglTRender.LineWidth(pixels: single);
begin
   glLineWidth(pixels);
end;

procedure oglTRender.Vertex(var v: TVector2f);
begin
   glVertexPointer(2, GL_FLOAT, 0, @v);
   {$IFDEF DEBUG}LastUsedVertex := @v;{$ENDIF}
end;

procedure oglTRender.Vertex(var v: TVector3f);
begin
   glVertexPointer(3, GL_FLOAT, 0, @v);
   {$IFDEF DEBUG}LastUsedVertex := @v;{$ENDIF}
end;

procedure oglTRender.Color(var v: TColor3f);
begin
   glEnableClientState(GL_COLOR_ARRAY);
   glColorPointer(3, GL_FLOAT, 0, @v);
   {$IFDEF DEBUG}LastUsedColor := @v;{$ENDIF}
end;

procedure oglTRender.Color(var v: TColor4f);
begin
   glEnableClientState(GL_COLOR_ARRAY);
   glColorPointer(4, GL_FLOAT, 0, @v);
   {$IFDEF DEBUG}LastUsedColor := @v;{$ENDIF}
end;

procedure oglTRender.Color(var v: TColor3ub);
begin
   glEnableClientState(GL_COLOR_ARRAY);
   glColorPointer(3, GL_BYTE, 0, @v);
   {$IFDEF DEBUG}LastUsedColor := @v;{$ENDIF}
end;

procedure oglTRender.Color(var v: TColor4ub);
begin
   glEnableClientState(GL_COLOR_ARRAY);
   glColorPointer(4, GL_BYTE, 0, @v);
   {$IFDEF DEBUG}LastUsedColor := @v;{$ENDIF}
end;

procedure oglTRender.DisableColor;
begin
   glDisableClientState(GL_COLOR_ARRAY);
end;

procedure oglTRender.Normals(var v: array of TVector3f);
begin
   glEnableClientState(GL_NORMAL_ARRAY);
   glNormalPointer(GL_FLOAT, 0, @v);
   {$IFDEF DEBUG}LastUsedNormals := @v;{$ENDIF}
end;

procedure oglTRender.DisableNormals;
begin
   glDisableClientState(GL_NORMAL_ARRAY);
end;

procedure oglTRender.TextureCoords(var v: TVector2f);
begin
   glEnableClientState(GL_TEXTURE_COORD_ARRAY);
   glTexCoordPointer(2, GL_FLOAT, 0, @v);

   {$IFDEF DEBUG}LastUsedTextureCoords := @v;{$ENDIF}
end;

procedure oglTRender.Lines(var v: array of TVector2f);
begin
   glVertexPointer(2, GL_FLOAT, 0, @v);
   glDrawArrays(GL_LINES, 0, Length(v));
   {$IFDEF DEBUG}LastUsedVertex := @v;{$ENDIF}
end;

procedure oglTRender.Lines(var v: array of TVector3f);
begin
   glVertexPointer(3, GL_FLOAT, 0, @v);
   glDrawArrays(GL_LINES, 0, Length(v));
   {$IFDEF DEBUG}LastUsedVertex := @v;{$ENDIF}
end;

procedure oglTRender.LineLoop(var v: array of TVector2f);
begin
   glVertexPointer(2, GL_FLOAT, 0, @v);
   glDrawArrays(GL_LINE_LOOP, 0, Length(v));
   {$IFDEF DEBUG}LastUsedVertex := @v;{$ENDIF}
end;

procedure oglTRender.LineLoop(var v: array of TVector3f);
begin
   glVertexPointer(3, GL_FLOAT, 0, @v);
   glDrawArrays(GL_LINE_LOOP, 0, Length(v));
   {$IFDEF DEBUG}LastUsedVertex := @v;{$ENDIF}
end;

procedure oglTRender.LineStrip(var v: array of TVector2f);
begin
   glVertexPointer(2, GL_FLOAT, 0, @v);
   glDrawArrays(GL_LINE_STRIP, 0, Length(v));
   {$IFDEF DEBUG}LastUsedVertex := @v;{$ENDIF}
end;

procedure oglTRender.LineStrip(var v: array of TVector3f);
begin
   glVertexPointer(3, GL_FLOAT, 0, @v);
   glDrawArrays(GL_LINE_STRIP, 0, Length(v));
   {$IFDEF DEBUG}LastUsedVertex := @v;{$ENDIF}
end;

procedure oglTRender.Points(var v: array of TVector2f);
begin
   glVertexPointer(2, GL_FLOAT, 0, @v);
   glDrawArrays(GL_POINTS, 0, Length(v));
   {$IFDEF DEBUG}LastUsedVertex := @v;{$ENDIF}
end;

procedure oglTRender.Points(var v: array of TVector3f);
begin
   glVertexPointer(3, GL_FLOAT, 0, @v);
   glDrawArrays(GL_POINTS, 0, Length(v));
   {$IFDEF DEBUG}LastUsedVertex := @v;{$ENDIF}
end;

procedure oglTRender.Primitives(primitive: oxTPrimitives; count: longint; indices: PWord);
begin
   if(primitive <> oxPRIMITIVE_NONE) then
      {$IFNDEF GLES}
      glDrawElements(primitive_translate[GLenum(primitive)], count, GL_UNSIGNED_SHORT, indices);
      {$ELSE}
      glDrawElements(primitive_translate[GLenum(primitive)], count, GL_UNSIGNED_SHORT, PGLvoid(indices));
      {$ENDIF}

   {$IFDEF DEBUG}LastUsedIndices := indices;{$ENDIF}
end;

procedure oglTRender.Primitives(primitive: oxTPrimitives; count: longint; indices: PLongWord);
begin
   if(primitive <> oxPRIMITIVE_NONE) then
      {$IFNDEF GLES}
      glDrawElements(primitive_translate[GLenum(primitive)], count, GL_UNSIGNED_SHORT, indices);
      {$ELSE}
      glDrawElements(primitive_translate[GLenum(primitive)], count, GL_UNSIGNED_SHORT, PGLvoid(indices));
      {$ENDIF}

   {$IFDEF DEBUG}LastUsedIndices := indices;{$ENDIF}
end;


procedure oglTRender.DrawArrays(primitive: oxTPrimitives; count: longint);
begin
   if(primitive <> oxPRIMITIVE_NONE) then
      glDrawArrays(primitive_translate[GLenum(primitive)], 0, count);
end;

procedure oglTRender.CheckError;
begin
   ogl.eRaise();
end;

{SCISSOR}
procedure oglTRender.Scissor(x, y, w, h: longint);
begin
   glEnable(GL_SCISSOR_TEST);
   glScissor(x, y - h + 1, w, h);
end;

procedure oglTRender.DisableScissor();
begin
   glDisable(GL_SCISSOR_TEST);
end;

function componentReturn(): TObject;
begin
   result := oglRender;
end;

procedure init();
begin
   oglRender := oglTRender.Create();

   oxglRenderer.components.RegisterComponent('render', @componentReturn);
end;

procedure deinit();
begin
   oglRender.Free();
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.PreInit.Add(initRoutines, 'ox.gl.render', @init, @deinit);

END.
