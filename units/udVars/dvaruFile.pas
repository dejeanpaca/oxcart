{
	dvaruFile, DVar file support
	Copyright (c) 2011. Dejan Boras

	Started On:		09.10.2011.

   Reads and writes dvars into a file, as:
      key = value
   per line.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT dvaruFile;

INTERFACE

   USES
      uStd, uLog, StringUtils, udvars,
      stdDataTypeCodeNames,
      uSimpleParser;

TYPE
   dvarPFileData = ^dvarTFileData;
   dvarPFileOnSaveList = ^dvarTFileOnSaveList;

   { dvarTFileOptions }

   dvarPFileOptions = ^dvarTFileOptions;
   dvarTFileOptions = record
      OnSave: dvarPFileOnSaveList;
   end;

   { dvarTFileData }

   dvarTFileData = record
      {filename}
      fn: StdString;
      {root dvar group}
      dv: PDVarGroup;
      {Parser data}
      Parser: TParseData;

      {Options}
      Options: dvarTFileOptions;

      function Write(const parent: StdString; var g: TDVarGroup): boolean;
      function Write(const parent: StdString; var v: TDVar): boolean;
      function Write(const parent: StdString; var v: TDVar; const what: StdString): boolean;
      function Write(const parent: StdString; var v: TDVar; const items: array of StdString; count: longint = 0): boolean;
      function Write(const parent: StdString; var v: TDVar; items: pstring; count: longint = 0): boolean;
   end;

   {called when a matching group is saved}
   dvarTFileSaveHandler = procedure(var dv: dvarTFileData; const parent: StdString);

   {handler associated with a dvar group, called when the dv is matched while saving}
   dvarTFileOnSave = record
      dv: PDVarGroup;
      handler: dvarTFileSaveHandler;
   end;

   {list of handlers for dvar saving}
   dvarTFileOnSaveList = specialize TPreallocatedArrayList<dvarTFileOnSave>;

   {helpful utilities for save handlers}

   { dvarTFileOnSaveListHelper }

   dvarTFileOnSaveListHelper = record helper for dvarTFileOnSaveList
      {add a save handler for the specified dvar group}
      procedure Add(dv: PDVarGroup; handler: dvarTFileSaveHandler);
      {returns a handler for the matching dv, or nil if nothing found}
      function Match(dv: PDVarGroup): dvarTFileSaveHandler;
   end;

   { dvarTFileGlobal }

   dvarTFileGlobal = record
      OnSave: dvarTFileOnSaveList;

      procedure InitializeOptions(out options: dvarTFileOptions);

      procedure Notify(pdvar: PDvar; f: dvarPFileData; what: loopint);

      { TEXT FILE }
      procedure ReadText(var dv: TDVarGroup; const fn: StdString; options: dvarPFileOptions = nil);
      procedure WriteText(var dv: TDVarGroup; const fn: StdString; options: dvarPFileOptions = nil);

      { TEXT FILE }
      procedure ReadText(const fn: StdString);
      procedure WriteText(const fn: StdString);
   end;

VAR
   dvarf: dvarTFileGlobal;

IMPLEMENTATION

{ READ TEXT FILE }

function readTextFile(var parseData: TParseData): boolean;
var
   key,
   value: StdString;
   pvar: PDVar;
   pd: PDVarGroup;

begin
   Result := true;

   pd := dvarTFileData(parseData.externalData^).dv;

   key := CopyToDel(parseData.currentLine, '=');
   StripWhitespace(key);

   if(key <> '') and (key[1] <> '#') then begin
      value := parseData.currentLine;
      StripWhitespace(value);

      pvar := pd^.Get(key);

      if(pvar <> nil) then begin
         if(pvar^.AssignFromString(value)) then begin
            if(dvarNOTIFY_READ in pvar^.Properties) then
               dvarf.Notify(pvar, parseData.ExternalData, DVAR_NOTIFICATION_READ)
         end else
            log.i('dvar > Could not set variable ' + key + '(' + stdGetDTCodeName(pvar^.DataType)^ + ') to value: ' + value);
      end else
         log.i('dvar > Variable ' + key + ' not found.');
   end;
end;

{ dvarTFileOnSaveListHelper }

procedure dvarTFileOnSaveListHelper.Add(dv: PDVarGroup; handler: dvarTFileSaveHandler);
var
   entry: dvarTFileOnSave;

begin
   entry.dv := dv;
   entry.handler := handler;

   inherited Add(entry);
end;

function dvarTFileOnSaveListHelper.Match(dv: PDVarGroup): dvarTFileSaveHandler;
var
   i: longint;

begin
   if(n > 0) then
      for i := 0 to (n - 1) do begin
         if(list[i].dv = dv) then
            exit(list[i].handler);
      end;

   Result := nil;
end;

procedure dvarTFileGlobal.InitializeOptions(out options: dvarTFileOptions);
begin
   ZeroOut(options, SizeOf(options));
   options.OnSave := @OnSave;
end;

procedure dvarTFileGlobal.Notify(pdvar: PDVar; f: dvarPFileData; what: loopint);
var
   context: TDVarNotificationContext;

begin
   TDVarNotificationContext.Initialize(context);

   context.DVar := @pdvar;
   context.f := f;
   context.What := what;

   if(pdvar^.pNotify <> nil) then
      pdvar^.pNotify(context);
end;

procedure dvarTFileGlobal.ReadText(var dv: TDVarGroup; const fn: StdString; options: dvarPFileOptions);
var
   data: dvarTFileData;
   opt: dvarTFileOptions;

begin
   data.fn := fn;
   data.dv := @dv;

   if(options = nil) then begin
      InitializeOptions(opt);
      options := @opt;
   end;

   data.Options := options^;

   TParseData.Init(data.Parser);
   data.Parser.externalData := @data;
   data.Parser.Read(fn, TParseMethod(@readTextFile));
end;

procedure dvarTFileGlobal.ReadText(const fn: StdString);
begin
   ReadText(dvar.dvars, fn);
end;

{ WRITE TEXT FILE }

{write a group into a text file}
function dvarTFileData.Write(const parent: StdString; var g: TDVarGroup): boolean;
var
   curGroup: PDVarGroup;
   curVar: PDVar = nil;
   matchHandler: dvarTFileSaveHandler;

begin
   Result := true;

   {write variables}
   curVar := g.vs;

   if(curVar <> nil) then repeat
      Write(parent,  curVar^);
      curVar := curVar^.Next;
   until (curVar = nil);

   {go through all sub groups}
   curGroup := g.sub.s;

   if(Options.OnSave <> nil) then begin
      if(curGroup <> nil) then repeat
         {check if we have any handlers for this group}
         matchHandler := Options.OnSave^.Match(curGroup);

         {write group or call its handler}
         if(matchHandler = nil) then
            Write(parent + curGroup^.Name + '.', curGroup^)
         else
            matchHandler(self, parent + curGroup^.Name + '.');

         curGroup := curGroup^.Next;
      until (curGroup = nil);
   end else begin
      if(curGroup <> nil) then repeat
         Write(parent + curGroup^.Name + '.', curGroup^);

         curGroup := curGroup^.Next;
      until (curGroup = nil);
   end;
end;

function dvarTFileData.Write(const parent: StdString; var v: TDVar): boolean;
begin
   if(not (dvarDO_NOT_SAVE in v.Properties)) then begin
      Parser.WriteLine(parent + v.Name + ' = ' + v.GetAsString());

      if(dvarNOTIFY_WRITE in v.Properties) then
         dvarf.Notify(@v, @self, DVAR_NOTIFICATION_WRITE);
   end;

   Result := true;
end;

function dvarTFileData.Write(const parent: StdString; var v: TDVar; const what: StdString): boolean;
begin
   if(not (dvarDO_NOT_SAVE in v.Properties)) then begin
      Parser.WriteLine(parent + v.Name + ' = ' + what);

      if(dvarNOTIFY_WRITE in v.Properties) then
         dvarf.Notify(@v, @self, DVAR_NOTIFICATION_WRITE);
   end;

   Result := true;
end;

function dvarTFileData.Write(const parent: StdString; var v: TDVar; const items: array of StdString; count: longint = 0): boolean;
var
   i: longint;

begin
   if(count = 0) then
      count := Length(items);

   for i := 0 to (count - 1) do begin
      Result := Write(parent, v, items[i]);

      if(not Result) then
         exit(false);
   end;

   Result := true;
end;

function dvarTFileData.Write(const parent: StdString; var v: TDVar; items: pstring; count: longint): boolean;
var
   i: longint;

begin
   for i := 0 to (count - 1) do begin
      Result := Write(parent, v, items[i]);

      if(not Result) then
         exit(false);
   end;

   Result := true;
end;

function writeTextFile(var parseData: TParseData): boolean;
var
   pd: PDVarGroup;
   rootGroup: TDVarGroup;

begin
   pd := dvarTFileData(parseData.externalData^).dv;

   parseData.WriteLine('# DVAR');
   parseData.WriteLine('');

   if(pd^.Name = '.') then
      dvarTFileData(parseData.externalData^).Write('', pd^)
   else begin
      {create a parent group for a group that doesn't have one}
      rootGroup := dvar.RootGroup;
      rootGroup.sub.s := pd;

      dvarTFileData(parseData.externalData^).Write('', rootGroup);
   end;

   Result := true;
end;

procedure dvarTFileGlobal.WriteText(var dv: TDVarGroup; const fn: StdString; options: dvarPFileOptions);
var
   data: dvarTFileData;
   opt: dvarTFileOptions;

begin
   data.fn := fn;
   data.dv := @dv;

   if(options = nil) then begin
      InitializeOptions(opt);
      options := @opt;
   end;

   data.Options := options^;

   if(dv.sub.s <> nil) or (dv.vs <> nil) then begin
      TParseData.Init(data.Parser);
      data.Parser.externalData := @data;
      data.Parser.Write(fn, TParseMethod(@writeTextFile));
   end;
end;

procedure dvarTFileGlobal.WriteText(const fn: StdString);
begin
   WriteText(dvar.dvars, fn);
end;

INITIALIZATION
   dvarTFileOnSaveList.Initialize(dvarf.OnSave);

END.

