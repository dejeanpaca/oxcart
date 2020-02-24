{
   Human readable binary sizes
   Copyright (C) 2011. Dejan Boras
}

{$MODE OBJFPC}{$H+}
UNIT uBinarySize;

INTERFACE

   USES math, sysutils, StringUtils, uStd;

CONST
   { IEC }
   IEC_BINARY_SIZE_B             = 0;
   IEC_BINARY_SIZE_KIB           = 1;
   IEC_BINARY_SIZE_MIB           = 2;
   IEC_BINARY_SIZE_GIB           = 3;
   IEC_BINARY_SIZE_TIB           = 4;
   IEC_BINARY_SIZE_PIB           = 5;
   IEC_BINARY_SIZE_EIB           = 6;
   IEC_BINARY_SIZE_ZIB           = 7;
   IEC_BINARY_SIZE_YIB           = 8;

   IEC_BINARY_SIZE_MAX_SUFFIX    = 8;

   iecBinarySizeUnitSuffixes: array[0..8] of StdString = (
      'B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'
   );

   { SI }

   SI_BINARY_SIZE_B              = 0;
   SI_BINARY_SIZE_KB             = 1;
   SI_BINARY_SIZE_MB             = 2;
   SI_BINARY_SIZE_GB             = 3;
   SI_BINARY_SIZE_TB             = 4;
   SI_BINARY_SIZE_PB             = 5;
   SI_BINARY_SIZE_EB             = 6;
   SI_BINARY_SIZE_ZB             = 7;
   SI_BINARY_SIZE_YB             = 8;

   SI_BINARY_SIZE_MAX_SUFFIX = 8;

   siBinarySizeUnitSuffixes: array[0..8] of StdString = (
      'B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'
   );

{ get suffix strings }
function getiecSuffixString(suffix: longint): StdString;
function getsiSuffixString(suffix: longint): StdString;

{ get binary size string }

function getiecBinarySizeString(size: int64; suffix: longint; decimals: longint = 1): StdString;
function getsiBinarySizeString(size: int64; suffix: longint; decimals: longint = 1): StdString;

{ get binary size string with suffix }

function getiecBinarySizeSuffixString(size: int64; suffix: longint; decimals: longint = 1; const separator: StdString = ' '): StdString;
function getsiBinarySizeSuffixString(size: int64; suffix: longint; decimals: longint = 1; const separator: StdString = ' '): StdString;

{get human readable versions for byte size}
function getiecByteSizeHumanReadable(byteCount: int64; decimals: loopint = 1; const separator: StdString = ' '): StdString;
function getsiByteSizeHumanReadable(byteCount: int64; decimals: loopint = 1; const separator: StdString = ' '): StdString;

{same as above, except it shows iec units with SI suffixes (compute IEC and lie it's SI)}
function getiecByteSizeHumanReadableSI(byteCount: int64; decimals: loopint = 1; const separator: StdString = ' '): StdString;

IMPLEMENTATION

{ get binary size string }

function getiecSuffixString(suffix: longint): StdString;
begin
   if(suffix >= 0) and (suffix <= high(iecBinarySizeUnitSuffixes)) then
      Result := iecBinarySizeUnitSuffixes[suffix]
   else
      Result := '?';
end;

function getsiSuffixString(suffix: longint): StdString;
begin
   if(suffix >= 0) and (suffix <= high(siBinarySizeUnitSuffixes)) then
      Result := siBinarySizeUnitSuffixes[suffix]
   else
      Result := '?';
end;

function getiecBinarySizeString(size: int64; suffix: longint; decimals: longint): StdString;
var
   floatSize: double;

begin
   if(suffix < IEC_BINARY_SIZE_MAX_SUFFIX) then begin
      if(suffix = 0) then
         Result := sf(size)
      else begin
         floatSize := size / power(1024, suffix);
         Result := sf(floatSize, decimals);
      end;
   end else
      Result := sf(size);
end;

function getsiBinarySizeString(size: int64; suffix: longint; decimals: longint): StdString;
var
   floatSize: double;

begin
   if(suffix < SI_BINARY_SIZE_MAX_SUFFIX) then begin
      if(suffix = 0) then
         Result := sf(size)
      else begin
         floatSize := size / power(1000, suffix);
         Result := sf(floatSize, decimals);
      end;
   end else
      Result := sf(size);
end;

{ get binary size string with suffix }

function getiecBinarySizeSuffixString(size: int64; suffix: longint; decimals: longint; const separator: StdString): StdString;
var
   floatSize: double;

begin
   if(suffix < IEC_BINARY_SIZE_MAX_SUFFIX) then begin
      if(suffix = 0) then
         Result := sf(size) + separator + iecBinarySizeUnitSuffixes[suffix]
      else begin
         floatSize := size / power(1024, suffix);
         Result := sf(floatSize, decimals) + separator + iecBinarySizeUnitSuffixes[suffix];
      end;
   end else
      Result := sf(size) + separator + 'B';
end;

function getsiBinarySizeSuffixString(size: int64; suffix: longint; decimals: longint; const separator: StdString): StdString;
var
   floatSize: double;

begin
   if(suffix < SI_BINARY_SIZE_MAX_SUFFIX) then begin
      if(suffix = 0) then
         Result := sf(size) + separator + siBinarySizeUnitSuffixes[suffix]
      else begin
         floatSize := size / power(1000, suffix);
         Result := sf(floatSize, decimals) + separator + siBinarySizeUnitSuffixes[suffix];
      end;
   end else
      Result := sf(size) + separator + 'B';
end;


function getiecByteSizeHumanReadable(byteCount: int64; decimals: loopint; const separator: StdString): StdString;
var
   bytes,
   place: int64;
   num: double;

begin
   if(byteCount > 0) then begin
      bytes := abs(byteCount);
      place := round(floor(logn(1024, bytes)));
      num := RoundTo(bytes / power(1024, place), -decimals);

      if(place > 0) then
         Result := FormatFloat('', sign(byteCount) * num) + separator + iecBinarySizeUnitSuffixes[place]
      else
         Result := sf(byteCount) + separator + 'B';
   end else
      Result := '0' + separator + 'B';
end;

function getsiByteSizeHumanReadable(byteCount: int64; decimals: loopint; const separator: StdString): StdString;
var
   bytes,
   place: int64;
   num: double;

begin
   if(byteCount > 0) then begin
      bytes := abs(byteCount);
      place := round(floor(logn(1000, bytes)));
      num := RoundTo(bytes / power(1000, place), -decimals);

      if(place > 0) then
         Result := FormatFloat('', sign(byteCount) * num) + separator + iecBinarySizeUnitSuffixes[place]
      else
        Result := sf(byteCount) + separator + 'B';
   end else
      Result := '0B';
end;

function getiecByteSizeHumanReadableSI(byteCount: int64; decimals: loopint; const separator: StdString): StdString;
var
   bytes,
   place: int64;
   num: double;

begin
   if(byteCount > 0) then begin
      bytes := abs(byteCount);
      place := round(floor(logn(1024, bytes)));
      num := RoundTo(bytes / power(1024, place), -decimals);

      if(place > 0) then
         Result := FormatFloat('', sign(byteCount) * num) + separator + siBinarySizeUnitSuffixes[place]
      else
        Result := sf(byteCount) + separator + 'B';
   end else
      Result := '0' + separator + 'B';
end;

END.

