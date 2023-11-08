{
   oxeduPlatformConfiguration, per platform configuration
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduPlatformConfiguration;

INTERFACE

   USES
      uStd;

TYPE
   oxedTPlatformConfiguration = class
      Features: TSimpleStringList;

      {compiler symbols to use when building}
      CompilerSymbols: TSimpleStringList;
   end;

IMPLEMENTATION

END.
