{
   usesgl.inc, includes gl units according to platform or target

   Started On:    11.02.2011.
}

{$IFDEF GLES}
   {%H-}gles
   {$DEFINE NO_DGL}
{$ELSE}
   {$IFNDEF NO_DGL}
      {%H-}dglOpenGL
   {$ELSE}
      {%H-}gl
   {$ENDIF}
{$ENDIF}
