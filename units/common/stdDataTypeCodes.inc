{
   stdDataTypeCodes.inc, standard data type codes
   Copyright (c) 2009. Dejan Boras

   Started on:    22.12.2008.

   This is a list of standardised data type codes used within many of my 
   programs and libraries. Instead of using multiple list of codes that do the
   same thing I've created a standardised list.
}

   {DATA TYPES}
   dtcNIL             = $00; 
   dtcVOID = dtcNIL;

   dtcUINT8           = $01;
      dtcBYTE = $01;
   dtcUINT16          = $02;
      dtcWORD = $02;
   dtcUINT32          = $03;
      dtcDWORD = $03;
      dtcLONGWORD = $03;
   dtcUINT64          = $04;
   dtcUINT128         = $05;
   dtcINT8            = $06;
      dtcSHORTINT = $06;
   dtcINT16           = $07;
      dtcSMALLINT = $07;
   dtcINT32           = $08;
      dtcLONGINT = $08;
   dtcINT64           = $09;
   dtcINT128          = $0A;
   {$IFDEF CPU32}
   dtcSIZEINT         = dtcINT32;
   {$ENDIF}
   {$IFDEF CPU64}
   dtcSIZEINT         = dtcINT64;
   {$ENDIF}


   dtcBOOL            = $0B;
   dtcCHAR            = $0C;
   dtcUCHAR           = $0D;

   dtcSHORTSTRING     = $0E;
   dtcANSISTRING      = $0F;
   dtcWIDESTRING      = $10;
   dtcXPSTRING        = $11;
   dtcXPUSTRING       = $12;
   dtcXSTRING         = $13;
   dtcSTRING          = dtcANSISTRING;

   dtcPOINTER32       = $14; 
   dtcPTR32 = dtcPOINTER32;
   dtcPOINTER64       = $15; 
   dtcPTR64 = dtcPOINTER64;

   dtcARRAY           = $16;
   dtcRECORD          = $17;
   dtcSINGLE          = $18;
   dtcDOUBLE          = $19;
   dtcEXTENDED        = $1A;
   dtcCOMP            = $1B;
   dtcCURRENCY        = $1C;
   dtcSET             = $1D;
   dtcFILE            = $1E;
   dtcDATE            = $1F;
   dtcTIME            = $20;
   dtcDATETIME        = $21;
   dtcXDATA           = $22;
   dtcPTR             = $23;
   
   {vector types}
   dtcVECTOR2UB       = $24;
   dtcVECTOR3UB       = $25;
   dtcVECTOR4UB       = $26;
   dtcVECTOR2B        = $27;
   dtcVECTOR3B        = $28;
   dtcVECTOR4B        = $29;

   dtcVECTOR2US       = $2A;
   dtcVECTOR3US       = $2B;
   dtcVECTOR4US       = $2C;
   dtcVECTOR2S        = $2D;
   dtcVECTOR3S        = $2E;
   dtcVECTOR4S        = $2F;

   dtcVECTOR2UI       = $30;
   dtcVECTOR3UI       = $31;
   dtcVECTOR4UI       = $32;
   dtcVECTOR2I        = $33;
   dtcVECTOR3I        = $34;
   dtcVECTOR4I        = $35;

   dtcVECTOR2F        = $36;
   dtcVECTOR3F        = $37;
   dtcVECTOR4F        = $38;
   dtcVECTOR2D        = $39;
   dtcVECTOR3D        = $3A;
   dtcVECTOR4D        = $3B;
   
   {matrix types}
   dtcMATRIX2UB       = $3C;
   dtcMATRIX3UB       = $3D;
   dtcMATRIX4UB       = $3E;
   dtcMATRIX2B        = $3F;
   dtcMATRIX3B        = $40;
   dtcMATRIX4B        = $41;

   dtcMATRIX2US       = $42;
   dtcMATRIX3US       = $43;
   dtcMATRIX4US       = $44;
   dtcMATRIX2S        = $45;
   dtcMATRIX3S        = $46;
   dtcMATRIX4S        = $47;

   dtcMATRIX2UI       = $48;
   dtcMATRIX3UI       = $49;
   dtcMATRIX4UI       = $4A;
   dtcMATRIX2I        = $4B;
   dtcMATRIX3I        = $4C;
   dtcMATRIX4I        = $4D;

   dtcMATRIX2F        = $4E;
   dtcMATRIX3F        = $4F;
   dtcMATRIX4F        = $50;
   dtcMATRIX2D        = $51;
   dtcMATRIX3D        = $52;
   dtcMATRIX4D        = $53;

   dtcMAX_DTIV        = $53;


   dtcSizes: array[0..dtcMAX_DTIV] of longint =
  (0, {dtcNIL}
   1, {dtcUINT8}
   2, {dtcUINT16}
   4, {dtcUINT32}
   8, {dtcUINT64}
   16, {dtcUINT128}
   1, {dtcINT8}
   2, {dtcINT16}
   4, {dtcINT32}
   8, {dtcINT64}
   16, {dtcINT128}

   1, {dtcBOOL}
   1, {dtcCHAR}
   2, {dtcUCHAR}

   0, {dtcSHORTSTRING}
   0, {dtcANSISTRING}
   0, {dtcWIDESTRING}
   0, {dtcXPSTRING}
   0, {dtcXPUSTRING}
   0, {dtcXSTRING}

   4, {dtcPOINTER32}
   8, {dtcPOINTER64}

   0, {dtcARRAY}
   0, {dtcRECORD}
   4, {dtcSINGLE}
   8, {dtcDOUBLE}
   8, {dtcCOMP, ?}
   10, {dtcEXTENDED, ?}
   8, {dtcCURRENCY, ?}
   0, {dtcSET}
   0, {dtcFILE}
   0, {dtcDATE, ?}
   0, {dtcTIME, ?}
   0, {dtcDATETIME, ?}
   0, {dtcXDATA}
   0, {dtcPTR}

   {vector types}

   2, {dtcVECTOR2UB}
   3, {dtcVECTOR3UB}
   4, {dtcVECTOR4UB}
   2, {dtcVECTOR2B}
   3, {dtcVECTOR3B}
   4, {dtcVECTOR4B}

   4, {dtcVECTOR2US}
   6, {dtcVECTOR3US}
   8, {dtcVECTOR4US}
   4, {dtcVECTOR2S}
   6, {dtcVECTOR3S}
   8, {dtcVECTOR4S}

   8, {dtcVECTOR2UI}
   12, {dtcVECTOR3UI}
   16, {dtcVECTOR4UI}
   8, {dtcVECTOR2I}
   12, {dtcVECTOR3I}
   16, {dtcVECTOR4I}

   8, {dtcVECTOR2F}
   12, {dtcVECTOR3F}
   16, {dtcVECTOR4F}
   16, {dtcVECTOR2D}
   24, {dtcVECTOR3D}
   32, {dtcVECTOR4D}

   {matrix types}

   4, {dtcMATRIX2UB}
   9, {dtcMATRIX3UB}
   16, {dtcMATRIX4UB}
   4, {dtcMATRIX2B}
   9, {dtcMATRIX3B}
   16, {dtcMATRIX4B}

   8, {dtcMATRIX2US}
   18, {dtcMATRIX3US}
   32, {dtcMATRIX4US}
   8, {dtcMATRIX2S}
   18, {dtcMATRIX3S}
   32, {dtcMATRIX4S}

   16, {dtcMATRIX2UI}
   36, {dtcMATRIX3UI}
   64, {dtcMATRIX4UI}
   16, {dtcMATRIX2I}
   36, {dtcMATRIX3I}
   64, {dtcMATRIX4I}

   16, {dtcMATRIX2F}
   36, {dtcMATRIX3F}
   64, {dtcMATRIX4F}
   32, {dtcMATRIX2D}
   72, {dtcMATRIX3D}
   128 {dtcMATRIX4D}
   );

