{
   uBuildFPCConfig
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uBuildFPCConfig;

INTERFACE

   USES
      uStd, StringUtils, uFileUtils,
      uBuild;

TYPE

   { TBuildFPCConfiguration }

   TBuildFPCConfiguration = record
      class function GenerateFile(config: TStringArray; const fn: StdString): boolean; static;
      class function GenerateFile(config: TSimpleStringList; const fn: StdString): boolean; static;
   end;

IMPLEMENTATION

class function TBuildFPCConfiguration.GenerateFile(config: TStringArray; const fn: StdString): boolean;
begin
   Result := FileUtils.WriteStrings(fn, config) >= 0;
end;

class function TBuildFPCConfiguration.GenerateFile(config: TSimpleStringList;
   const fn: StdString): boolean;
begin
   Result := GenerateFile(config.List, fn);
end;

END.
