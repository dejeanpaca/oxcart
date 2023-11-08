{
   appuSysInfo, provides system information
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuSysInfo;

INTERFACE

   USES
   uLog, StringUtils, ustrList,
   uApp, appuSysInfoBase,
   {$IFDEF WINDOWS}appuWinSysInfo,{$ENDIF}
   {$IFDEF UNIX}{$IF not defined(ANDROID) and not defined(DARWIN)}appuLinuxSysInfo,{$ENDIF}{$ENDIF}
   {$IFDEF ANDROID}appuAndroidSysInfo,{$ENDIF}
   oxuRunRoutines;

TYPE
   appTSystemInformation = record
      skipInit: boolean;

      {acquires information about the system}
      procedure Get();

      {logs the system information}
      procedure WriteLog();
   end;

VAR
   appSystemInformation: appTSystemInformation;

IMPLEMENTATION

VAR
   GotSystemInfo: boolean = false;
   LoggedSystemInfo: boolean = false;

{acquires information about the system}
procedure appTSystemInformation.Get();
begin
   if(not GotSystemInfo) then begin
      if(appSI.getInformation <> nil) then
         appSI.getInformation();


      GotSystemInfo := true;
   end;
end;

procedure logString(const title, what: string);
begin
   if(what <> '') then
      log.i(title + ': ' + what);
end;

procedure logInt(const title: string; what: longint);
begin
   if(what <> 0) then
      log.i(title + ': ' + sf(what));
end;

procedure appTSystemInformation.WriteLog();
var
   i,
   startCPU,
   currentCPU: longint;
   s: string;

procedure logCPU(var processor: appTProcessorInformation);
begin
   with processor do begin
      logString('Name', Name);
      logString('Implementer', Implementer);
      logString('Architecture', Architecture);
      logString('Variant', Variant);
      logString('Part', Part);
      logString('Revision', Revision);
      logString('Vendor', Vendor);
      logString('Model name', ModelName);

      logInt('Family', Family);
      logInt('Model', Model);
      logInt('Stepping', Stepping);
      logInt('Cores', Cores);
      logString('Flags', Flags);

      if(freq <> 0) then
         logString('Frequency', sf(Freq, 2) + ' MHz');

      if(cacheSize <> 0) then
         logString('Cache', sf(CacheSize) + ' kB');

      if(bogomips <> 0) then
         log.i('Bogomips: ' + sf(Bogomips, 2));

      if(nFeatures > 0) then begin
         strList.ConvertToSpaceSeparated(Features, s);
         logString('Features', s);
      end;
   end;
end;

procedure logCPURange(s, e: longint);
begin
   if(s = e) then
      log.Enter('CPU ' + sf(s + 1))
   else
      log.Collapsed('CPU ' + sf(s + 1) + ' - ' + sf(e + 1));

   logCPU(appSI.Processors[s]);

   log.Leave();
end;

procedure logMemory(const name: string; mem: uint64);
begin
   if(mem > 0) then
      log.i(name + ' Size: ' + sf(mem div 1024 div 1024) +
         ' MiB (' + sf(mem) +
         '), available: ' + sf(mem div 1024 div 1024) + ' MiB');
end;

begin
   if(not LoggedSystemInfo = true) and (GotSystemInfo) then begin
      log.Collapsed('System Information');
      logString('System', appSI.SystemName);
      logString('Device', appSI.SystemDeviceName);

      logString('Kernel', appSI.KernelVersion);

      if(appSI.hasProcessorInfo) then begin
         log.Enter('CPU');
         log.i('Number of (cores):    ' + sf(appSI.nProcessors));

         if(length(appSI.Processors) > 0) then begin
            currentCPU := 0;
            startCPU := 0;

            {group log processors with same characteristics}
            for i := currentCPU to appSI.nProcessors do begin
               if(i = appSI.nProcessors) then begin
                  logCPURange(startCPU, appSI.nProcessors - 1);
                  break;
               end;

               if(appSI.Processors[i].Model = appSI.Processors[startCPU].Model) and (
                  appSI.Processors[i].ModelName = appSI.Processors[startCPU].ModelName) then begin
                     currentCPU := i;
               end else begin
                  logCPURange(startCPU, currentCPU);
                  startCPU := currentCPU + 1;

                  if(startCPU >= appSI.nProcessors) then
                     break;
               end;
            end;
         end;

         log.Leave();
      end;

      if(appSI.hasMemoryInfo) then begin
         log.Enter('Memory');

         logMemory('Physical', appSI.Memory.Physical);
         logMemory('Virtual', appSI.Memory.Virt);
         logMemory('Page', appSI.Memory.Page);

         log.Leave();
      end;

      log.Leave();
      LoggedSystemInfo := true;
   end;
end;

procedure Initialize();
begin
   if(not appSystemInformation.skipInit) then begin
      appSystemInformation.Get();

      appSystemInformation.WriteLog();
   end;
end;

INITIALIZATION
   {set defaults}
   appSI.systemName := 'unknown';

   app.InitializationProcs.Add('systeminformation', @Initialize);

END.
