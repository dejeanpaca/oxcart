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
      {get current platform and settings as an fpc command line string}
      function GetFPCCommandLineAsString(): StdString;
      function GetFPCCommandLine(emptyBefore: loopint = 0; emptyAfter: loopint = 0): TStringArray;

      class function WriteFile(config: TStringArray; const fn: StdString): boolean; static;
      class function WriteFile(config: TSimpleStringList; const fn: StdString): boolean; static;
   end;

VAR
   BuildFPCConfiguration: TBuildFPCConfiguration;

IMPLEMENTATION

function TBuildFPCConfiguration.GetFPCCommandLineAsString(): StdString;
var
   args: TStringArray;

begin
   args := GetFPCCommandLine();

   Result := args.GetSingleString(' ');
end;

function TBuildFPCConfiguration.GetFPCCommandLine(emptyBefore: loopint = 0; emptyAfter: loopint = 0): TStringArray;
var
   count,
   i,
   index: loopint;
   arguments: TStringArray;

procedure AddArgument(const s: StdString);
begin
   arguments[index] := s;
   inc(index);
end;

begin
   count := emptyBefore + emptyAfter;

   inc(count, build.Units.n);
   inc(count, build.Includes.n);
   inc(count, build.Symbols.n);

   index := emptyBefore;

   arguments := nil;
   SetLength(arguments, count);

   if(build.Options.Rebuild) then
      AddArgument('-B');

   if(build.FPCOptions.UnitOutputDirectory <> '') then
      AddArgument('-FU' + build.FPCOptions.UnitOutputDirectory);

   for i := 0 to build.Units.n - 1 do begin
      AddArgument('-Fu' + build.Units.List[i]);
   end;

   for i := 0 to build.Includes.n - 1 do begin
      AddArgument('-Fi' + build.Includes.List[i]);
   end;

   for i := 0 to build.Symbols.n - 1 do begin
      AddArgument('-d' + build.Symbols.List[i]);
   end;

   Result := arguments;
end;

class function TBuildFPCConfiguration.WriteFile(config: TStringArray; const fn: StdString): boolean;
begin
   Result := FileUtils.WriteStrings(fn, config) >= 0;
end;

class function TBuildFPCConfiguration.WriteFile(config: TSimpleStringList;
   const fn: StdString): boolean;
begin
   Result := FileUtils.WriteStrings(fn, config.List, config.n) >= 0;
end;

END.
