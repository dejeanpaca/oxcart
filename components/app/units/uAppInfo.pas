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
}

{$INCLUDE oxheader.inc}
UNIT uAppInfo;

INTERFACE

   USES
      uStd, StringUtils;

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
      Name,
      NameShort,
      Author,
      Org,
      OrgShort,
      Website,
      Description: StdString;
      VersionFields: longint;
      Version: array[0..3] of longword;
      sVersion,
      Title: StdString;

      class procedure Initialize(out info: appTInfo); static;

      procedure SetName(const s: StdString);
      procedure SetOrganization(const s: StdString);
      procedure SetName(const n, o: StdString);
      procedure SetVersion(major: longword; minor: longint = -1; fix: longint = -1; revision: longint = -1);
      procedure SetVersion(const v: array of loopint);
      procedure SetVersion(const v: StdString);
      function GetVersionString(properties: longword = 0): StdString;

      class function GetShort(const s: StdString): StdString; static;
   end;

VAR
   appInfo: appTInfo;

IMPLEMENTATION

class procedure appTInfo.Initialize(out info: appTInfo);
begin
   ZeroOut(info, SizeOf(info));
end;

procedure appTInfo.SetName(const s: StdString);
begin
   Name := s;
   NameShort := GetShort(s);
end;

procedure appTInfo.SetOrganization(const s: StdString);
begin
   Org := s;
   OrgShort := GetShort(s);
end;

procedure appTInfo.SetName(const n, o: StdString);
begin
   setName(n);
   setOrganization(o);
end;

procedure appTInfo.SetVersion(major: longword; minor: longint; fix: longint; revision: longint);
begin
   Version[0] := major;
   VersionFields := 1;

   if(minor > -1) then begin
      Version[1] := minor;
      VersionFields := 2;

      if(fix > -1) then begin
         Version[2] := fix;
         VersionFields := 3;
      end;

      if(revision > -1) then begin
         Version[3] := revision;
         VersionFields := 4;
      end;
   end;
end;

procedure appTInfo.SetVersion(const v: array of loopint);
var
   major,
   minor,
   fix,
   revision: loopint;

begin
   major := -1;
   minor := -1;
   fix := -1;
   revision := -1;

   if(Length(v) > 0) then begin
     if(high(v) >= 0) then
        major := v[0];

     if(high(v) >= 1) then
        minor := v[1];

     if(high(v) >= 2) then
        fix := v[2];

     if(high(v) >= 3) then
        revision := v[3];

     SetVersion(major, minor, fix, revision);
   end;
end;

procedure appTInfo.SetVersion(const v: StdString);
var
   vs: array of StdString;
   n, i, code: longint;

begin
   vs := strExplode(v, '.');

   n := length(vs);
   if(n > 0) then begin
      if(n > 4) then
         n := 4;

      VersionFields := n;
      Version[0] := 0;
      Version[1] := 0;
      Version[2] := 0;
      Version[3] := 0;

      for i := 0 to (n - 1) do begin
         Val(vs[i], Version[i], code);

         if(code <> 0) then begin
            VersionFields := i;
            Version[i] := 0;
            break;
         end;
      end;
   end;
end;

{ INFO }
function appTInfo.GetVersionString(properties: longword = 0): StdString;
var
   i: longint;
   sver: StdString = '';
   short: StdString;

begin
   if(sVersion = '') then begin
      if(VersionFields > 0) then begin
         sver := 'v';

         for i := 0 to (VersionFields - 1) do begin
            if(i < appInfo.VersionFields - 1) then
               sver := sver + sf(Version[i]) + '.'
            else
               sver := sver + sf(Version[i]);
         end;
      end;
   end else
      sver := 'v' + sVersion;

   if(properties and appVERSION_STR_ONLY = 0) then begin
      if(properties and appVERSION_SHORT = 0) then
         Result := Name
      else begin
         if(NameShort = '') then
            short := Name
         else
            short := NameShort;

         Result := short;
      end;

      if(sver <> '') then
         Result := Result + ' ' + sver;
   end else
      Result := sver
end;

class function appTInfo.GetShort(const s: StdString): StdString;
var
   short: StdString;

begin
   short := StdString(lowerCase(s));
   EliminateWhiteSpace(short);

   Result := short;
end;

INITIALIZATION
   ZeroOut(appInfo, SizeOf(appInfo));

   appInfo.VersionFields   := 0;

END.
