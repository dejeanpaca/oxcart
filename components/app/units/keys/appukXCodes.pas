{
   appukXCodes, x key codes
   Copyright (C) 2017. Dejan Boras

   Started On:    17.01.2017.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT appukXCodes;

INTERFACE

   USES appuKeys;

CONST
   {$INCLUDE ./xkeyremapcodes.inc}

   XK_MISC_START     = $ff08;
   XK_MISC_END       = $ffff;
   XK_LATIN_START    = $fe00;
   XK_LATIN_END      = $feff;

IMPLEMENTATION

END.
