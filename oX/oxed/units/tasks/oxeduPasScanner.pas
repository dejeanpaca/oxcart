{
   oxeduPasScanner, pascal source scanner
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPasScanner;

INTERFACE

   USES
      uLog, sysutils, Classes, uStd, StringUtils,
      uBuild, uBuildFPCConfig,
      {pas}
      PScanner, PParser, PasTree,
      {oxed}
      oxeduPackageTypes, oxeduProject, oxeduProjectScanner;

TYPE
   oxedTPasScanResult = record
      IsUnit: boolean;
   end;

   { oxedTPasScanner }

   oxedTPasScanner = record
      {$IF FPC_FULLVERSION >= 030200}
      FpcCommandLine: TSimpleStringList;
      {$ELSE}
      FpcCommandLineString: StdString;
      {$ENDIF}

      function Scan(const fn: string): oxedTPasScanResult;
   end;

VAR
   oxedPasScanner: oxedTPasScanner;

IMPLEMENTATION

TYPE
   { TSimpleParseEngine }

   TSimpleParseEngine = class(TPasTreeContainer)
   public
      CurModule: TPasModule;

      function CreateElement(AClass: TPTreeElement; const AName: String;
         AParent: TPasElement; AVisibility: TPasMemberVisibility;
         const ASourceFilename: String; ASourceLinenumber: Integer): TPasElement; override;

      function FindElement(const {%H-}AName: String): TPasElement; override;
  end;

function TSimpleParseEngine.CreateElement(AClass: TPTreeElement; const AName: String;
   AParent: TPasElement; AVisibility: TPasMemberVisibility;
   const ASourceFilename: String; ASourceLinenumber: Integer): TPasElement;

begin
   Result := AClass.Create(AName, AParent);
   Result.Visibility := AVisibility;
   Result.SourceFilename := ASourceFilename;
   Result.SourceLinenumber := ASourceLinenumber;
end;

function TSimpleParseEngine.FindElement(const AName: String): TPasElement;
begin
   Result := nil;
end;

{ oxedTPasScanner }

{TODO: Utilize this eventually}
function oxedTPasScanner.Scan(const fn: string): oxedTPasScanResult;
var
   M: TPasModule;
   E: TPasTreeContainer;
   {$IF FPC_FULLVERSION >= 030200}
   commandLine: TAnsiStringArray;
   {$ENDIF}

begin
   {$IFDEF VER3_2}
   if(DefaultFileResolverClass = nil) then
      DefaultFileResolverClass := TFileResolver;
   {$ENDIF}

   ZeroOut(result, SizeOf(Result));

   E := TSimpleParseEngine.Create();

   try
      log.v('Parsing: ' + fn);

      {$IF FPC_FULLVERSION >= 030200}
      commandLine := FpcCommandLine.GetAnsiStrings();
      commandLine[0] := fn;
      M := ParseSource(E, commandLine, {$I %FPCTARGETOS%}, {$I %FPCTargetCPU}, []);
      {$ELSE}
      M := ParseSource(E, fn + oxedPasScanner.FpcCommandLineString, {$I %FPCTARGETOS%}, {$I %FPCTargetCPU}, []);
      {$ENDIF}

      if(M.InterfaceSection <> nil) then
         Result.IsUnit := true;

      FreeAndNil(M);
   except
      on E : Exception do begin
         log.e('Failed parsing: ' + fn + LineEnding + E.ToString);
      end;
   end;

   FreeAndNil(E);
end;

procedure onFile(var f: oxedTScannerFile);
var
   unitFile: oxedTPackageUnit;

begin
   unitFile.Name := ExtractFileNameNoExt(f.ProjectFileName);
   unitFile.Path := f.PackageFileName;

   if(f.Extension = '.pas') then begin
      f.Package^.AddUnit(unitFile)
   end else if(f.Extension = '.inc') then
      f.Package^.AddInclude(unitFile);
end;

procedure onStart();
var
   i: loopint;

begin
   oxedProject.MainPackage.DisposeList();

   for i := 0 to oxedProject.Packages.n - 1 do begin
      oxedProject.Packages.List[i].DisposeList();
   end;

   {get command line parameters with room for one more}
   {$IF FPC_FULLVERSION >= 030200}
   oxedPasScanner.FpcCommandLine := TBuildFPCConfiguration.GetFPCCommandLine(1);
   {$ELSE}
   oxedPasScanner.FpcCommandLineString := TBuildFPCConfiguration.GetFPCCommandLineAsString();
   {$ENDIF}
end;

INITIALIZATION
   oxedProjectScanner.OnStart.Add(@onStart);
   oxedProjectScanner.OnFile.Add(@onFile);

END.
