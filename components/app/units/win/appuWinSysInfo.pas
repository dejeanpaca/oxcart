{
   Started On:		   09.10.2012.
}

{$MODE OBJFPC}{$H+}
UNIT appuWinSysInfo;

INTERFACE

	USES windows, windowsver, appuSysInfoBase;

IMPLEMENTATION

CONST
   MiBytes = 1024 * 1024;

procedure getInformation();
var
   si: SYSTEM_INFO;
   mem: MEMORYSTATUS;

begin
   {system name}
   appSI.SystemName := windowsVersion.GetString();

   {get system information from windows}
   GetSystemInfo(@si);

   {get the number of processors}
   appSI.nProcessors        := si.dwNumberOfProcessors;
   appSI.HasProcessorInfo   := true;

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

