{
   oxeduPasScanner, pascal source scanner
   Copyright (C) 2018. Dejan Boras

   Started On:    20.01.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPasScanner;

INTERFACE

   USES
      uLog, sysutils, Classes, uStd, uBuild, PParser, PasTree;

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

END.
