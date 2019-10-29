{
   uiuKeyMappings, ui global key mappings
   Copyright (c) 2019. Dejan Boras

   Started On:    11.04.2019.
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
