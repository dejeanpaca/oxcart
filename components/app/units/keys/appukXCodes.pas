{
   appukXCodes, x key codes
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
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
