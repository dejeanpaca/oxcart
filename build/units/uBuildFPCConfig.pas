{
   uBuildFPCConfig
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uBuildFPCConfig;

INTERFACE

   USES
      uStd, uFileUtils,
      uBuild;

TYPE
   TBuildFPCConfiguration = record
      procedure GenerateFile(const fn: StdString);
   end;

IMPLEMENTATION

procedure TBuildFPCConfiguration.GenerateFile(const fn: StdString);
var
   cfg: TAppendableString;

begin
   FileUtils.WriteString(fn, cfg);
end;

END.
