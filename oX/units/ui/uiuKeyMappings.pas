{
   uiuKeyMappings, ui global key mappings
   Copyright (c) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuKeyMappings;

INTERFACE

   USES
      uStd, udvars,
      {app}
      uAppInfo, appuKeyMappings;

VAR
   uiKeyMappings: appTKeyMappingGroup;

IMPLEMENTATION

INITIALIZATION
   appKeyMappings.AddGroup('Other', 'Everything else', uiKeyMappings);

END.
