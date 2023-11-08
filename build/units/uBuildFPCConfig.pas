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
      Config: TSimpleStringList;

      class procedure Initialize(out buildConfig: TBuildFPCConfiguration); static;

      {get fpc command line options as strings}
      class function GetFPCCommandLineAsString(): StdString; static;
      {get fpc command line options as strings}
      class function GetFPCCommandLine(emptyBefore: loopint = 0; emptyAfter: loopint = 0): TStringArray; static;
      {get fpc command line options for use with a config file}
      class function GetFPCCommandLineForConfig(): TStringArray; static;

      {add a new config line}
      procedure Add(const s: StdString); inline;
      {construct a config from build configuration}
      procedure Construct();

      procedure FromList(const list: TStringArray; const prefix: StdString; count: loopint = -1);
      procedure IncludeUnits(const list: TStringArray; count: loopint = -1);
      procedure AddIncludes(const list: TStringArray; count: loopint = -1);
      procedure AddSymbols(const list: TStringArray; count: loopint = -1);

      function WriteFile(const fn: StdString): boolean;
      class function WriteFile(what: TStringArray; const fn: StdString): boolean; static;
      class function WriteFile(what: TSimpleStringList; const fn: StdString): boolean; static;
   end;

IMPLEMENTATION

class procedure TBuildFPCConfiguration.Initialize(out buildConfig: TBuildFPCConfiguration);
begin
   ZeroOut(buildConfig, SizeOf(buildConfig));
   TSimpleStringList.InitializeValues(buildConfig.Config, 128);
end;

class function TBuildFPCConfiguration.GetFPCCommandLineAsString(): StdString;
var
   args: TStringArray;

begin
   args := GetFPCCommandLine();

   Result := args.GetSingleString(' ');
end;

class function TBuildFPCConfiguration.GetFPCCommandLine(emptyBefore: loopint = 0; emptyAfter: loopint = 0): TStringArray;
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

   if(build.TargetOS <> '') then
      AddArgument('-T' + build.TargetOS);

   if(build.TargetCPU <> '') then
      AddArgument('-p' + build.TargetCPU);

   if(build.IncludeDebugInfo) then
      AddArgument('-g');

   Result := arguments;
end;

class function TBuildFPCConfiguration.GetFPCCommandLineForConfig(): TStringArray;
var
   index: loopint;

procedure AddArgument(const s: StdString);
begin
   inc(index);
   SetLength(Result, index);
   Result[index - 1] := s;
end;

begin
   Result := nil;
   index := 0;

   if(build.Options.Rebuild) then
      AddArgument('-B');

   if(build.FPCOptions.DontUseDefaultConfig) then
      AddArgument('-n');

   if(build.FPCOptions.UseConfig <> '') then
      AddArgument('@' + build.FPCOptions.UseConfig);
end;

procedure TBuildFPCConfiguration.Add(const s: StdString);
begin
   Config.Add(s);
end;

procedure TBuildFPCConfiguration.Construct();

begin
   Config.Dispose();

   add('# unit output directory');

   if(build.FPCOptions.UnitOutputDirectory <> '') then
      add('-FU' + build.FPCOptions.UnitOutputDirectory);

   IncludeUnits(build.Units.List, build.Units.n);
   AddIncludes(build.Includes.List, build.Includes.n);
   AddSymbols(build.Symbols.List, build.Includes.n);

   if(build.TargetOS <> '') then begin
      add('# target OS');
      add('-T' + build.TargetOS);
   end;

   if(build.TargetCPU <> '') then begin
      add('# target CPU');
      add('-p' + build.TargetCPU);
   end;

   if(build.IncludeDebugInfo) then begin
      add('# include debug info');
      add('-g');
   end;
end;

procedure TBuildFPCConfiguration.FromList(const list: TStringArray; const prefix: StdString; count: loopint);
var
   i: loopint;

begin
   if(count > High(list) + 1) then
      count := High(list)
   else
      count := count - 1;

   if(count >= 0) then begin
      for i := 0 to count do begin
         Config.Add(prefix + list[i]);
      end;
   end;
end;

procedure TBuildFPCConfiguration.IncludeUnits(const list: TStringArray; count: loopint);
begin
   if(count > 0) then begin
      Config.Add('# units');
      FromList(list, '-Fu', count);
   end;
end;

procedure TBuildFPCConfiguration.AddIncludes(const list: TStringArray; count: loopint);
begin
   if(count > 0) then begin
      Config.Add('# includes');
      FromList(list, '-Fi', count);
   end;
end;

procedure TBuildFPCConfiguration.AddSymbols(const list: TStringArray; count: loopint);
begin
   if(count > 0) then begin
      Config.Add('# symbols');
      FromList(list, '-d', count);
   end;
end;

function TBuildFPCConfiguration.WriteFile(const fn: StdString): boolean;
begin
   Result := WriteFile(Config, fn);
end;

class function TBuildFPCConfiguration.WriteFile(what: TStringArray; const fn: StdString): boolean;
begin
   Result := FileUtils.WriteStrings(fn, what) >= 0;
end;

class function TBuildFPCConfiguration.WriteFile(what: TSimpleStringList; const fn: StdString): boolean;
begin
   Result := FileUtils.WriteStrings(fn, what.List, what.n) >= 0;
end;

END.
