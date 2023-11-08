{
   uLPI, manipulates LPI files
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uLPI;

INTERFACE

   USES
      sysutils, uStd, uError, uLog, uFileUtils, StringUtils, uSimpleParser,
      uBuild,
      {LazUtils}
      uLazXMLUtils, Laz2_DOM, laz2_XMLRead, laz2_XMLWrite;

CONST
   eLPI_NONE                        = 0;
   eLPI_NOT_INITIALIZED             = 1;
   eLPI_FAILED_TO_LOAD_TEMPLATE     = 2;
   eLPI_FAILED_TO_LOAD              = 3;
   eLPI_FAILED_TO_WRITE             = 4;

TYPE
   TLPIMode = (
      lpiMODE_NONE,
      lpiMODE_CREATE,
      lpiMODE_UPDATE,
      lpiMODE_TEST
   );

   PLPITemplate = ^TLPITemplate;
   PLPIFile = ^TLPIFile;
   PLPIContext = ^TLPIContext;

   { TLLPITemplate }

   TLPITemplate = record
      Path,
      Name: StdString;

      procedure Setup();
   end;

   { TLPIFile }

   TLPIFile = record
      MinimumVersion,
      LPIVersion: loopint;
      Mode: TLPIMode;

      {source file from which the lpi is created, or the main unit when an lpi is loaded}
      Source,
      Path: StdString;
      xmlDoc: TXMLDocument;
      Error: longint;

      project: record
         root,
         version: TDOMNode;

         general: record
            root,
            title: TDOMNode;
         end;

         versionInfo: TDOMNode;

         units: record
            root,
            unit0,
            unit0Filename: TDOMNode;
         end;

         requiredPackages: record
            root: TDOMNode;
         end;
      end;

      compiler: record
         root,
         version: TDOMNode;

         searchPaths: record
            root,
            includeFiles,
            otherUnits,
            unitOutputDirectory: TDOMNode;
         end;

         target,
         targetFilename: TDOMNode;

         applyConventions: boolean;

         codeGeneration: record
            root: TDOMNode;
            checks: record
               root,
               io,
               range,
               overflow,
               stack: TDOMNode;
            end;
         end;

         Linking: record
            root: TDOMNode;
            Debugging: record
               root,
               UseExternalDebugSymbols: TDOMNode;
            end;
         end;

         other: record
            root,
            customOptions: TDOMNode;
         end;
      end;

      SourceData: record
         PackageList: TSimpleStringList;
         Symbols: TSimpleStringList;
      end;

      procedure Initialize();

      procedure Update();
      procedure ApplyValues();

      procedure Load(const newPath: StdString);
      procedure Save(const newPath: StdString = '');
      {extract information from source (like required packages)}
      procedure ParseSource();

      procedure AddCustomOption(const option: StdString);
      procedure AddUnitPath(const newPath: StdString);
      procedure AddIncludePath(const newPath: StdString);
      procedure SetUnitOutputDirectory(const newPath: StdString);
      procedure SetTitle(const newTitle: StdString);
      procedure AddRequiredPackage(const packageName: StdString);
      procedure AddSymbol(const symbol: StdString);
      procedure CreatePackagesSection();

      class procedure SetValue(node: TDOMNode; const value: StdString); static;
      class function GetValue(node: TDOMNode): StdString; static;

      procedure Destroy();

      procedure QuitOnError(errorCode: longint);
   end;

   { TLPIContext }

   TLPIContext = record
      Target: StdString;
      Loaded: procedure(var f: TLPIFile);
   end;

   { TLPIGlobal }

   TLPIGlobal = record
      {is lpi initialized}
      Initialized,
      {log verbose}
      Verbose: boolean;
      {last error}
      Error: longint;

      {output filename}
      OutFileName: StdString;

      {template information}
      Template: TLPITemplate;

      procedure Initialize();
      procedure DeInitialize();
      function IsInitialized(): boolean;

      procedure Create(const source: StdString; context: PLPIContext = nil; testMode: boolean = false);
      procedure Update(const lpiFile: StdString; context: PLPIContext = nil);
      {runs Create() in test mode}
      procedure Test(const source: StdString; context: PLPIContext = nil);

      procedure Initialize(out f: TLPIFile);
      procedure Initialize(out context: TLPIContext);
   end;

VAR
   lpi: TLPIGlobal;

IMPLEMENTATION

{ TLPIFile }

procedure TLPIFile.Initialize();
begin
   compiler.applyConventions := true;
   MinimumVersion := 11;

   SourceData.PackageList.InitializeValues(SourceData.PackageList, 128);
   SourceData.Symbols.InitializeValues(SourceData.Symbols, 128);
end;

procedure TLPIFile.Update();
begin
   try
      project.root := xmlDoc.FirstChild.FindNode('ProjectOptions');
      if(project.root <> nil) then begin
         project.version := project.root.FindNode('Version');

         project.general.root := project.root.FindNode('General');

         if(project.general.root <> nil) then
            project.general.title := project.general.root.FindNode('Title');

         project.units.root := project.root.FindNode('Units');

         if(project.units.root <> nil) then begin
            project.units.unit0 := project.units.root.FindNode('Unit0');

            if(project.units.unit0 <> nil) then
               project.units.unit0Filename := project.units.unit0.FindNode('Filename');
         end;

         project.versionInfo := project.root.FindNode('VersionInfo');
      end;

      compiler.root := xmlDoc.FirstChild.FindNode('CompilerOptions');

      if(compiler.root <> nil) then begin
         compiler.version := compiler.root.FindNode('Version');
         compiler.target := compiler.root.FindNode('Target');

         if(compiler.target <> nil) then begin
            compiler.targetFilename := compiler.target.FindNode('Filename');

            if(compiler.targetFilename <> nil) then
               compiler.applyConventions := compiler.targetFilename.GetAttributeBool('ApplyConventions', true);
         end;

         compiler.searchPaths.root := compiler.root.FindNode('SearchPaths');

         if(compiler.searchPaths.root <> nil) then begin
            compiler.searchPaths.includeFiles := compiler.searchPaths.root.FindNode('IncludeFiles');
            compiler.searchPaths.otherUnits := compiler.searchPaths.root.FindNode('OtherUnitFiles');
            compiler.searchPaths.unitOutputDirectory := compiler.searchPaths.root.FindNode('UnitOutputDirectory');
         end;

         compiler.codeGeneration.root := compiler.root.FindNode('CodeGeneration');

         if(compiler.codeGeneration.root <> nil) then begin
            compiler.codeGeneration.checks.root := compiler.codeGeneration.root.FindNode('Checks');

            if(compiler.codeGeneration.checks.root <> nil) then begin
               compiler.codeGeneration.checks.io := compiler.codeGeneration.checks.root.FindNode('IOChecks');
               compiler.codeGeneration.checks.range := compiler.codeGeneration.checks.root.FindNode('RangeChecks');
               compiler.codeGeneration.checks.overflow := compiler.codeGeneration.checks.root.FindNode('OverflowChecks');
               compiler.codeGeneration.checks.stack := compiler.codeGeneration.checks.root.FindNode('StackChecks');
            end;
         end;

         compiler.Linking.root := compiler.root.FindNode('Linking');

         if(compiler.Linking.root <> nil) then begin
            compiler.Linking.Debugging.root := compiler.Linking.root.FindNode('Debugging');

            if(compiler.Linking.Debugging.root <> nil) then begin
               compiler.Linking.Debugging.UseExternalDebugSymbols :=
                  compiler.Linking.Debugging.root.FindNode('UseExternalDbgSym');
            end;
         end;

         compiler.other.root := compiler.root.FindNode('Other');

         if(compiler.other.root <> nil) then
            compiler.other.customOptions := compiler.other.root.FindNode('CustomOptions');
      end;

      if(project.version <> nil) then begin
         lpiVersion := project.version.GetAttributeInt('Value');

         if(LPIVersion < MinimumVersion) then
            log.w('LPI version mismatch, got ' + GetValue(project.version) + ', expected ' + sf(MinimumVersion) + ' for: ' + Path);
      end;
   except
      on E: Exception do begin
         log.w('Failure extracting node from lpi xml ' + Path);
         log.w(E.ToString());
         QuitOnError(eLPI_FAILED_TO_LOAD);
      end;
   end;
end;

procedure TLPIFile.ApplyValues();
var
   i: loopint;

begin
   if(compiler.applyConventions) then
      compiler.targetFilename.RemoveAttribute('ApplyConventions')
   else
      compiler.targetFilename.SetAttributeValue('ApplyConventions', false);

   for i := 0 to SourceData.PackageList.n - 1 do begin
      AddRequiredPackage(SourceData.PackageList.List[i]);
   end;

   for i := 0 to SourceData.Symbols.n - 1 do begin
      AddSymbol(SourceData.Symbols.List[i]);
   end;
end;

procedure TLPIFile.Load(const newPath: StdString);
begin
   Path := newPath;

   try
      ReadXMLFile(xmlDoc, Path);

      Update();
   except
      on E: Exception do begin
         log.e('Failure reading lpi file at ' + Path);
         log.e(E.ToString());
         QuitOnError(eLPI_FAILED_TO_LOAD);
         exit;
      end;
   end;
end;

procedure TLPIFile.Save(const newPath: StdString);
var
   p: StdString;

begin
   ApplyValues();
   p := newPath;

   if(p = '') then
      p := Path;

   try
      {write}
      WriteXMLFile(xmlDoc, p)
   except
      on E: Exception do begin
         log.e('Failure writing lpi to ' + p);
         log.e(E.ToString());
         QuitOnError(eLPI_FAILED_TO_WRITE);
         exit;
      end
   end;
end;

function parseRead(var p: TParseData): boolean;
const
   requireString = '@lazpackage';
   symbolString = '@define';

var
   f: PLPIFile;
   definePos: loopint;

   define,
   currentLine: StdString;

begin
   Result := true;
   f := p.ExternalData;

   currentLine := LowerCase(p.CurrentLine);

   definePos := pos(requireString, currentLine);

   if(definePos > 0) then begin
      define := Copy(p.CurrentLine, definePos + Length(requireString));
      StripWhitespace(define);

      if(f^.Mode = lpiMODE_TEST) then
         log.i('Found lazarus package dependency: ' + define);

      f^.SourceData.PackageList.Add(define);
   end;

   definePos := pos(symbolString, currentLine);

   if(definePos > 0) then begin
      define := Copy(p.CurrentLine, definePos + Length(symbolString));
      StripWhitespace(define);

      if(f^.Mode = lpiMODE_TEST) then
         log.i('Found symbol define dependency: ' + define);

      f^.SourceData.Symbols.Add(define);
   end;
end;

procedure TLPIFile.ParseSource();
var
   parse: TParseData;

begin
   if(Path <> '') and (Error = 0) then begin
      if(Mode = lpiMODE_TEST) then
         log.i('lpi > Parsing: ' + Source);

      parse.Create();
      parse.ExternalData := @Self;

      parse.Read(Source, TParseMethod(@parseRead));

      if(parse.ErrorCode <> 0) then begin
         log.e('lpi > ' + parse.GetErrorString());
         Error := eREAD;
      end;
   end;
end;


procedure TLPIFile.AddCustomOption(const option: StdString);
var
   s,
   nodeValue: StdString;

begin
   if(compiler.other.root = nil) then
      compiler.other.root := compiler.root.CreateChild('Other');

   if(compiler.other.customOptions = nil) then
      compiler.other.customOptions := compiler.other.root.CreateChild('CustomOptions');

   nodeValue := GetValue(compiler.other.customOptions);

   s := option;

   if(nodeValue <> '') then
      SetValue(compiler.other.customOptions, nodeValue + LineEnding + s)
   else
      SetValue(compiler.other.customOptions, s);
end;

procedure TLPIFile.AddUnitPath(const newPath: StdString);
var
   units: StdString;

begin
   if(compiler.searchPaths.otherUnits = nil) then
      compiler.searchPaths.otherUnits := compiler.searchPaths.root.CreateChild('OtherUnitFiles');

   units := GetValue(compiler.searchPaths.otherUnits);

   if(units <> '') then
      units := units + ';' + newPath
   else
      units := newPath;

   SetValue(compiler.searchPaths.otherUnits, units);
end;

procedure TLPIFile.AddIncludePath(const newPath: StdString);
var
   includes: StdString;

begin
   if(compiler.searchPaths.includeFiles = nil) then
      compiler.searchPaths.includeFiles := compiler.searchPaths.root.CreateChild('IncludeFiles');

   includes := GetValue(compiler.searchPaths.includeFiles);

   if(includes <> '') then
      includes := includes + ';' + newPath
   else
      includes := newPath;

   SetValue(compiler.searchPaths.includeFiles, includes);
end;

procedure TLPIFile.SetUnitOutputDirectory(const newPath: StdString);
begin
   if(compiler.searchPaths.unitOutputDirectory = nil) then
      compiler.searchPaths.unitOutputDirectory := compiler.searchPaths.root.CreateChild('UnitOutputDirectory');

   SetValue(compiler.searchPaths.unitOutputDirectory, newPath);
end;

procedure TLPIFile.SetTitle(const newTitle: StdString);
begin
   SetValue(project.general.title, newTitle);
end;

procedure TLPIFile.AddRequiredPackage(const packageName: StdString);
var
   count: loopint;
   item,
   valueNode: TDOMNode;

begin
   if(packageName <> '') then begin
      CreatePackagesSection();

      {get package count}
      loopint.TryParse(project.requiredPackages.root.GetAttributeValue('Count', '0'), count);

      {increase count}
      inc(count);

      project.requiredPackages.root.SetAttributeValue('Count', sf(count));

      {add new item}
      item := project.requiredPackages.root.CreateChild('Item' + sf(count));

      {add item value}
      valueNode := item.CreateChild('PackageName');

      SetValue(valueNode, packageName);
   end;
end;

procedure TLPIFile.AddSymbol(const symbol: StdString);
begin
   AddCustomOption('-d' + symbol);
end;

procedure TLPIFile.CreatePackagesSection();
begin
   if(project.requiredPackages.root = nil) then begin
      project.requiredPackages.root := project.root.CreateChild('RequiredPackages');
      project.requiredPackages.root.SetAttributeValue('Count', '0');
   end;
end;

class procedure TLPIFile.SetValue(node: TDOMNode; const value: StdString);
begin
   if(node <> nil) then
      node.SetAttributeValue('Value', value);
end;

class function TLPIFile.GetValue(node: TDOMNode): StdString;
var
   valueNode: TDOMNode;

begin
   if(node <> nil) then begin
      valueNode := node.Attributes.GetNamedItem('Value');

      if(valueNode <> nil) then
         exit(valueNode.NodeValue);
   end;

   Result := '';
end;

procedure TLPIFile.Destroy();
begin
   FreeObject(xmlDoc);
end;

procedure TLPIFile.QuitOnError(errorCode: longint);
begin
   Destroy();
   Error := errorCode;
end;

{ TLPIGlobal }

procedure TLPIGlobal.Initialize();
begin
   if(build.Initialized) then begin
      Template.Setup();

      Initialized := true;
   end else
      log.e('Cannot initialize lpi build, due to base build system not being initialized');
end;

procedure TLPIGlobal.DeInitialize();
begin
   Initialized := false;
end;

function TLPIGlobal.IsInitialized(): boolean;
begin
   if(not Initialized) then
      log.e('LPI functionality not initialized');

   Result := Initialized;
end;

procedure TLPIGlobal.Create(const source: StdString; context: PLPIContext; testMode: boolean);
var
   target,
   targetPath,
   templateFilename,
   destination,
   absoluteDestination,
   units,
   includes: StdString;

   f: TLPIFile;

begin
   if(not IsInitialized()) then begin
      Error := eLPI_NOT_INITIALIZED;
      exit;
   end;

   Error := 0;
   Initialize(f);

   if(context <> nil) and (context^.Target <> '') then
      target := context^.Target
   else
      target := ExtractFileNameNoExt(source);

   targetPath := ExtractFilePath(source);

   if(targetPath <> '') then
      targetPath := IncludeTrailingPathDelimiter(targetPath);

   destination := targetPath + ExtractFileNameNoExt(source) + '.lpi';
   absoluteDestination := ExpandFileName(destination);

   OutFileName := destination;

   units := '';

   {get template name}
   templateFilename := Template.Path + Template.Name;

   if(not testMode) then
      f.Mode := lpiMODE_CREATE
   else
      f.Mode := lpiMODE_TEST;

   f.Load(templateFilename);
   f.Source := source;
   Error := f.Error;

   {load a template as a string}
   if(f.Error = 0) then begin
      f.ParseSource();

      units := build.GetIncludesPath(absoluteDestination, build.Units);
      includes := build.GetIncludesPath(absoluteDestination, build.Includes);

      if(build.FPCOptions.UnitOutputPath <> '') then
         f.SetUnitOutputDirectory(build.FPCOptions.UnitOutputPath);

      f.SetValue(f.project.general.title, target);
      f.SetValue(f.project.units.unit0Filename, target + ExtractFileExt(source));
      f.SetValue(f.compiler.targetFilename, target);
      f.SetValue(f.compiler.searchPaths.otherUnits, units);
      f.SetValue(f.compiler.searchPaths.includeFiles, includes);

      if(context <> nil) and (context^.Loaded <> nil) then
         context^.Loaded(f);

      if(not testMode) then begin
         f.Save(destination);
         Error := f.Error;
      end;

      if(f.Error = 0) then
         log.i('Created lpi file as ' + destination)
      else
         log.e('Failure writing lpi to ' + destination + ': ' + sf(Error));
  end else begin
     log.e('Failure reading template file from ' + templateFilename + ': ' + sf(Error));

     Error := eLPI_FAILED_TO_LOAD_TEMPLATE;
  end;

  f.Destroy();
end;

procedure TLPIGlobal.Update(const lpiFile: StdString; context: PLPIContext = nil);
var
   units,
   includes,
   absoluteDestination: StdString;

   i: loopint;
   f: TLPIFile;

begin
   if(not IsInitialized()) then begin
      Error := eLPI_NOT_INITIALIZED;
      exit;
   end;

   Error := 0;
   Initialize(f);

   absoluteDestination := ExpandFileName(lpiFile);

   {load a template as a string}
   if(FileExists(lpiFile)) then begin
      Initialize(f);

      f.Mode := lpiMODE_UPDATE;
      f.Load(lpiFile);

      if(f.Error <> 0) then begin
         Error := f.Error;
         exit;
      end;

      if(f.compiler.searchPaths.root <> nil) then begin
         absoluteDestination := ExtractFilePath(absoluteDestination);

         if(Verbose) then
            log.v('Destination: ' + absoluteDestination);

         if(f.compiler.searchPaths.includeFiles <> nil) and (f.compiler.searchPaths.otherUnits <> nil) then begin
            includes := build.GetIncludesPath(absoluteDestination, build.Includes, f.GetValue(f.compiler.searchPaths.includeFiles));

            if(Verbose) then begin
               for i := 0 to build.Includes.n - 1 do
                  log.v('build.Includes: ' + build.Includes.List[i]);

               log.v('Includes: ' + includes);
            end;

            f.SetValue(f.compiler.searchPaths.includeFiles, includes);

            units := build.GetIncludesPath(absoluteDestination, build.Units, f.GetValue(f.compiler.searchPaths.otherUnits));
            f.SetValue(f.compiler.searchPaths.otherUnits, units);

            if(Verbose) then begin
               for i := 0 to build.Units.n - 1 do
                  log.v('build.Units: ' + build.Units.List[i]);

               log.v('Units: ' + includes);
            end;

            if(context <> nil) and (context^.Loaded <> nil) then
               context^.Loaded(f);

            f.Save(lpiFile);
            Error := f.Error;
         end;
      end;

      log.i('Updated lpi file ' + lpiFile);
      f.Destroy();
   end else begin
      log.e('Failure finding lpi file at ' + lpiFile + ': ' + getRunTimeErrorDescription(ioE));

      Error := eLPI_FAILED_TO_LOAD;
   end;
end;

procedure TLPIGlobal.Test(const source: StdString; context: PLPIContext);
begin
   Create(source, context, true);
end;

procedure TLPIGlobal.Initialize(out f: TLPIFile);
begin
   ZeroPtr(@f, SizeOf(f));
   f.Initialize();
end;

procedure TLPIGlobal.Initialize(out context: TLPIContext);
begin
   ZeroPtr(@context, SizeOf(TLPIContext));
end;

{ TLLPITemplate }

procedure TLPITemplate.Setup;
begin
   {TODO: Should read this from a configuration file}

   Path := build.Tools.Build + 'tools\lpi_templates\';
   FileUtils.NormalizePath(Path);
   Path := IncludeTrailingPathDelimiter(Path);

   Name := 'template.lpi';
end;

END.
