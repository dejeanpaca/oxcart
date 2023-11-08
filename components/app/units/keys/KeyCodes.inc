{
   KeyCodes.inc, list of standardised keyboard code constants.
   Copyright (C) 2008. Dejan Boras

   In order to get around some problems with using the keyboard on various
   operating systems I had to make a standardised list of codes, and remap
   values returned from the operating system into these. This way everything is
   pretty much standardised for all my programs.
}

   {The value 0 is not allowed}

   {standard keys}
   kcESC          = 001;
   kcENTER        = 002;
   kcRETURN       = kcENTER; {whichever your favorite is}

   kcTAB          = 003;
   kcSPACE        = 004;
   kcBACKSPACE    = 005;
   kcDEL          = 006;

   {modifiers}
   kcLSHIFT       = 007;
   kcRSHIFT       = 008;
   kcLCTRL        = 009;
   kcRCTRL        = 010;
   kcLALT         = 011;
   kcRALT         = 012;

   kcNUMLOCK      = 013;
   kcSCROLLLOCK   = 014;
   kcCAPSLOCK     = 015;
   kcINSERT       = 016;

   {positioning keys}
   kcPGUP         = 031;
   kcPGDN         = 032;
   kcEND          = 033;
   kcHOME         = 034;

   {position keys}
   kcLEFT         = 035;
   kcUP           = 036;
   kcRIGHT        = 037;
   kcDOWN         = 038;

   {numbers, usually just decrement these by 48(or shift 3 bits right) to get
   their integer value instead of code}
   kc0            = 048;
   kc1            = 049;
   kc2            = 050;
   kc3            = 051;
   kc4            = 052;
   kc5            = 053;
   kc6            = 054;
   kc7            = 055;
   kc8            = 056;
   kc9            = 057;

   {alphabetical symbols}
   kcA            = 065;
   kcB            = 066;
   kcC            = 067;
   kcD            = 068;
   kcE            = 069;
   kcF            = 070;
   kcG            = 071;
   kcH            = 072;
   kcI            = 073;
   kcJ            = 074;
   kcK            = 075;
   kcL            = 076;
   kcM            = 077;
   kcN            = 078;
   kcO            = 079;
   kcP            = 080;
   kcQ            = 081;
   kcR            = 082;
   kcS            = 083;
   kcT            = 084;
   kcU            = 085;
   kcV            = 086;
   kcW            = 087;
   kcX            = 088;
   kcY            = 089;
   kcZ            = 090;

   {the following key codes are named for the default symbol obtained
   when the keys are pressed on a US keyboard, but may vary from system
   to system.}

   {symbols}
   kcTILDE        = 091; {~}
   kcDASH         = 092; {-}
   kcEQUAL        = 093; {=}
   kcSLASH        = 094; {/}
   kcSEMICOLON    = 095; {;}
   kcAPOSTROPHE   = 096; {'}
   kcBACKSLASH    = 097; {\}
   kcCOMMA        = 098; {,}
   kcPERIOD       = 099; {.}

   {brackets}
   kcLBRACKET     = 100;
   kcRBRACKET     = 101;


   { remap range }
   kcSTART_REMAP  = kc0;
   kcEND_REMAP    = kcRBRACKET;

   {NumPad keys}
   kcNUMENTER     = 110;
   kcNUM0         = 111;
   kcNUM1         = 112;
   kcNUM2         = 113;
   kcNUM3         = 114;
   kcNUM4         = 115;
   kcNUM5         = 116;
   kcNUM6         = 117;
   kcNUM7         = 118;
   kcNUM8         = 119;
   kcNUM9         = 120;

   kcNUMMUL       = 121;
   kcNUMADD       = 122;
   kcNUMSUBTRACT  = 123;
   kcNUMSEPARATOR = 124;
   kcNUMDIVIDE    = 125;
   kcNUMDECIMAL   = 126;
   kcNUMINSERT    = kcNUM0;
   kcNUMDEL       = kcNUMDECIMAL;

   kcNUMPGUP      = kcNUM9;
   kcNUMPGDN      = kcNUM3;
   kcNUMHOME      = kcNUM7;
   kcNUMEND       = kcNUM1;
   kcNUMBEGIN     = kcNUM5;
   kcNUMUP        = kcNUM8;
   kcNUMDOWN      = kcNUM2;
   kcNUMLEFT      = kcNUM4;
   kcNUMRIGHT     = kcNUM6;

   {function keys}
   kcF1           = 130;
   kcF2           = 131;
   kcF3           = 132;
   kcF4           = 133;
   kcF5           = 134;
   kcF6           = 135;
   kcF7           = 136;
   kcF8           = 137;
   kcF9           = 138;
   kcF10          = 139;
   kcF11          = 140;
   kcF12          = 141;
   kcF13          = 142;
   kcF14          = 143;
   kcF15          = 144;
   kcF16          = 145;
   kcF17          = 146;
   kcF18          = 147;
   kcF19          = 148;
   kcF20          = 149;
   kcF21          = 150;
   kcF22          = 151;
   kcF23          = 152;
   kcF24          = 153;

   kcSYSBACK      = 160;
   kcSYSHOME      = 161;
   kcSYSMENU      = 162;
   kcSYSSEARCH    = 163;
   
   {extra keys}
   kcPAUSEBREAK   = 164;
   kcSYSREQ       = 165;
   kcPRINTSCREEN  = 166;

   kcLOS          = 167;
   kcROS          = 168;
   kcLCONTEXT     = 169;
   kcRCONTEXT     = 170;
   kcSLEEP        = 171;

