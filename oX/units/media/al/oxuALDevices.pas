{
   oxuALDevices, al device management
   Copyright (C) 2017. Dejan Boras

   Started On:    11.09.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuALDevices;

INTERFACE

   USES
     uStd, uLog, StringUtils,
     {dal}
     {$IFNDEF OX_LIBRARY}
     ctypes, ustrList,
     {$ENDIF}
     openal,
     {ox}
     oxuAL, oxuALExtensions;

TYPE
   oxPALDevicesGlobal = ^oxTALDevicesGlobal;

   { oxTALDevicesGlobal }

   oxTALDevicesGlobal = record
      Preferred,
      {currently open device name}
      DeviceSpecifier: string;
      {device name}
      Device: PALCdevice;

      DeviceExtensions: oxTALExtensions;
      Devices: TpShortStringArray;
      nDevices: longint;
      sDevices: pointer;

      {get a normalized device name}
      function GetDeviceName(const devName: string): string;

      function OpenDevice(const devName: string): boolean;
      function OpenDefault(): boolean;
      function OpenPreferred(): boolean;
      function Open(): boolean;

      function GetDevices(): boolean;
      function Find(const devName: string): string;

      function Close(): boolean;

      procedure DeInitialize();
   end;

VAR
   oxalDevices: oxTALDevicesGlobal;

IMPLEMENTATION


{ oxTALDevicesGlobal }

function oxTALDevicesGlobal.GetDeviceName(const devName: string): string;
begin
   if(devName <> '') then
      Result := devName
   else
      Result := 'default';
end;

function oxTALDevicesGlobal.OpenDevice(const devName: string): boolean;
{$IFNDEF OX_LIBRARY}
var
   devSpec: UTF8String;
{$ENDIF}

begin
   {$IFNDEF OX_LIBRARY}
   if(devName <> '') then begin
      devSpec := UTF8Encode(devName);
      Device := alcOpenDevice(pcchar(pchar(devSpec)))
   end else
      Device := alcOpenDevice(nil);

   Result := oxal.cGetError(Device) = AL_NO_ERROR;

   if(Result) then begin
      DeviceSpecifier := devName;
      log.i('al > Opened device: ' + GetDeviceName(devName))
   end else begin
      DeviceSpecifier := 'error';
      log.e('al > Failed to open device: ' + GetDeviceName(devName));
   end;
   {$ELSE}
   log.w('Should not try to open an AL device (' + devName + ') in library mode');
   exit(true);
   {$ENDIF}
end;

function oxTALDevicesGlobal.OpenDefault: boolean;
begin
   result := OpenDevice('');
end;

function oxTALDevicesGlobal.OpenPreferred: boolean;
{$IFNDEF OX_LIBRARY}
var
   found: string;
{$ENDIF}

begin
   {$IFNDEF OX_LIBRARY}
   {open preferred device if possible}
   if(Preferred <> '') then begin
      found := Find(Preferred);

      if(found <> '') then begin
         Close();

         Result := OpenDevice(found);
         if(Result) then
            log.i('al > Opened preferred device: ' + found)
         else
            log.e('al > Failed to open preferred device: ' + found);

         exit(Result);
      end else
         log.w('Preferred device ' + Preferred + ' not found');
   end;

   Result := false;
   {$ELSE}
   log.w('Should not try to open preferred AL device in library mode');
   exit(true);
   {$ENDIF}
end;

function oxTALDevicesGlobal.Open: boolean;
begin
   result := OpenDefault();
end;

function oxTALDevicesGlobal.GetDevices: boolean;
{$IFNDEF OX_LIBRARY}
var
   enumerationPresent: boolean;
   deviceList: PChar;
   i: loopint;
   dev: string;
{$ENDIF}

begin
   {$IFNDEF OX_LIBRARY}
   enumerationPresent := alcIsExtensionPresent(nil, pcchar(pchar('ALC_ENUMERATION_EXT')));
   if(enumerationPresent) then begin
      deviceList := pchar(alcGetString(nil, ALC_DEVICE_SPECIFIER));

      if(strList.ConvertNullSeparated(deviceList, sDevices, Devices, nDevices)  = 0) then begin
         log.Enter('Devices (' + sf(nDevices) + ')');

         for i := 0 to nDevices - 1 do begin
            dev := sf(i);

            AddLeadingPadding(dev, '0', 3);

            log.i('(' + dev + ') ' + Devices[i]^);
         end;

         log.Leave();
      end;

      Result := True;
   end else begin
      log.w('ALC_ENUMERATION_EXT not present');
      Result := false;
   end;
   {$ELSE}
   log.w('Should not try to get AL devices again in library mode');
   exit(true);
   {$ENDIF}
end;

function oxTALDevicesGlobal.Find(const devName: string): string;
var
   i: loopint;
   lc: string;

begin
   lc := lowercase(devName);

   for i := 0 to nDevices - 1 do begin
      if(lc = lowercase(Devices[i]^)) then begin
         exit(Devices[i]^);
      end;
   end;

   Result := '';
end;

function oxTALDevicesGlobal.Close: boolean;
begin
   {$IFNDEF OX_LIBRARY}
   Result := false;

   if(Device <> nil) then begin
      Result := alcCloseDevice(Device);

      if(Result) then begin
         Result := true;
         log.i('Closed device: ' + GetDeviceName(DeviceSpecifier));
      end else begin
         oxal.cGetError();
         log.e('Failed to close device: ' + GetDeviceName(DeviceSpecifier));
      end;

      Device := nil;
   end else
      Result := True;
   {$ELSE}
   log.w('Should not try to close AL device in library mode');
   exit(true);
   {$ENDIF}
end;

procedure oxTALDevicesGlobal.DeInitialize;
begin
   {$IFNDEF OX_LIBRARY}
   oxalDevices.DeviceExtensions.DisposeExtensions();

   XFreeMem(sDevices);
   if(Devices <> nil) then
      SetLength(Devices, 0);
   {$ENDIF}
end;

INITIALIZATION
   oxalDevices.Preferred := 'OpenAL Soft';

END.

