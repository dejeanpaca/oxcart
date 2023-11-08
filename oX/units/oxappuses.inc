{NOTE: Ignore warnings for oxuDefaults because it is used, even though fpc may complain it is not}

{$IFDEF UNIX}
   {$IFNDEF NO_THREADS}
   cthreads,
   {$ENDIF}
{$ENDIF}

{app}
{%H-}uAppInfo,
{ox}
{%H-}uOX,
{%H-}oxuDefaults
{$IFNDEF OX_LIBRARY}
{%H-}, oxuRun,
{%H-}oxuTypes
{$ENDIF}
