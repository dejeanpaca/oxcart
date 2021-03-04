{
   palKonvert
   Copyright (C) 2008. Dejan Boras
}

{$INCLUDE oxheader.inc}
PROGRAM palKonvert;

   USES
      uStd, dError, Colors, dImage, ConsoleUtils, StringUtils;

CONST
   dcProgramName           = 'palKonvert';
   dcProgramVersion        = $0132;
   dcProgramAuthor         = 'Dejan Boras';
   dcProgramDescription    = 'Converts various palette formats';

   {Palette File Formats}
   cpfNone                 = 00;
   cpfRAW                  = 01;
   cpfPaintShopPro         = 02;
   cpfCFStudio             = 03;
   cpfGIMP                 = 04;
   cpfXDPalette            = 05;

   {default palette file names}
   csDefaultPalFileName    = 'palette.pal';

   cFileBufSize            = 8192;

   {palette types}
   cptNone                 = 00;
   cptStandard             = 01;
   cptEGA                  = 02;

   {palette extension}
   cXDPalExt: string[4]    = '.xdp';

TYPE
   TPalette = array[0..255] of TColor4ub;

{XDPalette types & constants}
   xdpTID = array[0..4] of char;

CONST
   xdpcID: xdpTID          = ('X', 'D', 'P', 'A', 'L');
   xdpcVERSION             = $0100;

   {properties}
   xdpcPROPERTIES_EGA      = $0001;

TYPE
   {}
   xdpTHeader = record
      ID: xdpTID;
      Endian: byte;
      Version: word;
   end;

   {color header}
   xdpTColor = record
      Properties: longword;
      nColors: longint;
      Format: longword;
   end;

VAR
   {PROGRAM INFORMATION}
   srcFormat,
   Format,
   PaletteType,
   palPIXF: longword;
   sourceFN,
   destinationFN: string;
   fileBuf: array[0..cFileBufSize-1] of uint8;

   pal: TPalette;
   nColors: longint;

   kError: longint;

   sAuthor,
   sPalName,
   sPalDescription,
   sProgram: shortstring;

{ERROR HANDLING}
procedure keRaise(err: uint16);
begin
   kError := err;
end;

function _ioerror(): int32;
begin
   if(ioerror <> 0) then begin
      keRaise(eIO);
      result := eIO;
   end else
      result := 0;
end;

procedure errorHalt(const s: string);
begin
end;

{ LOADING }

{load a RAW palette}
procedure loadPalRAW();
var
   f: file;
   repx,
   fSize,
   Elements,
   Channels: int32;
   bRead: int64 = 0;
   buf: array[0..3] of uint8 = (0, 0, 0, 0);

{close the file}
procedure fClose();
begin
   Close(f);
   if(_ioerror <> 0) then
      console.w('Unable to close the palette file.');
end;

begin
   {open the file}
   FileReset(f, sourceFN);
   if(_ioerror <> 0) then
      exit;

   {figure out what kind of a palette file it is}
   fSize := FileSize(f);
   if(_ioerror <> 0) then
      exit;

   case fSize of
      16*3: begin
         Elements := 16;
         Channels := 3;
         palPIXF := PIXF_RGB;
      end;
      16*4: begin
         Elements := 16;
         Channels := 4;
         palPIXF := PIXF_RGBA;
      end;
      256*3: begin
         Elements := 256;
         Channels := 3;
         palPIXF := PIXF_RGB;
      end;
      256*4: begin
         Elements := 256;
         Channels := 4;
         palPIXF := PIXF_RGBA;
      end;
      else begin
         console.e('Unknown or unsupported palette format.');
         keRaise(eUnsupported);
         exit;
      end;
   end;

   {read in the palette.
   Though this all could have been read in less code,
   it would have been slower}
   if(Channels = 4) then begin
      {$PUSH}{$HINTS OFF}blockread(f, pal, Channels*Elements);{$POP}
      if(_ioerror <> 0) then begin
         fClose();
         exit;
      end;
   end else if(Channels = 3) then begin
      for repx := 0 to (elements-1) do begin
         blockread(f, buf, Channels, bRead);
         if(_ioerror <> 0) then begin
            fClose();
            exit;
         end;

         move(buf, pal[repx], 3);
      end;
   end;

   nColors := Elements;

   {finished}
   fClose();
end;

{load a palette}
procedure loadPal();
var
   f: text;
   pStr,
   numStr: string;
   repx,
   sFormat: uint32; {source format}
   colors,
   value,
   code: int32;
   color: TColor4ub;

procedure fClose();
begin
   Close(f);
   _ioerror();
end;

begin
   {Open the file}
   FileReset(f, sourceFN);
   if(_ioerror <> 0) then
      exit;

   {a small buffer to speed up things}
   SetTextBuf(f, fileBuf, cFileBufSize);

   palPIXF := PIXF_RGB;

   {find and read in the header}
   sFormat := 0;
   repeat
      readln(f, pStr);
      if(_ioerror <> 0) then exit;

      dStripWhiteSpace(pStr);

      if(pStr = 'JASC-PAL') then begin
         writeln('Paint Shop Pro Palette Format');
         sFormat := cpfPaintShopPro;
         break;
      end else if(pStr = 'Palette') then begin
         writeln('CF Studio Palette Format');
         sFormat := cpfCFStudio;
         break;
      end  else if(pStr = 'GIMP Palette') then begin
         writeln('GIMP Palette Format');
         sFormat := cpfGIMP;
         break;
      end;
   until eof(f);

   {check if it is a valid paint shop pro format}
   if(sFormat = cpfPaintShopPro) then begin
      {read the version}
      readln(f, pStr);
      if(_ioerror <> 0) then begin
         fClose();
         exit;
      end;
      if(pStr <> '0100') then begin
         fClose();
         keRaise(eUNSUPPORTED);
         exit;
      end;

      {read the number of colors}
      readln(f, pStr);
      if(_ioerror <> 0) then begin
         fClose();
         exit;
      end;
   end else if(sFormat = cpfCFStudio) then begin
      readln(f, pStr);
      if(_ioerror <> 0) then begin
         fClose();
         exit;
      end;

      if(pStr <> 'Version 4.0') then begin
         fClose();
         keRaise(eUNSUPPORTED);
         exit;
      end;
   end else if(sFormat = cpfGIMP) then begin
   end else begin
      keRaise(eUNSUPPORTED);
      exit;
   end;

   {read in the palette data}
   colors := 0;
   repeat
      readln(f, pStr);
      dStripWhiteSpace(pStr);
      if(pstr <> '') then
         if(pStr[1] <> '#') then begin {if not comment}
            for repx := 0 to 2 do begin
               numStr := dCopy2Del(pStr);
               val(numStr, value, code);
               if(code <> 0) then
                  break; {ignore any faulty lines}

               color[repx] := value;
               {go to next color only if current read successfully}
               if(repx = 2) then begin
                  pal[colors, 0] := color[0];
                  pal[colors, 1] := color[1];
                  pal[colors, 2] := color[2];
                  inc(colors);
               end;
            end;
         end;
   until eof(f) or (colors >= 256);
   nColors := colors;

   {done}
   Close(f);
   _ioerror();
end;

{read a string from a untyped file}
function readString(var f: file; var s: shortstring): longint;
begin
   blockread(f, s[0], 1);
   if(_ioerror() <> 0) then
      exit(kError);

   if(s[0] <> #0) then begin
      blockread(f, s[1], uint8(s[0]));
      _ioerror();
   end;

   result := kError;
end;

{load a XDPalette file}
procedure loadXDPal();
var
   f: file;
   hdr: xdpTHeader;
   clr: xdpTColor;
   repx: int32;

procedure cleanup();
begin
   close(f);
   IOResult();
end;

function reads(var s: shortstring): boolean;
begin
   result := readString(f, s) = 0;
   if(not result) then
      cleanup();
end;

begin
   FileReset(f, sourceFN);
   if(_ioerror() <> 0) then
      exit;

   {read the header}
   blockread(f, hdr, SizeOf(xdpTHeader));
   if(_ioerror <> 0) then begin
      cleanup();
      exit;
   end;

   {check the header}
   if(hdr.ID <> xdpcID) then begin
      console.e('The file is not a XDPalette file.');
      keRaise(eINVALID);
      exit;
   end;

   if(hdr.Endian <> ENDIAN_BYTE) then begin
      console.e('The file is written in a unsupported endian.');
      keRaise(eUNSUPPORTED);
      exit;
   end;

   if(hdr.Version <> xdpcVERSION) then begin
      console.e('The file format version is not supported.');
      keRaise(eUNSUPPORTED);
      exit;
   end;

   {read the general information}
   if(not reads(f, sAuthor)) then
      exit;

   if(not reads(f, sPalName)) then
      exit;

   if(not reads(f, sPalDescription)) then
      exit;

   if(not reads(f, sProgram)) then
      exit;

   {read the color information}
   blockread(f, clr, SizeOf(xdpTColor));
   if(_ioerror <> 0) then begin
      cleanup();
      exit;
   end;

   nColors := clr.nColors;
   palPIXF := clr.Format;

   {read the colors}
   if(nColors > 0) then
   for repx := 0 to (nColors - 1) do begin
      case palPIXF of
         PIXF_RGB, PIXF_BGR:
            blockread(f, pal[repx], SizeOf(TColor3ub));
         PIXF_RGBA, PIXF_BGRA:
            blockread(f, pal[repx], SizeOf(TColor4ub));
      end;
      if(_ioerror <> 0) then begin
         cleanup();
         exit;
      end;
   end;

   {done, close the file}
   Close(f);
   if(_ioerror <> 0) then
      console.w('Could not properly close the source file');
end;

{ SAVING }

{save a RAW palette}
procedure savePalRAW();
var
   f: file;
   repx: uint32;

begin
   FileRewrite(f, destinationFN);
   if(_ioerror <> 0) then
      exit;

   for repx := 0 to nColors-1 do begin
      blockwrite(f, pal[repx], 3);
      if(_ioerror <> 0) then
         exit;
   end;

   Close(f);
   if(_ioerror <> 0) then
      console.w('Failed to properly close the file.');
end;

{save some of the regular ASCII palettes}
procedure savePal();
var
   f: text;
   repx: uint32;

begin
   FileRewrite(f, destinationFN);
   if(_ioerror <> 0) then
      exit;

   SetTextBuf(f, fileBuf, cFileBufSize);
   if(_ioerror <> 0) then begin
      Close(f);
      exit;
   end;

   {write Paint Shop Pro palette file header}
   if(Format = cpfPaintShopPro) then begin
      writeln(f, 'JASC-PAL');
      writeln(f, '0100');
      writeln(f, nColors);
   {write CF Studio palette file header}
   end else if(Format = cpfCFStudio) then begin
      writeln(f, 'Palette');
      writeln(f, 'Version 4.0');
   {write GIMP palette file header}
   end else if(Format = cpfGIMP) then begin
      writeln(f, 'GIMP Palette');
      writeln(f, '#Created by palKonvert from file: ', sourceFN);
   end;

   {check for errors}
   if(_ioerror <> 0) then begin close(f); exit; end;

   {write down information}
   if(sAuthor <> '') then
      writeln(f, '#Author: ', sAuthor);
   if(_ioerror <> 0) then begin
      close(f);
      exit;
   end;

   if(sPalName <> '') then
      writeln(f, '#Palette Name: ', sPalName);

   if(sPalDescription <> '') then
      writeln(f, '#Palette Description: ', sPalDescription);

   sProgram := 'palKonvert '+sf(hi(dcProgramVersion))+'.'+sf(lo(dcProgramVersion));
   if(sProgram <> '') then
      writeln(f, '#Program: ', sProgram);

   {write down all the colours}
   for repx := 0 to nColors-1 do begin
      writeln(f, pal[repx][0], ' ', pal[repx][1], ' ', pal[repx][2]);
      if(_ioerror <> 0) then begin
         close(f);
         exit;
      end;
   end;

   {finished}
   Close(f);
   if(_ioerror <> 0) then
      console.w('Failed to properly close the file.');
end;

{write a string to a untyped file}
procedure writeString(var f: file; const s: shortstring);
begin
   blockwrite(f, s, Length(s) + 1);
   if(_ioerror <> 0) then
      exit;
end;

{save the palette to a XDPalette format file}
procedure saveXDPal();
var
   f: file;
   hdr: xdpTHeader;
   clr: xdpTColor;
   repx: int32;
   sProgram: shortstring;

procedure Cleanup();
begin
   close(f); IOResult;
end;

begin
   {open the file}
   FileRewrite(f, destinationFN);
   if(_ioerror <> 0) then
      exit;

   {write the header}
   hdr.ID         := xdpcID;
   hdr.Endian     := ENDIAN_BYTE;
   hdr.Version    := xdpcVERSION;

   blockwrite(f, hdr, SizeOf(hdr));
   if(_ioerror <> 0) then begin
      cleanup();
      exit;
   end;

   {write information}
   {author name}
   writeString(f, sAuthor);
   if(kError <> 0) then
      exit;
   {palette name}
   writeString(f, sPalName);
   if(kError <> 0) then
      exit;
   {palette description}
   writeString(f, sPalDescription);
   if(kError <> 0) then
      exit;
   {program name}
   sProgram := 'palKonvert '+sf(hi(dcProgramVersion))+'.'+sf(lo(dcProgramVersion));
   writeString(f, sProgram);
   if(kError <> 0) then
      exit;

   {write the color information}
   clr.Format     := palPIXF;
   clr.nColors    := nColors;
   clr.Properties := 0;
   if(paletteType = cptEGA) then
      clr.Properties := clr.Properties or xdpcPROPERTIES_EGA;

   blockwrite(f, clr, SizeOf(xdpTColor));
   if(_ioerror <> 0) then begin
      cleanup();
      exit;
   end;

   {write the colors in the palette}
   for repx := 0 to (nColors-1) do begin
      case palPIXF of
         PIXF_RGB, PIXF_BGR: begin
            blockwrite(f, pal[repx], SizeOf(TColor3ub));
         end;
         PIXF_RGBA, PIXF_BGRA: begin
            blockwrite(f, pal[repx], SizeOf(TColor4ub));
         end;
      end;
      if(_ioerror <> 0) then
         exit;
   end;

   {close the file}
   Close(f);
   if(_ioerror <> 0) then
      console.w('Failed to properly close the output file.');
end;

{ PALETTE OPERATIONS }

{processes the palette}
procedure ProcessPalette();
var
   repx: uint32;

begin
   if(PaletteType = cptEGA) then begin
      write('Converting palette to EGA...');
      for repx := 0 to nColors-1 do begin
         pal[repx][0] := pal[repx][0] shr 2;
         pal[repx][1] := pal[repx][1] shr 2;
         pal[repx][2] := pal[repx][2] shr 2;
      end;
      writeln(' Done!');
   end;
end;

{return the size of the file}
function fSize(): int64;
var
   f: file;

begin
   fSize := 0;

   Assign(f, sourceFN);
   Reset(f, 1);
   if(_ioerror <> 0) then
      exit;

   fSize := FileSize(f);
   if(_ioerror <> 0) then
      exit;

   Close(f);
   if(_ioerror <> 0) then
      exit;
end;

{converts one format to another}
procedure Konvert();
var
   ext: string;
   size: int64;

begin
   {INITIALISE}
   writeln('Converting file: ', sourceFN);

   {figure out what kind of a palette file it is}
   ext := LowerCase(dExtractFileExt(sourceFN));

   size := fSize();
   if(kError <> 0) then
      errorHalt('File not found or in use.');

   {check if there is any information in the file}
   if(size = 0) then
      errorHalt('The source file is empty.');

   {LOAD THE FILE}

   {if no format is specified then we'll have to guess the format}
   if(srcFormat = 0) then begin
      {it could be either a RAW palette or a Paint Shop Pro palette}
      if(ext = '.pal') then begin
         {need to check which one it actually is}
         if(size = 48) or (size = 64) or (size = 768) or (size = 1024) then
            loadPalRAW()
         else loadPal();
      {it could be a CF Studio palette}
      end else if(ext = '.hpl') then begin
         LoadPal();
      {it could be a gimp palette}
      end else if(ext = '.gimp') then begin
         LoadPal();
      end else if(ext = cXDPalExt) then begin
         LoadXDPal();
      {unknown or unsupported palette type}
      end else begin
         errorHalt('Cannot figure out the source palette format.');
      end;
   {if the format is specified then call the required palette loader}
   end else begin
      if(srcFormat = cpfRAW) then
         loadPalRAW()
      else if(srcFormat = cpfXDPalette) then
         loadXDPal()
      else
         loadPal();
   end;

   {check for errors}
   if(kError <> 0) then begin
      if(kError = eIO) then begin
         console.e('Input/Output Error');
         Writeln('IO Result: ', ioE);
      end else if(kError = eUNSUPPORTED) then begin
         console.e('Unknown or unsupported file format.');
      end else if(kError = eInvalid) then begin
         console.e('The file is corrupted or has an unsupported format.');
      end else begin
         console.e('Invalid condition reading the file');
      end;
      halt(1);
   end;

   {PROCESS THE PALETTE}
   ProcessPalette();

   {SAVE}
   writeln('Saving file as: ', destinationFN);

   {save in the new format}
   if(Format = cpfRAW) then
      savePalRAW()
   else if(Format = cpfXDPalette) then
      saveXDPal()
   else
      savePal();

   if(kError <> 0) then begin
      console.e('Failed to write the file.');
      kError := 0;
   end;

   {DONE}
   writeln(' ... Finished');
end;

{ PARAMETER PARSING }

{sets the format to the specified one}
procedure setFormat(fmt: uint32);
begin
   if(Format = 0) then
      Format := fmt
   else
      errorHalt('Cannot specify more than one format.');
end;

{set the source format}
procedure setSourceFormat(fmt: uint32);
begin
   if(srcFormat = 0) then
      srcFormat := fmt
   else
      errorHalt('Cannot specify more than one source format.');
end;

{sets the palette type to the specified one}
procedure setPaletteType(pt: uint32);
begin
   if(PaletteType = cptNone) then
      PaletteType := pt
   else
      errorHalt('Cannot specify more than one palette type.');
end;

{write out some help}
procedure WriteHelp();
begin
   writeln('palKonvert syntax:');
   writeln('   palKonvert [-option1, -option2] [sourcefile] [outfile]');
   writeln('option(1, 2, ...) can be one of the following:');
   writeln('   help      - displays this screen');
   writeln('   version   - displays program & version information');
   writeln('   srcformat - source format of the source file');
   writeln('   outformat - output format of the converted file');
   writeln('   paltype   - palette type for the converted file');
   writeln('   palauthor [name]         - palette author');
   writeln('   paldescr  [description]  - palette description');
   writeln('   palname   [name]         - palette name');
   writeln('sourcefile is the palette file to be converted.');
   writeln('outfile is the output file with the converted palette.');
   writeln('outformat is replaced by one of the following:');
   writeln('   raw   - raw RGB binary palette file');
   writeln('   psp   - Paint Shop Prop palette file');
   writeln('   cfs   - CF Studio palette file');
   writeln('   gimp  - GIMP palette file');
   writeln('   xdp   - XDPalette');
   writeln('srcformat is optional and can be any outformat prefixed with a ''src''');
   writeln('(no quotes, e.g. -srcgimp)');
   writeln();
   writeln('paltype can be one of the following:');
   writeln('   standard - normal palette, unchanged');
   writeln('   ega      - will convert the palette to an EGA display palette');
   writeln();
   writeln('The program will try to guess the source file format if it is not specified');
   writeln('with -srcformat, but it might fail. It uses the extension and some cheap');
   writeln('tricks to accomplish this.');
   halt(0);
end;

procedure WriteVersion();
begin
   writeln(dcProgramName + ' v', hi(dcProgramVersion), '.', lo(dcProgramVersion));
   writeln(dcProgramDescription);
   writeln();
   writeln('Copyright (c) '+dcProgramAuthor+' 2008.');
   writeln('All rights reserved.');
   writeln();
   halt(0);
end;

{parses the command line or terminal parameters}
procedure ParseParameters();
var
   repx: longint = 0;
   nParams: longint = 0;
   nName: longint = 0;
   pStr: string;

begin
   pStr := ParamStr(1);

   nParams := ParamCount();
   repeat
      inc(repx);
      pStr := ParamStr(repx);
      if(pStr = '?') or (pStr = '/?') or (pStr = '-help') or (pStr = '--help')
         then WriteHelp()
      else if(pStr[1] = '-') then begin {a format}
         pStr := LowerCase(pStr);
         {destination format}
         if(pStr = '-raw') then
            setFormat(cpfRAW)
         else if(pStr = '-psp') then
            setFormat(cpfPaintShopPro)
         else if(pStr = '-cfs') then
            setFormat(cpfCFStudio)
         else if(pStr = '-gimp') then
            setFormat(cpfGIMP)
         else if(pStr = '-xdp') then
            setFormat(cpfXDPalette)
         {source formats}
         else if(pStr = '-srcraw') then
            setSourceFormat(cpfRAW)
         else if(pStr = '-srcpsp') then
            setSourceFormat(cpfPaintShopPro)
         else if(pStr = '-srccfs') then
            setSourceFormat(cpfCFStudio)
         else if(pStr = '-srcgimp') then
            setSourceFormat(cpfGIMP)
         else if(pStr = '-srcxdp') then
            setSourceFormat(cpfXDPalette)
         {palette types}
         else if(pStr = '-ega') then
            setPaletteType(cptEGA)
         else if(pStr = '-standard') then
            setPaletteType(cptStandard)
         {commands}
         else if(pStr = '-version') then
            WriteVersion()
         {strings}
         else if(pStr = '-palauthor') then begin
            inc(repx);
            if(repx <= nParams) then begin
               pStr := ParamStr(repx);
               sAuthor := pStr;
            end else begin
               console.e('Did not specify the author''s name.');
            end;
         end else if(pStr = '-palname') then begin
            inc(repx);
            if(repx <= nParams) then begin
               pStr := ParamStr(repx);
               sPalName := pStr;
            end else begin
               console.e('Did not specify the palette name.');
            end;
         end else if(pStr = '-paldescr') then begin
            inc(repx);
            if(repx <= nParams) then begin
               pStr := ParamStr(repx);
               sPalDescription := pStr;
            end else begin
               console.e('Did not specify the palette description.');
            end;
         end else begin
            console.e('Unkown format or option: '+pStr+'. Use -? option for help.');
         end;
      end else begin
         inc(nName);
         case nName of
            1: sourceFN := pStr;
            2: destinationFN := pStr;
            else begin
               errorHalt('Too many parameters or invalid parameters. Check your typing.');
            end;
         end;
      end;
   until (repx = nParams);

   {check arguments}
   if(Format = cpfNone) then begin
      errorHalt('Format not specified.');
   end;

   {set the palette type to default if not already set}
   if(PaletteType = cptNone) then
      PaletteType := cptStandard;

   {check if the file name is specified}
   if(nName = 0) then begin
      errorHalt('Source file name not specified.');
   {check if the data file name is specified}
   end else if (nName = 1) then begin
      console.w('Destination palette name not specified. Will use: ' + csDefaultPalFileName);
      destinationFN := csDefaultPalFileName;
   end;
end;

{ MAIN }

{$R *.res}

BEGIN
   ParseParameters();
   Konvert();
END.
