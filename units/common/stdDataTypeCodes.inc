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
   dtcUTF8STRING      = $11;
   dtcXPSTRING        = $12;
   dtcXPUSTRING       = $13;
   dtcXSTRING         = $14;
   dtcSTRING          = dtcUTF8STRING;

   dtcPOINTER32       = $15;
   dtcPTR32 = dtcPOINTER32;
   dtcPOINTER64       = $16;
   dtcPTR64 = dtcPOINTER64;

   dtcARRAY           = $17;
   dtcRECORD          = $18;
   dtcSINGLE          = $19;
   dtcDOUBLE          = $1A;
   dtcEXTENDED        = $1B;
   dtcCOMP            = $1C;
   dtcCURRENCY        = $1D;
   dtcSET             = $1E;
   dtcFILE            = $1F;
   dtcDATE            = $20;
   dtcTIME            = $21;
   dtcDATETIME        = $22;
   dtcXDATA           = $23;
   dtcPTR             = $24;
   
   {vector types}
   dtcVECTOR2UB       = $25;
   dtcVECTOR3UB       = $26;
   dtcVECTOR4UB       = $27;
   dtcVECTOR2B        = $28;
   dtcVECTOR3B        = $29;
   dtcVECTOR4B        = $2A;

   dtcVECTOR2US       = $2B;
   dtcVECTOR3US       = $2C;
   dtcVECTOR4US       = $2D;
   dtcVECTOR2S        = $2E;
   dtcVECTOR3S        = $2F;
   dtcVECTOR4S        = $30;

   dtcVECTOR2UI       = $31;
   dtcVECTOR3UI       = $32;
   dtcVECTOR4UI       = $33;
   dtcVECTOR2I        = $34;
   dtcVECTOR3I        = $35;
   dtcVECTOR4I        = $36;

   dtcVECTOR2F        = $37;
   dtcVECTOR3F        = $38;
   dtcVECTOR4F        = $39;
   dtcVECTOR2D        = $3A;
   dtcVECTOR3D        = $3B;
   dtcVECTOR4D        = $3C;
   
   {matrix types}
   dtcMATRIX2UB       = $3D;
   dtcMATRIX3UB       = $3E;
   dtcMATRIX4UB       = $3F;
   dtcMATRIX2B        = $40;
   dtcMATRIX3B        = $41;
   dtcMATRIX4B        = $42;

   dtcMATRIX2US       = $43;
   dtcMATRIX3US       = $44;
   dtcMATRIX4US       = $45;
   dtcMATRIX2S        = $46;
   dtcMATRIX3S        = $47;
   dtcMATRIX4S        = $48;

   dtcMATRIX2UI       = $49;
   dtcMATRIX3UI       = $4A;
   dtcMATRIX4UI       = $4B;
   dtcMATRIX2I        = $4C;
   dtcMATRIX3I        = $4D;
   dtcMATRIX4I        = $4E;

   dtcMATRIX2F        = $4F;
   dtcMATRIX3F        = $50;
   dtcMATRIX4F        = $51;
   dtcMATRIX2D        = $52;
   dtcMATRIX3D        = $53;
   dtcMATRIX4D        = $54;

   dtcMAX_DTIV        = $54;


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
   0, {dtcUTF8STRING}
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

