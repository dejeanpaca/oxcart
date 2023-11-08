{
   uLPI, manipulates LPI files
   Copyright (C) 2017. Dejan Boras

   Started On:    02.01.2017.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uLPI;

INTERFACE

   USES
      sysutils, uStd, uLog, uBuild, uFileUtils, StringUtils,
      {LazUtils}
      uLazXMLUtils, Laz2_DOM, laz2_XMLRead, laz2_XMLWrite;

CONST
   eLPI_NONE                        = 0;
   eLPI_NOT_INITIALIZED             = 1;
   eLPI_FAILED_TO_LOAD_TEMPLATE     = 2;
   eLPI_FAILED_TO_LOAD              = 3;
   eLPI_FAILED_TO_WRITE             = 4;

TYPE
   PLPITemplate = ^TLPITemplate;
   PLPIFile = ^TLPIFile;
   PLPIContext = ^TLPIContext;

   { TLLPITemplate }

   TLPITemplate = record
      Path,
      Name: string;

      procedure Setup();
   end;

   { TLPIFile }

   TLPIFile = record
      Version: loopint;
      Path: string;
      xmlDoc: TXMLDocument;
      Error: longint;

      project: record
         root: TDOMNode;

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
         root: TDOMNode;

         searchPaths: record
            root,
            includeFiles,
            otherUnits: TDOMNode;
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

      procedure Update();
      procedure ApplyValues();

      procedure Load(const newPath: string);
      procedure Save(const newPath: string = '');

      procedure AddCustomOption(const option: string);
      procedure AddUnitPath(const newPath: string);
      procedure AddIncludePath(const newPath: string);
      procedure SetTitle(const newTitle: string);
      procedure AddRequiredPackage(const packageName: string);
      procedure CreatePackagesSection();

      class procedure SetValue(node: TDOMNode; const value: string); static;
      class function GetValue(node: TDOMNode): string; static;

      procedure Destroy();

      procedure QuitOnError(errorCode: longint);
   end;

   { TLPIContext }

   TLPIContext = record
      Target: string;
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
      OutFileName: string;

      {template information}
      Template: TLPITemplate;

      procedure Initialize();
      function IsInitialized(): boolean;

      procedure Create(const source: string; context: PLPIContext = nil);
      procedure Update(const lpiFile: string; context: PLPIContext = nil);

      procedure Initialize(out f: TLPIFile);
      procedure Initialize(out context: TLPIContext);
   end;

   { TLPIBuild }

   TLPIBuild = record
      function BuildFromPas(const source: string): boolean;
      function BuildFromPas(const source: string; var context: TLPIContext): boolean;
   end;

VAR
   lpi: TLPIGlobal;
   lpibuild: TLPIBuild;

IMPLEMENTATION

{ TLPIBuild }

function TLPIBuild.BuildFromPas(const source: string): boolean;
var
   context: TLPIContext;

begin
   lpi.Initialize(context);

   Result := BuildFromPas(source, context);
end;

function TLPIBuild.BuildFromPas(const source: string; var context: TLPIContext): boolean;
var
   fn: string;

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
      build.Output.Success := false;
      exit(false);
   end;

   lpi.Create(fn, @context);

   if(lpi.Error = 0) then
      build.Laz(lpi.OutFileName);

   Result := build.Output.Success;
end;

{ TLPIFile }

procedure TLPIFile.Update();
begin
   try
      project.root := xmlDoc.FirstChild.FindNode('ProjectOptions');
      if(project.root <> nil) then begin
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

         if(compiler.other.root <> nil) then begin
            compiler.other.customOptions := compiler.other.root.FindNode('CustomOptions');
         end else
            log.e('custom options not found');
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
begin
   if(compiler.applyConventions) then
      compiler.target.RemoveAttribute('applyConventions')
   else
      compiler.target.SetAttributeValue('applyConventions', false);
end;

procedure TLPIFile.Load(const newPath: string);
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

procedure TLPIFile.Save(const newPath: string);
var
   p: string;

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

procedure TLPIFile.AddCustomOption(const option: string);
var
   s,
   nodeValue: string;

begin
   if(compiler.other.customOptions <> nil) then begin
      nodeValue := GetValue(compiler.other.customOptions);

      s := option;

      if(nodeValue <> '') then
         SetValue(compiler.other.customOptions, nodeValue + LineEnding + s)
      else
         SetValue(compiler.other.customOptions, s);
   end else
      log.e('Could not set custom option ' +  option + ' in lpi xml, as the node was not found');
end;

procedure TLPIFile.AddUnitPath(const newPath: string);
var
   units: string;

begin
   units := GetValue(compiler.searchPaths.otherUnits);

   if(units <> '') then
      units := units + ';' + newPath
   else
      units := newPath;

   SetValue(compiler.searchPaths.otherUnits, units);
end;

procedure TLPIFile.AddIncludePath(const newPath: string);
var
   includes: string;

begin
   includes := GetValue(compiler.searchPaths.includeFiles);

   if(includes <> '') then
      includes := includes + ';' + newPath
   else
      includes := newPath;

   SetValue(compiler.searchPaths.includeFiles, includes);
end;

procedure TLPIFile.SetTitle(const newTitle: string);
begin
   SetValue(project.general.title, newTitle);
end;

procedure TLPIFile.AddRequiredPackage(const packageName: string);
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

      {add new item}
      item := project.requiredPackages.root.CreateChild('Item' + sf(count));

      {add item value}
      valueNode := item.CreateChild('PackageName');
      valueNode.SetAttributeValue('Value', packageName);
   end;
end;

procedure TLPIFile.CreatePackagesSection();
var
   attr: TDOMAttr;

begin
   if(project.requiredPackages.root = nil) then begin
      project.requiredPackages.root := xmlDoc.CreateElement('RequiredPackages');
      project.root.AppendChild(project.requiredPackages.root);

      attr := xmlDoc.CreateAttribute('Count');
      attr.NodeValue := '0';
      project.requiredPackages.root.Attributes.SetNamedItem(attr);
   end;
end;

class procedure TLPIFile.SetValue(node: TDOMNode; const value: string);
var
   valueNode: TDOMNode;

begin
   if(node <> nil) then begin
      valueNode := node.Attributes.GetNamedItem('Value');

      if(valueNode <> nil) then
         valueNode.NodeValue := Value;
   end;
end;

class function TLPIFile.GetValue(node: TDOMNode): string;
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
   if(xmlDoc <> nil) then
      xmlDoc.Free();
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

function TLPIGlobal.IsInitialized(): boolean;
begin
   if(not Initialized) then
      log.e('LPI functionality not initialized');

   Result := Initialized;
end;

procedure TLPIGlobal.Create(const source: string; context: PLPIContext);
var
   target,
   targetPath,
   templateFilename,
   destination,
   absoluteDestination,
   units,
   includes: string;

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

   f.Load(templateFilename);
   Error := f.Error;

   {load a template as a string}
   if(f.Error = 0) then begin
      units := build.GetIncludesPath(absoluteDestination, build.Units);
      includes := build.GetIncludesPath(absoluteDestination, build.Includes);

      f.SetValue(f.project.general.title, target);
      f.SetValue(f.project.units.unit0Filename, target + ExtractFileExt(source));
      f.SetValue(f.compiler.targetFilename, target);
      f.SetValue(f.compiler.searchPaths.otherUnits, units);
      f.SetValue(f.compiler.searchPaths.includeFiles, includes);

      if(context <> nil) and (context^.Loaded <> nil) then
         context^.Loaded(f);

      f.Save(destination);
      Error := f.Error;

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

procedure TLPIGlobal.Update(const lpiFile: string; context: PLPIContext = nil);
var
   units,
   includes,
   absoluteDestination: string;

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

procedure TLPIGlobal.Initialize(out f: TLPIFile);
begin
   ZeroPtr(@f, SizeOf(f));
   f.compiler.applyConventions := true;
   f.Version := 11;
end;

procedure TLPIGlobal.Initialize(out context: TLPIContext);
begin
   ZeroPtr(@context, SizeOf(TLPIContext));
end;

{ TLLPITemplate }

procedure TLPITemplate.Setup;
begin
   {TODO: Should read this from a configuration file}

   Path := build.tools.build + 'tools\lpi_templates\';
   FileUtils.NormalizePath(Path);
   Path := IncludeTrailingPathDelimiter(Path);

   Name := 'template.lpi';
end;

END.
