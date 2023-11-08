{
   imguGIF, gif image loader
   Copyright (C) 2019. Dejan Boras

   Started On:    29.08.2019.
}

{$INCLUDE oxdefines.inc}
UNIT imguGIF;

INTERFACE

   USES uStd, uImage, uFileHandlers, imguRW;

IMPLEMENTATION

TYPE
   TGIFHeader = array[0..5] of char;

   TGIFDescriptor = packed record
      Header: TGIFHeader;

      Width,
      Height: Word;

      GCT: record
         Flags,
         BackgroundColorIndex,
         NonSquarePixels: Byte;
      end;
   end;

VAR
   ext: fhTExtension;
   loader: fhTHandler;

   //!
   //! * Header - 6 bytes
   //!     * "GIF87a" or "GIF89a"
   //! * Logical Screen Descriptor - 7 bytes
   //!     * bytes 0-3: (width: u16, height: u16)
   //!     * byte 4:    GCT MEGA FIELD
   //!         * bit 0:    GCT flag (whether there will be one)
   //!         * bits 1-3: GCT resolution --  ??????
   //!         * bit 4:    LEGACY GARBAGE about sorting
   //!         * bits 5-7: GCT size -- k -> 2^(k + 1) entries in the GCT
   //!     * byte 5:    GCT background colour index
   //!     * byte 6:    LEGACY GARBAGE about non-square pixels
   //! * If the GCT flag was set, the GCT follows (otherwise just go to the next section)
   //!     * Array of RGB triples (1 byte per channel = 3 bytes per colour)
   //!     * GCT size = k -> 3*2^(k + 1) bytes
   //!

{loads the bitmap file}
procedure load(data: pointer);
var
   ld: imgPFileData;
   imgP: imgTImage;

   descriptor: TGIFDescriptor;

begin
   ld := data;
   imgP := ld^.Image;

   ld^.BlockRead(descriptor, SizeOf(descriptor));
   if(ld^.Error <> 0) then
      exit;

   {check header}
   if(descriptor.Header <> 'GIF87a') and (descriptor.Header <> 'GIF89a') then begin
     ld^.SetError(eUNEXPECTED);
     exit;
   end;

   {check the flags}
end;

BEGIN
   {register the extension and loader}
   imgFile.Loaders.RegisterHandler(loader, 'GIF', @load);
   imgFile.Loaders.RegisterExt(ext, '.gif', @loader);

END.
