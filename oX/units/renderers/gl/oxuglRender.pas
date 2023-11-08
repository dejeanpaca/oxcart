{
   oxuRender, rendering
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglRender;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uStd, uLog, uColors, vmVector,
      {$IFNDEF GLES}
      StringUtils,
      {$ENDIF}
      {oX}
      uOX, oxuRenderer, oxuRender, oxuTypes, oxuRunRoutines, oxuWindow,
      {ogl}
      oxuglRenderer, oxuOGL, oxuglExtensions, oxuglRenderTypes;

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
      procedure DisableTextureCoords(); override;

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

procedure oglTRender.BlendFunction(blendFunc: oxTBlendFunction);
begin
   if(blendFunc <> oxBLEND_NONE) then begin
      glEnable(GL_BLEND);
      {$IFNDEF GLES}
      glBlendFunc(oglBlendRemaps[longint(blendFunc)][1], oglBlendRemaps[longint(blendFunc)][2]);
      glBlendEquation(oglBlendRemaps[longint(blendFunc)][0]);
      {$ELSE}
      glBlendFunc(oglBlendRemaps[longint(blendFunc)][0], oglBlendRemaps[longint(blendFunc)][1]);
      {$ENDIF}
   end else
      glDisable(GL_BLEND);
end;

procedure oglTRender.DepthTest(test: oxTTestFunction);
begin
   if(test <> oxTEST_FUNCTION_NONE) then begin
      glEnable(GL_DEPTH_TEST);

      glDepthFunc(oglFunctionRemaps[longint(test)]);
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

      glAlphaFunc(oglFunctionRemaps[longint(test)], alpha);
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

procedure oglTRender.DisableColor();
begin
   glDisableClientState(GL_COLOR_ARRAY);
end;

procedure oglTRender.Normals(var v: array of TVector3f);
begin
   glEnableClientState(GL_NORMAL_ARRAY);
   glNormalPointer(GL_FLOAT, 0, @v);
   {$IFDEF DEBUG}LastUsedNormals := @v;{$ENDIF}
end;

procedure oglTRender.DisableNormals();
begin
   glDisableClientState(GL_NORMAL_ARRAY);
end;

procedure oglTRender.TextureCoords(var v: TVector2f);
begin
   glEnableClientState(GL_TEXTURE_COORD_ARRAY);
   glTexCoordPointer(2, GL_FLOAT, 0, @v);

   {$IFDEF DEBUG}LastUsedTextureCoords := @v;{$ENDIF}
end;

procedure oglTRender.DisableTextureCoords();
begin
   glDisableClientState(GL_TEXTURE_COORD_ARRAY);
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
      glDrawElements(oglPrimitiveTranslate[GLenum(primitive)], count, GL_UNSIGNED_SHORT, indices);
      {$ELSE}
      glDrawElements(oglPrimitiveTranslate[GLenum(primitive)], count, GL_UNSIGNED_SHORT, PGLvoid(indices));
      {$ENDIF}

   {$IFDEF DEBUG}LastUsedIndices := indices;{$ENDIF}
end;

procedure oglTRender.Primitives(primitive: oxTPrimitives; count: longint; indices: PLongWord);
begin
   if(primitive <> oxPRIMITIVE_NONE) then
      {$IFNDEF GLES}
      glDrawElements(oglPrimitiveTranslate[GLenum(primitive)], count, GL_UNSIGNED_INT, indices);
      {$ELSE}
      glDrawElements(oglPrimitiveTranslate[GLenum(primitive)], count, GL_UNSIGNED_SHORT, PGLvoid(indices));
      {$ENDIF}

   {$IFDEF DEBUG}LastUsedIndices := indices;{$ENDIF}
end;


procedure oglTRender.DrawArrays(primitive: oxTPrimitives; count: longint);
begin
   if(primitive <> oxPRIMITIVE_NONE) then
      glDrawArrays(oglPrimitiveTranslate[GLenum(primitive)], 0, count);
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
   Result := oglRender;
end;

VAR
   glInitRoutines: oxTRunRoutine;

procedure renderInit();
{$IFNDEF GLES}
var
   i: loopint;
{$ENDIF}

begin
   {$IFNDEF GLES}
   if(not oglExtensions.Supported(cGL_EXT_blend_subtract)) then begin
      for i := 0 to high(oglBlendRemaps) do begin
         if(oglBlendRemaps[i][0] = GL_FUNC_SUBTRACT) then
            log.w('Disabled blend remap ' + sf(i) + ' because subtractive blend is not supported');
      end;
   end;
   {$ENDIF}
end;

procedure init();
begin
   oglRender := oglTRender.Create();

   oxglRenderer.Components.RegisterComponent('render', @componentReturn);
   oxglRenderer.AfterInit.Add(glInitRoutines, 'render', @renderInit);
end;

procedure deinit();
begin
   oglRender.Free();
end;

INITIALIZATION
   ox.PreInit.Add('gl.render', @init, @deinit);

END.
