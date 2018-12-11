{
   oxauAIFF, AudioIFF file format handling
   Copyright (C) 2007. - 2009. Dejan Boras

   Started On:    14.09.2007.
}

{$INCLUDE oxdefines.inc}
UNIT oxauAIFF;

INTERFACE


TYPE
   aiffTID = array[0..3] of char;

   aiffTChunk = packed record
      ID: aiffTID;
      Size: longword;
   end;

   aiffTHeader = packed record
       ID: aiffTID;
       Size: longword;
       typeID: aiffTID;
   end;

IMPLEMENTATION

END.
