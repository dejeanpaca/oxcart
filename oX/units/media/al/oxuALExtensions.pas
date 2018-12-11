{
   daluExtensions, OpenAL extension management
   Copyright (C) 2009. Dejan Boras

   This file is part of dAL.

   dAL is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   dAL is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with dAL.  If not, see <http://www.gnu.org/licenses/>.

   Started On:    17.01.2009.
}

{$INCLUDE oxdefines.inc}
UNIT oxuALExtensions;

INTERFACE

   USES
      {$IFNDEF OX_LIBRARY}
      openal,
      {$ENDIF}
      uStd, uLog, StringUtils, ustrList,
      {ox}
      oxuAL;

TYPE
   oxPALExtensions = ^oxTALExtensions;

   { oxTALExtensions }

   oxTALExtensions = record
      Extensions: TpShortStringArray;
      sExtensions: pointer;
      nExtensions: int32;

      {$IFNDEF OX_LIBRARY}
      {analyze all extensions}
      procedure GetExtensions(device: PALCdevice = nil);
      {disposes all the extension information}
      procedure DisposeExtensions();
      {log all extensions}
      procedure LogExtensions(const logSection: string = 'Extensions');
      {$ENDIF}
      {checks whether an extension is supported}
      function ExtSupported(const ext: string): boolean;
   end;

VAR
   oxalExtensions: oxTALExtensions;

IMPLEMENTATION

{$IFNDEF OX_LIBRARY}

{ oxTALExtensions }

procedure oxTALExtensions.GetExtensions(device: PALCdevice);
var
   ExtensionsString: pChar;

begin
   DisposeExtensions();

   {extract extension strings}
   if(device <> nil) then
      ExtensionsString := pChar(alcGetString(device, ALC_EXTENSIONS))
   else
      ExtensionsString := pChar(alGetString(AL_EXTENSIONS));

   oxal.GetError();

   strList.ConvertSpaceSeparated(ExtensionsString, sExtensions, Extensions, nExtensions);
end;

procedure oxTALExtensions.DisposeExtensions();
begin
   XFreeMem(sExtensions);
   if(nExtensions > 0) then begin
      if(Extensions <> nil) then
         SetLength(Extensions, 0);

      nExtensions := 0;
   end;
end;

procedure oxTALExtensions.LogExtensions(const logSection: string);
var
   i: loopint;
   Exts: string;

begin
   log.Collapsed(logSection + ' (' + sf(nExtensions) + ')');

   for i := 0 to nExtensions - 1 do begin
      Exts := sf(i);

      AddLeadingPadding(Exts, '0', 3);

      log.i('(' + Exts + ') ' + Extensions[i]^);
   end;

   log.Leave();
end;
{$ENDIF}

function oxTALExtensions.ExtSupported(const ext: string): boolean;
var
   i: int32;

begin
   Result := false;

   {try to find the extension}
   for i := 0 to nExtensions - 1 do begin
      {if true the extension is found and supported}
      if(ext = Extensions[i]^) then
         exit(true);
   end;
end;

END.
