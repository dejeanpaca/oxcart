{
   appuKeys, keys
   Copyright (C) 2007. Dejan Boras

   Started On:    01.05.2007.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT appuInputTypes;

INTERFACE

   USES uStd;

CONST
   { key properties }
   {key is pressed}
   kpPRESSED                  = $01;
   {key was pressed previous cycle}
   kpWAS_PRESSED              = $02;
   {key was just pressed in current cycle}
   kpCYCLE_PRESSED            = $04;
   {key was pressed and released in the same cycle}
   kpPRESSED_RELEASED         = $08;

TYPE
   appiTAxis = word;
   appiTTrigger = word;
   appiTKeyState = TBitSet;

IMPLEMENTATION

END.
