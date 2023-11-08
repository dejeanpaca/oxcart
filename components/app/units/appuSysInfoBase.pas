{
   appuSysInfoBase, basic functionality for system information
   Copyright (C) 2011. Dejan Boras

   Started On:    09.10.2012.
}

{$INCLUDE oxdefines.inc}
UNIT appuSysInfoBase;

INTERFACE

   USES uStd, uBinarySize;

TYPE
   {contains information about a single processor}
   appPProcessorInformation = ^appTProcessorInformation;
   appTProcessorInformation = record
      Name,
      Vendor,
      ModelName,
      Flags,
      Implementer,
      Architecture,
      Variant,
      Part,
      Revision: string;
      Family,
      Model,
      Stepping,
      Cores: longint;
      Bogomips,
      Freq: single;
      CacheSize: longint;

      Features: array of string;
      nFeatures: longint;
   end;

   {contains information about the system}
   appPSystemInformation = ^appTSystemInformation;

   { appTSystemInformation }

   appTSystemInformation = record
      SystemName,
      SystemDeviceName,
      KernelVersion: string;

      nProcessors: longint;
	   Processors: array of appTProcessorInformation;

      Memory: record
         Physical,
         Virt,
         Page: uint64;
         Available: record
            Physical,
            Virt,
            Page: uint64;
         end;
      end;

      HasProcessorInfo,
      HasMemoryInfo: boolean;

      GetInformation: TProcedure;

      {adds a new processor descriptor to the system information record}
      function AddProcessor(): longint;
      {get processor name}
      function GetProcessorName(): string;
      {get processor vendor}
      function GetProcessorVendor(): string;
      {get processor modeč}
      function GetProcessorModel(): string;
      {get processor name}
      function GetMemorySize(units: longint = SI_BINARY_SIZE_GB; adjust: boolean = true): string;
   end;

VAR
   {all system information is stored into this variable}
   appSI: appTSystemInformation;


IMPLEMENTATION

function appTSystemInformation.AddProcessor(): longint;
var
   n: longint;

begin
   n := Length(Processors);
   n := n + 1;

   try
      SetLength(Processors, n);

      Result := n;
   except
      Result := -1;
   end;
end;

function appTSystemInformation.GetProcessorName(): string;
begin
   if(Length(Processors) > 0) then begin
      if(Processors[0].Name <> '') then
         exit(Processors[0].Name)
      else
         exit(Processors[0].ModelName);
   end;

   Result := 'Unknown';
end;

function appTSystemInformation.GetProcessorVendor(): string;
begin
   if(Length(Processors) > 0) and (Processors[0].Vendor <> '') then
      exit(Processors[0].Vendor);

   Result := '';
end;

function appTSystemInformation.GetProcessorModel(): string;
begin
   if(Length(Processors) > 0) and (Processors[0].ModelName <> '') then
      exit(Processors[0].ModelName);

   Result := 'Unknown';
end;

function appTSystemInformation.GetMemorySize(units: longint; adjust: boolean): string;
begin
   if(adjust) then
      Result := getiecByteSizeHumanReadable(Memory.Physical)
   else
      Result := getiecBinarySizeSuffixString(Memory.Physical, units);
end;

INITIALIZATION
   ZeroOut(appSI, SizeOf(appSI));

END.
