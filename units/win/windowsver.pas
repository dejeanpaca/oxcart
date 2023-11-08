{
   windowsver, Windows OS version information
   Copyright (C) 2009. Dejan Boras

   Started On:    12.01.2009.
}


{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT windowsver;

INTERFACE

   USES StringUtils, windows;

TYPE
   winTVersion = record
      platform,
      major, 
      minor,
      buildNumber,
      spMajorVersion: longint;
      
      name,
      spName: string;

      procedure Initialize();
      function GetString(): string;
      function GetShortString(): string;
      function Check(maj: longint): Boolean;
      function Check(maj, min: longint): Boolean;
   end;

VAR
   windowsVersion: winTVersion;

IMPLEMENTATION

procedure winTVersion.Initialize();
var
   i: OSVERSIONINFO;

begin
   name := '';

   i.dwOSVersionInfoSize := SizeOf(OSVERSIONINFO);
   if(GetVersionEx(i)) then begin
      platform    := i.dwPlatformID;
      major       := i.dwMajorVersion;
      minor       := i.dwMinorVersion;
      buildNumber := i.dwBuildNumber;
      spName      := i.szCSDVersion;

      case i.dwPlatformID of
         {Windows NT}
         VER_PLATFORM_WIN32_NT: begin
            {Windows NT}
            if(i.dwMajorVersion <= 4) then
               name := 'NT';
            
            {Windows 2000}
            if(i.dwMajorVersion = 5) and (i.dwMinorVersion = 0) then
               name := '2000';
            
            {Windows XP}
            if(i.dwMajorVersion = 5) and (i.dwMinorVersion = 1) then begin
               name := 'XP';
               if(spName = 'Service Pack 3') then
                  spMajorVersion := 3
               else if (spName = 'Service Pack 2') then
                  spMajorVersion := 2
               else if (spName = 'Service Pack 1') then
                  spMajorVersion := 1;
            end;
            
            {Windows Server 2003}
            if(i.dwMajorVersion = 5) and (i.dwMinorVersion = 2) then
               name := 'Server 2003';

            {vista, 7, 8}
            if(i.dwMajorVersion = 6) then begin
               if(i.dwMinorVersion = 0) then
                  name := 'Vista'
               else if(i.dwMinorVersion = 1) then
                  name := '7'
               else if (i.dwMinorVersion = 2) then
                  name := '8'
               else if (i.dwMinorVersion = 3) then
                  name := '8.1';
            end;

            if(i.dwMajorVersion = 10) then
               name := '10';
         end;

         {Windows 9x, Me}
         VER_PLATFORM_WIN32_WINDOWS: begin
            {windows 95}
            if(i.dwMajorVersion = 4) and (i.dwMinorVersion = 0) then begin
               name := '95';
               
               if(i.szCSDVersion[1] = 'C') or (i.szCSDVersion[1] = 'B') then
                  spName := 'OSR2';
            end;
            
            {windows 98}
            if(i.dwMajorVersion = 4) and (i.dwMinorVersion = 10) then begin
               name := '98';
               
               if(i.szCSDVersion[1] = 'A') then
                  spName := 'SE';
            end;
            
            {Windows Millennium Edition}
            if(i.dwMajorVersion = 4) and (i.dwMinorVersion = 90) then
               name := 'ME';
         end;
      end;
   end;

   if(name = '') then
      name := 'Windows'
   else
      name := 'Windows ' + name;
end;

function winTVersion.GetString(): string;
begin
   result := 'Microsoft ' + name + ' Version ' + sf(major) + '.' + sf(minor) +
      ' (Build: ' + sf(buildNumber) + ') ' + spName;
end;

function winTVersion.GetShortString(): string;
var
   s: string;

begin
   s := name + ' v' + sf(major) + '.' + sf(minor) + '.' + sf(buildNumber);
   if(spMajorVersion <> 0) then
      s := s + ' SP' + sf(spMajorVersion);

   result := s;
end;


function winTVersion.Check(maj: longint): Boolean;
begin
   result := Check(maj, 0);
end;

function winTVersion.Check(maj, min: longint): Boolean;
begin
   result := (major > maj) or
             ((major = maj) and (minor >= min));
end;

INITIALIZATION
   windowsVersion.name := 'Windows';
   windowsVersion.Initialize();
   
END.
