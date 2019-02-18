{
   KeyCodes.inc, list of standardised keyboard code constants.
   Copyright (C) 2008. Dejan Boras

   Started On:    13.06.2008.

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

   {NumPad keys}
   kcNUMENTER     = 095;
   kcNUM0         = 096;
   kcNUM1         = 097;
   kcNUM2         = 098;
   kcNUM3         = 099;
   kcNUM4         = 100;
   kcNUM5         = 101;
   kcNUM6         = 102;
   kcNUM7         = 103;
   kcNUM8         = 104;
   kcNUM9         = 105;

   kcNUMMUL       = 106;
   kcNUMADD       = 107;
   kcNUMSUBTRACT  = 108;
   kcNUMSEPARATOR = 109;
   kcNUMDIVIDE    = 110;
   kcNUMDECIMAL   = 111;
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
   kcF1           = 122;
   kcF2           = 123;
   kcF3           = 124;
   kcF4           = 125;
   kcF5           = 126;
   kcF6           = 127;
   kcF7           = 128;
   kcF8           = 129;
   kcF9           = 130;
   kcF10          = 131;
   kcF11          = 132;
   kcF12          = 133;
   kcF13          = 134;
   kcF14          = 135;
   kcF15          = 136;
   kcF16          = 137;
   kcF17          = 138;
   kcF18          = 139;
   kcF19          = 140;
   kcF20          = 141;
   kcF21          = 142;
   kcF22          = 143;
   kcF23          = 144;
   kcF24          = 145;

   kcSYSBACK      = 146;
   kcSYSHOME      = 147;
   kcSYSMENU      = 148;
   kcSYSSEARCH    = 149;
   
   {extra keys}
   kcPAUSEBREAK   = 160;
   kcSYSREQ       = 161;
   kcPRINTSCREEN  = 162;

   kcLOS          = 163;
   kcROS          = 164;
   kcLCONTEXT     = 165;
   kcRCONTEXT     = 166;
   kcSLEEP        = 167;
   
   {the following key codes are named for the default symbol obtained
   when the keys are pressed on a US keyboard, but may vary from system
   to system.}

   {symbols}
   kcTILDE        = 170; {~}
   kcDASH         = 171; {-}
   kcEQUAL        = 172; {=}
   kcSLASH        = 173; {/}
   kcSEMICOLON    = 174; {;}
   kcAPOSTROPHE   = 175; {'}
   kcBACKSLASH    = 176; {\}
   kcCOMMA        = 177; {,}
   kcPERIOD       = 178; {.}

   {brackets}
   kcLBRACKET     = 179;
   kcRBRACKET     = 180;
