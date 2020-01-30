{
   imguTGA, Truevision Targa image loader for dImage
   Copyright (C) 2009. Dejan Boras

   Started On:    26.06.2009.
}

{$INCLUDE oxheader.inc}
UNIT imguTGAStuff;

INTERFACE

CONST
   {targa image types}
   TGA_NO_IMAGE_DATA                = $00; {no image data included}
   TGA_UNCOMPRESSED_COLOR_MAPPED    = $01; {uncompressed, color mapped}
   TGA_UNCOMPRESSED_TRUE_COLOR      = $02; {uncompressed, true color}
   TGA_UNCOMPRESSED_BLACK_WHITE     = $03; {uncompressed, black and white}
   TGA_RLE_COLOR_MAPPED             = $09; {RLE compression, color mapped}
   TGA_RLE_TRUE_COLOR               = $0A; {RLE compression, true color}
   TGA_RLE_BLACK_WHITE              = $0B; {RLE compression, black and white}

   TGA_ORIGIN_HORIZONTAL            = $0010; {ORIGIN}
   TGA_ORIGIN_VERTICAL              = $0020;

   {footer signature}
   tgacFooterSignature: array[0..15] of char = ('T', 'R', 'U', 'E', 'V', 'I', 'S', 'I', 'O', 'N',
                                                '-', 'X', 'F', 'I', 'L', 'E');

TYPE
   {targa footer, 26 bytes}
   tgaTFooter = packed record
      offsetExt,
      offsetDev: longword; {extension and developer directory offset}

      Signature: array[0..15] of char; {signature}

      chars: array[0..1] of char; {dot and null characters}
   end;

TYPE
   {targa header, 12 bytes}
   tgaTHeader = packed record
      lengthID,
      typeColorMap,
      typeImage: byte;

      cmSpec: record {color map specification}
         FirstEntry,
         cmLength: word;
         cmEntrySize: byte;
      end;
   end;

   {targa image specification, 10 bytes}
   tgaTImageSpec = packed record
      xOrigin,
      yOrigin: smallint;

      Width,
      Height: word;

      PixDepth,
      imgDescriptor: byte;
   end;

IMPLEMENTATION

END.
