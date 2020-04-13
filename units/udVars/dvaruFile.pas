{
	dvaruFile, DVar file support
	Copyright (c) 2011. Dejan Boras

   Reads and writes dvars into a file, as:
      key = value
   per line.

   TODO: Add methods that operate Write() directly on the context (and store result there)
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

   { dvarTFileOptions }

   dvarPFileOptions = ^dvarTFileOptions;
   dvarTFileOptions = record

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

      procedure GetContext(out context: TDVarNotificationContext; group: PDVarGroup; parent: string = '');

      function Write(const parent: StdString; var g: TDVarGroup): boolean;
      function Write(const parent: StdString; var g: TDVarGroup; var v: TDVar): boolean;
      function Write(const parent: StdString; var v: TDVar): boolean;
      function Write(const parent: StdString; var v: TDVar; const what: StdString): boolean;
      function Write(const parent: StdString; var v: TDVar; const items: array of StdString; count: longint = 0): boolean;
      function Write(const parent: StdString; var v: TDVar; items: pstring; count: longint = 0): boolean;
   end;

   { dvarTFileGlobal }

   dvarTFileGlobal = record
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

   pd := dvarTFileData(parseData.ExternalData^).dv;

   key := CopyToDel(parseData.CurrentLine, '=');
   StripWhitespace(key);

   if(key <> '') and (key[1] <> '#') then begin
      value := parseData.CurrentLine;
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

procedure dvarTFileGlobal.InitializeOptions(out options: dvarTFileOptions);
begin
   ZeroPtr(@options, SizeOf(options));
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
   data.Parser.ExternalData := @data;
   data.Parser.Read(fn, TParseMethod(@readTextFile));
end;

procedure dvarTFileGlobal.ReadText(const fn: StdString);
begin
   ReadText(dvar.dvars, fn);
end;

{ WRITE TEXT FILE }

procedure dvarTFileData.GetContext(out context: TDVarNotificationContext; group: PDVarGroup; parent: string);
begin
   TDVarNotificationContext.Initialize(context);

   context.f := @Self;
   context.Group := group;
   context.Parent := parent + group^.Name + '.';
   context.What := DVAR_NOTIFICATION_WRITE;
   context.Result := -1;
end;

{write a group into a text file}
function dvarTFileData.Write(const parent: StdString; var g: TDVarGroup): boolean;
var
   curGroup: PDVarGroup;
   curVar: PDVar = nil;
   context: TDVarNotificationContext;

begin
   Result := true;

   {write variables}
   curVar := g.vs;

   if(curVar <> nil) then repeat
      Write(parent, g, curVar^);
      curVar := curVar^.Next;
   until (curVar = nil);

   {go through all sub groups}
   curGroup := g.Sub.s;

   if(curGroup <> nil) then begin
      repeat
         if(curGroup^.pNotify <> nil) then begin
            GetContext(context, curGroup, parent);
            curGroup^.pNotify(context);

            if(context.Result = -1) then
               Write(parent + curGroup^.Name + '.', curGroup^);
         end else
            Write(parent + curGroup^.Name + '.', curGroup^);

         curGroup := curGroup^.Next;
      until (curGroup = nil);
   end;
end;

function dvarTFileData.Write(const parent: StdString; var g: TDVarGroup; var v: TDVar): boolean;
var
   context: TDVarNotificationContext;

begin
   if(not (dvarDO_NOT_SAVE in v.Properties)) then begin
      if(dvarNOTIFY_WRITE in v.Properties) then begin
         GetContext(context, @g, parent);
         context.Parent := parent;
         context.DVar := @v;

         if(v.pNotify <> nil) then
            v.pNotify(context);

         if(context.Result = 0) then
            exit(True)
         else if(context.Result > 0) then
            exit(False);
      end;

      Parser.WriteLine(parent + v.Name + ' = ' + v.GetAsString());
   end;

   Result := true;
end;

function dvarTFileData.Write(const parent: StdString; var v: TDVar): boolean;
begin
   if(not (dvarDO_NOT_SAVE in v.Properties)) then
      Parser.WriteLine(parent + v.Name + ' = ' + v.GetAsString());

   Result := true;
end;

function dvarTFileData.Write(const parent: StdString; var v: TDVar; const what: StdString): boolean;
begin
   if(not (dvarDO_NOT_SAVE in v.Properties)) then
      Parser.WriteLine(parent + v.Name + ' = ' + what);

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
   pd := dvarTFileData(parseData.ExternalData^).dv;

   parseData.WriteLine('# DVAR');
   parseData.WriteLine('');

   if(pd^.Name = '.') then
      dvarTFileData(parseData.ExternalData^).Write('', pd^)
   else begin
      {create a parent group for a group that doesn't have one}
      rootGroup := dvar.RootGroup;
      rootGroup.sub.s := pd;

      dvarTFileData(parseData.ExternalData^).Write('', rootGroup);
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
      data.Parser.ExternalData := @data;
      data.Parser.Write(fn, TParseMethod(@writeTextFile));
   end;
end;

procedure dvarTFileGlobal.WriteText(const fn: StdString);
begin
   WriteText(dvar.dvars, fn);
end;

END.
