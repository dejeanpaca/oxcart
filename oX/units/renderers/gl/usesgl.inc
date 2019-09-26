{
   usesgl.inc, includes gl units according to platform or target

   Started On:    11.02.2011.
}

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
