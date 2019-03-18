{
   oxeduPasScanner, pascal source scanner
   Copyright (C) 2018. Dejan Boras

   Started On:    20.01.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPasScanner;

INTERFACE

   USES
      uLog, sysutils, Classes, uStd, StringUtils, uBuild,
      PScanner, PParser, PasTree,
      oxeduProject, oxeduProjectScanner;

TYPE
   oxedTPasScanResult = record
      IsUnit: boolean;
   end;

   { oxedTPasScanner }

   oxedTPasScanner = record
      fpcCommandLine: string;

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

function oxedTPasScanner.Scan(const fn: string): oxedTPasScanResult;
var
   M: TPasModule;
   E: TPasTreeContainer;
   commandLine: string;

begin
   {$IFDEF VER3_2}
   if(DefaultFileResolverClass = nil) then
      DefaultFileResolverClass := TFileResolver;
   {$ENDIF}

   ZeroOut(result, SizeOf(Result));

   E := TSimpleParseEngine.Create;

   try
      log.v('Parsing: ' + fn);

      commandLine := fn + ' ' + fpcCommandLine;
      M := ParseSource(E, commandLine, {$I %FPCTARGETOS%}, {$I %FPCTargetCPU});

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
   unitFile: oxedTProjectUnit;
   pasResult: oxedTPasScanResult;

begin
   unitFile.Name := ExtractFileNameNoExt(f.FileName);
   unitFile.Path := f.FileName;

   if(f.Extension = '.pas') then begin
      pasResult := oxedPasScanner.Scan(f.FileName);

      if(pasResult.IsUnit) then
         oxedProject.Units.Add(unitFile);
   end else if(f.Extension = '.inc') then
      oxedProject.IncludeFiles.Add(unitFile);
end;

procedure onStart();
begin
   oxedPasScanner.fpcCommandLine := build.GetFPCCommandLine();
end;

INITIALIZATION
   oxedProjectScanner.OnStart.Add(@onStart);
   oxedProjectScanner.OnFile.Add(@onFile);

END.
