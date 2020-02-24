{
   usesgl.inc, includes gl units according to platform or target

   Copyright (c) 2011. Dejan Boras
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
