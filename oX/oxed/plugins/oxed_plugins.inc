{$IFDEF OXED_PLUGIN_TESTS}
   {tests plugin}
   , oxeduTestsPlugin,
   {$IFNDEF NO_UI}
   oxeduTestsPluginUI
   {$ENDIF}
{$ENDIF}

