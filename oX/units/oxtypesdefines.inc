{$IF DEFINED(WINDOWS)}
   {$IFDEF CPU64}
      {$DEFINE EXCLUDE_EXTENDED}
   {$ENDIF}
{$ELSEIF DEFINED(ANDROID)}
   {$DEFINE EXCLUDE_EXTENDED}
   {$DEFINE EXCLUDE_CURRENCY}
{$ENDIF}
