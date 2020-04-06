{
   uLPIBuild, builds from LPI files
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uLPIBuild;

INTERFACE

TYPE
   { TLPIBuild }

   TLPIBuild = record
      function BuildFromPas(const source: StdString): boolean;
      function BuildFromPas(const source: StdString; var context: TLPIContext): boolean;
   end;

VAR
   lpibuild: TLPIBuild;

IMPLEMENTATION

{ TLPIBuild }

function TLPIBuild.BuildFromPas(const source: StdString): boolean;
var
   context: TLPIContext;

begin
   lpi.Initialize(context);

   Result := BuildFromPas(source, context);
end;

function TLPIBuild.BuildFromPas(const source: StdString; var context: TLPIContext): boolean;
var
   fn: StdString;

begin
   if(not lpi.Initialized) then
      exit(false);

   if(FileUtils.Exists(source) > 0) then
      fn := source
   else if(FileUtils.Exists(source + '.pas') > 0) then
      fn := source + '.pas'
   else if(FileUtils.Exists(source + '.pp') > 0) then
      fn := source + '.pp'
   else if(FileUtils.Exists(source + '.lpr') > 0) then
      fn := source + '.lpr'
   else begin
      log.w('Cannot build from source because no files found for: ' + source);
      BuildExec.Output.Success := false;
      exit(false);
   end;

   lpi.Create(fn, @context);

   if(lpi.Error = 0) then
      BuildExec.Laz(lpi.OutFileName);

   Result := BuildExec.Output.Success;
end;

END.
