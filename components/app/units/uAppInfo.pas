{
   uAppInfo, application information
   Copyright (C) 2010. Dejan Boras

   it under the terms of the GNU Lesser General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

   Started on:    27.09.2010.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uAppInfo;

INTERFACE

   USES uStd, StringUtils;

CONST
   { version string properties }
   {show only name string}
   appVERSION_STR_ONLY  = $0001;
   {use short variant for version}
   appVERSION_SHORT     = $0002;

TYPE
   { appTInfo }
   appPInfo = ^appTInfo;
   appTInfo = record
      name,
      nameShort,
      author,
      org,
      orgShort,
      website,
      description: string;
      versionFields: longint;
      version: array[0..3] of longword;
      sVersion: string;
      title: string;

      procedure SetName(const s: string);
      procedure SetOrganization(const s: string);
      procedure SetName(const n, o: string);
      procedure SetVersion(major: longword; minor: longint = -1; fix: longint = -1; revision: longint = -1);
      procedure SetVersion(const v: string);
      function GetVersionString(properties: longword = 0): string;

      class function GetShort(const s: string): string; static;
   end;

VAR
   appInfo: appTInfo;

IMPLEMENTATION

procedure appTInfo.SetName(const s: string);
begin
   name := s;
   nameShort := GetShort(s);
end;

procedure appTInfo.SetOrganization(const s: string);
begin
   org := s;
   orgShort := GetShort(s);
end;

procedure appTInfo.SetName(const n, o: string);
begin
   setName(n);
   setOrganization(o);
end;

procedure appTInfo.SetVersion(major: longword; minor: longint; fix: longint; revision: longint);
begin
   version[0] := major;
   versionFields := 1;

   if(minor > -1) then begin
      version[1] := minor;
      versionFields := 2;

      if(fix > -1) then begin
         version[2] := fix;
         versionFields := 3;
      end;

      if(revision > -1) then begin
         version[3] := revision;
         versionFields := 4;
      end;
   end;
end;

procedure appTInfo.SetVersion(const v: string);
var
   vs: array of string;
   n, i, code: longint;

begin
   vs := strExplode(v, '.');

   n := length(vs);
   if(n > 0) then begin
      if(n > 4) then
         n := 4;

      versionFields := n;
      version[0] := 0;
      version[1] := 0;
      version[2] := 0;
      version[3] := 0;

      for i := 0 to (n - 1) do begin
         Val(vs[i], version[i], code);

         if(code <> 0) then begin
            versionFields := i;
            version[i] := 0;
            break;
         end;
      end;
   end;
end;

{ INFO }
function appTInfo.GetVersionString(properties: longword = 0): string;
var
   i: longint;
   sver: string = '';
   short: string;

begin
   if(sVersion = '') then begin
      if(versionFields > 0) then begin
         sver := 'v';

         for i := 0 to (versionFields - 1) do begin
            if(i < appInfo.versionFields - 1) then
               sver := sver + sf(version[i]) + '.'
            else
               sver := sver + sf(version[i]);
         end;
      end;
   end else
      sver := 'v' + sVersion;

   if(properties and appVERSION_STR_ONLY = 0) then begin
      if(properties and appVERSION_SHORT = 0) then
         result := name
      else begin
         if(nameShort = '') then
            short := name
         else
            short := nameShort;

         result := short;
      end;

      if(sver <> '') then
         result := result + ' ' + sver;
   end else
      result := sver
end;

class function appTInfo.GetShort(const s: string): string;
var
   short: string;

begin
   short := lowerCase(s);
   EliminateWhiteSpace(short);

   result := short;
end;

INITIALIZATION
   ZeroOut(appInfo, SizeOf(appInfo));

   appInfo.versionFields   := 0;

END.
