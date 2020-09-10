{
  oxuFileFormat, common oX file format functionality
  Copyright (c) 2012. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuFileFormat;

INTERFACE

   USES
     {files}
     uStd,
     {oX}
     uOX;

CONST
   oxfeINVALID_FORMAT_VERSION       = $1001;
   oxfeINVALID_VERSION              = $1002;

TYPE
   oxfTHeaderID      = array[0..3] of char;
   oxfTHeaderTypeID  = array[0..3] of char;
   oxfTVersion       = longword;

CONST
   oxfHDR_VALIDATE_IGNORE_ENDIAN    = $0001;
   oxfHDR_VALIDATE_IGNORE_VERSION   = $0002;

TYPE
   oxfTHeaderValidation = record
      typeID: oxfTHeaderTypeID;
      version: oxfTVersion;
      properties: longword;
   end;

   oxfTFHeader = packed record
      ID: oxfTHeaderID;
      typeID: oxfTHeaderTypeID;
      endian: word;
      oxfversion,
      version: oxfTVersion;
      md5: array[0..15] of byte;
   end;

   oxTFileFormatHelper = record
      headerID: oxfTHeaderID;
      version: oxfTVersion;
      defaultHeader: oxfTFHeader;

      function Validate(var hdr: oxfTFHeader; var vld: oxfTHeaderValidation): longint;
   end;

VAR
   oxfFormat: oxtFileFormatHelper;

IMPLEMENTATION

function oxtFileFormatHelper.Validate(var hdr: oxfTFHeader; var vld: oxfTHeaderValidation): longint;
begin
   result := eNONE;

   if(hdr.oxfversion <> oxfFormat.version) then
      exit(oxfeINVALID_FORMAT_VERSION);

   if(vld.properties and oxfHDR_VALIDATE_IGNORE_ENDIAN = 0) and
      (hdr.endian <> ENDIAN_WORD) then
         exit(oxeUNSUPPORTED_ENDIAN);

   if(vld.properties and oxfHDR_VALIDATE_IGNORE_VERSION = 0) and
      (hdr.version <> vld.version) then
         exit(oxfeINVALID_VERSION);
end;

INITIALIZATION
   oxfFormat.headerID   := 'OX10';
   oxfFormat.version    := 0001;

   oxfFormat.defaultHeader.ID          := oxfFormat.headerID;
   oxfFormat.defaultHeader.oxfversion  := oxfFormat.version;
   oxfFormat.defaultHeader.endian      := ENDIAN_WORD;
END.
