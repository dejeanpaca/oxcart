{
   oxauAIFF, AudioIFF file format handling
   Copyright (C) 2007. Dejan Boras
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
