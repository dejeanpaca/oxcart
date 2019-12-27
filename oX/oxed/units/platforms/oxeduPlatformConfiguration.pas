{
   oxeduPlatformConfiguration, per platform configuration
   Copyright (C) 2019. Dejan Boras

   Started On:    29.10.2019.
}

{$INCLUDE oxdefines.inc}
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
