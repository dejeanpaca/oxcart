{
   usesgl.inc, includes gl units according to platform or target

   Started On:    11.02.2011.
}

{$IFDEF OX_NO_GL_RENDERER}
   {$FATAL Included usesgl.inc, with OX_NO_GL_RENDERER defined}
{$ENDIF}


{$IFDEF GLES}
   gles
   {$DEFINE NO_DGL}
{$ELSE}
   {$IFNDEF NO_DGL}
      dglOpenGL
   {$ELSE}
      gl
   {$ENDIF}
{$ENDIF}
