{
   Gathers information on linux systems
   Copyright (C) 2012. Dejan Boras

	TODO: Need to also skip unsupported sections in cpuinfo, and expand support for the hardware section.
   TODO: Maybe not cram android stuff in here
}

{$INCLUDE oxheader.inc}
UNIT appuLinuxSysInfo;

INTERFACE

	USES
      uStd, StringUtils, uFileUtils, ustrList,
      appuSysInfoBase;

procedure appLinuxSysInfoGetInformation();

IMPLEMENTATION

TYPE
   TProcessFileHandler = function(const key, value: string): boolean;

{processes a key/value file (/proc/ files)}
procedure processKeyColonValueFile(const fn: string; handler: TProcessFileHandler);
var
   f: text;
   s: string;
   key, value: string;

label
   process_end;

begin
   if(handler <> nil) then begin
      if(FileReset(f, fn) = 0) then begin
         repeat
            readln(f, s);

            if(ioerror() = 0) then begin
               key := LowerCase(CopyToDel(s, ':'));
               StripWhiteSpace(key);
               value := s;
               StripWhiteSpace(value);

               if(not handler(key, value)) then
                  goto process_end;
            end else
               break;
         until eof(f);
      end;

process_end:

      close(f);
      ioerror();
   end;
end;

{ cpu information }
function cpuHandler(const key, value: string): boolean;
var
   s: string;
   ivalue: int64;
   fvalue: single;
   code: loopint;
   idx: loopint = -1;

function prepare(): boolean;
begin
   s := value;
   s := CopyToDel(s, ' ');
   StripWhiteSpace(s);

   val(s, ivalue, code);
   if(code <> 0) then
      ivalue := 0;

   result := code = 0;
end;

function preparefloat(): boolean;
begin
   s := value;
   s := CopyToDel(s, ' ');
   StripWhiteSpace(s);

   val(s, fvalue, code);
   if(code <> 0) then
      fvalue := 0;

   Result := code = 0;
end;

begin
   result := true;
   idx := length(appSI.Processors) - 1;

   ivalue := 0;
   fvalue := 0;
   code := 0;

   {processor identifier (could be a number or name)}
   if(key = 'processor') then begin
      idx := appSI.AddProcessor();

      {if it's not a number then it's the cpu name}
      if(not prepare()) then
         appSI.Processors[idx - 1].Name := value;

      appSI.HasProcessorInfo := true;
      exit;
   end;

   if(idx > -1) then begin
      if(key = 'vendor_id') then begin
         appSI.Processors[idx].Vendor := value;
      end else if(key = 'model name') then begin
         appSI.Processors[idx].ModelName := value;
      end else if(key = 'cpu family') then begin
         prepare();
         appSI.Processors[idx].Family := ivalue;
      end else if(key = 'model') then begin
         prepare();
         appSI.Processors[idx].Model := ivalue;
      end else if(key = 'stepping') then begin
         prepare();
         appSI.Processors[idx].Stepping := ivalue;
      end else if(key = 'cores') then begin
         prepare();
         appSI.Processors[idx].Cores := ivalue;
      end else if(key = 'cache size') then begin
         prepare();
         appSI.Processors[idx].CacheSize := ivalue;
      end else if(key = 'cpu mhz') then begin
         preparefloat();
         appSI.Processors[idx].Freq := fvalue;
      end else if(key = 'bogomips') then begin
         preparefloat();
         appSI.Processors[idx].Bogomips := fvalue;
      end else if(key = 'cpu implementer') then
         appSI.Processors[idx].Implementer := value
      else if(key = 'cpu architecture') then
         appSI.Processors[idx].Architecture := value
      else if(key = 'cpu variant') then
         appSI.Processors[idx].Variant := value
      else if(key = 'cpu part') then
         appSI.Processors[idx].Part := value
      else if(key = 'cpu revision') then
         appSI.Processors[idx].Revision := value
      else if(key = 'features') or (key = 'flags') then begin
         strList.ConvertSpaceSeparated(value, appSI.Processors[idx].Features, appSI.Processors[idx].nFeatures);
      end;
   end;
end;

{ memory information }
function memoryHandler(const key, value: string): boolean;
var
  s: string;
  ivalue: uint64;
  code: longint;

procedure prepare();
begin
   s := value;
   s := CopyToDel(s, ' ');
   StripWhiteSpace(s);

   val(s, ivalue, code);
end;

begin
   result := true;

   code := 0;
   ivalue := 0;
   prepare();

   if(code = 0) then begin
      {physical memory}
      if(key = 'memtotal') then begin
         appSI.Memory.Physical := ivalue * 1024;
      end else if(key = 'memfree') then begin
         appSI.Memory.Available.Physical := ivalue * 1024;
      {swap (virtual) memory}
      end else if(key = 'swaptotal') then begin
         appSI.Memory.Virt := ivalue * 1024;
      end else if(key = 'swapfree') then begin
        appSI.Memory.Available.Virt := ivalue * 1024;
      end;
   end;

   appSI.hasMemoryInfo := true;
end;

{$IFNDEF ANDROID}
CONST
   nPlatforms = 3;

   platformNames: array[0..nPlatforms-1] of string = (
      'debian-version',
      'redhat-release',
      'slackware-version'
   );
{$ENDIF}

procedure appLinuxSysInfoGetInformation();
var
   release: StdString = '';
   ok: longint;
   {$IFNDEF ANDROID}
   i: longint;
   {$ENDIF}

begin
   {$IFNDEF ANDROID}
   appSI.System.Name := 'Linux';
   {$ELSE}
   appSI.System.Name := 'Android';
   {$ENDIF}

   {get platform names}
   {$IFNDEF ANDROID}
   for i := 0 to (nPlatforms - 1) do begin
      ok := FileUtils.LoadStringPipe('/etc/' + platformNames[i], release);

      if(ok > 0) then begin
         StringUtils.StripEndLine(release);
         appSI.System.Name := release;
         break;
      end;
   end;
   {$ENDIF}

   {get kernel version}
   ok := FileUtils.LoadStringPipe('/proc/version', release);

   if(ok > 0) then begin
      StringUtils.StripEndLine(release);
      appSI.System.KernelVersion := release;
   end;

   {get memory information}
   processKeyColonValueFile('/proc/meminfo', @memoryHandler);

   {get processor information}
   processKeyColonValueFile('/proc/cpuinfo', @cpuHandler);
   appSI.nProcessors := length(appSI.Processors);
end;

INITIALIZATION
   appSI.getInformation := @appLinuxSysInfoGetInformation;

END.
