{
   uiuKeyMappings, ui global key mappings
   Copyright (c) 2019. Dejan Boras

   Started On:    11.04.2019.
}

{$INCLUDE oxdefines.inc}
UNIT uiuKeyMappings;

INTERFACE

   USES
      uStd, uInit, uAppInfo, udvars, appuKeyMappings;

VAR
   oxKeyMappings: appTKeyMappingGroup;

IMPLEMENTATION

INITIALIZATION
   appKeyMappings.AddGroup('Other', 'Everything else', oxKeyMappings);

END.
