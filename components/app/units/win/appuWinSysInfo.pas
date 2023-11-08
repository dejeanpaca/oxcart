{
   Started On:		   09.10.2012.
}

{$INCLUDE oxheader.inc}
UNIT appuWinSysInfo;

INTERFACE

	USES
     windows, windowsver, windowsutils,
     uStd, StringUtils,
     appuSysInfoBase;

IMPLEMENTATION

CONST
   MiBytes = 1024 * 1024;

procedure getInformation();
var
   i: loopint;
   si: SYSTEM_INFO;
   mem: MEMORYSTATUS;
   proc: appTProcessorInformation;

   regKey: windows.HKEY;
   dwMHZ: windows.DWORD;

   cpuName,
   cpuVendor,
   cpuIdentifier,
   previousCpuName,
   previousCpuVendor,
   previousCpuIdentifier: string;

begin
   {system name}
   appSI.SystemName := windowsVersion.GetString();

   {get system information from windows}
   GetSystemInfo(@si);

   dwMHZ := 0;
   cpuName := '';
   cpuVendor := '';

   {get the number of processors}
   appSI.nProcessors        := si.dwNumberOfProcessors;
   appSI.HasProcessorInfo   := true;

   previousCpuName := '';
   previousCpuVendor := '';
   previousCpuIdentifier := '';

   for i := 0 to appSI.nProcessors - 1 do begin;
      regKey := windowsutils.OpenRegistryKey(HKEY_LOCAL_MACHINE, 'HARDWARE\DESCRIPTION\System\CentralProcessor\0');

      appSI.AddProcessor();
      proc := appSI.Processors[i];

      cpuName := '';
      cpuVendor := '';
      dwMHZ := 0;

      if(regKey <> 0) then begin
         dwMHZ := GetRegistryDWord(regKey, '~MHz');

         cpuName := windowsutils.GetRegistryString(regKey, 'ProcessorNameString');
         cpuVendor := windowsutils.GetRegistryString(regKey, 'VendorIdentifier');
         cpuIdentifier := windowsutils.GetRegistryString(regKey, 'Identifier');

         {we do this so we use the same string reference, without having unneeded copies}
         if(cpuName = previousCpuName) then
            cpuName := previousCpuName;

         if(cpuVendor = previousCpuVendor) then
            cpuVendor := previousCpuVendor;

         if(cpuIdentifier = previousCpuIdentifier) then
            cpuIdentifier := previousCpuIdentifier;

         previousCpuName := cpuName;
         previousCpuVendor := cpuVendor;
         previousCpuIdentifier := cpuIdentifier;

         windows.RegCloseKey(regKey);
      end;

      proc.Freq := dwMHZ;
      proc.Name := cpuName;
      proc.ModelName := cpuIdentifier;
      proc.Vendor := cpuVendor;
      proc.Model := hi(si.wProcessorRevision);
      proc.Revision := sf(lo(si.wProcessorRevision));

      appSI.Processors[i] := proc;
   end;

   {get information about memory}
   GlobalMemoryStatus(@mem);
   appSI.Memory.Physical           := mem.dwTotalPhys;
   appSI.Memory.Available.physical := mem.dwAvailPhys;
   appSI.Memory.Virt               := mem.dwTotalVirtual;
   appSI.Memory.Available.virt     := mem.dwAvailVirtual;
   appSI.Memory.Page               := mem.dwTotalPageFile;
   appSI.Memory.Available.page     := mem.dwAvailPageFile;

   {correct values}
   appSI.Memory.Physical := appSI.Memory.Physical + (MiBytes - (appSI.Memory.Physical mod MiBytes));
   appSI.Memory.Virt     := appSI.Memory.Virt + (MiBytes - (appSI.Memory.Virt mod MiBytes));
   appSI.Memory.Page     := appSI.Memory.Page + (MiBytes - (appSI.Memory.Page mod MiBytes));

   appSI.HasMemoryInfo := true;
end;

INITIALIZATION
   appSI.GetInformation := @getInformation;

END.

