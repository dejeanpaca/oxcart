{
   oxauRIFF, RIFF file format handling
   Copyright (C) 2007. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxauRIFF;

INTERFACE


TYPE
   riffTID = array[0..3] of char;

   riffTChunk = packed record
      ID: riffTID;
      Size: longword;
   end;

   riffTHeader = packed record
       ID: riffTID;
       Size: longword;
       typeID: riffTID;
   end;
   
CONST
   riffID: riffTID = ('R','I','F','F');

IMPLEMENTATION

END.
