{NOTE: Ignore warnings for oxuDefaults because it is used, even though fpc may complain it is not}

{$IFNDEF NO_THREADS}
   {$IFDEF UNIX}
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
