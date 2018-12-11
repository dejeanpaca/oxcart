{
   oxbuildglextdscr
   Copyright (c) 2011. Dejan Boras

   Started On:    28.03.2011.
}

{$MODE OBJFPC}{$H+}
PROGRAM oxbuildglextdscr;

   USES
      uStd, uSimpleParser;

CONST
   MAX_EXT = 8192-1;

VAR
   {list of extensions}
   nExts: longint = 0;
   Exts: array[0..MAX_EXT] of string;

   {filenames}
   listFN: string    = '';
   psListFN: string  = '';
   outFN: string     = '';

{process a line from the list file}
function readf(var p: TParseData): boolean;
begin
   result := true;

   if(p.currentLine[1] <> '#') then begin
     writeln('found: ', p.currentLine);

     Inc(nExts);
     Exts[nExts - 1] := p.currentLine;
   end;
end;

{read the extensions list file}
procedure ReadFile(fn: string);
var
   p: TParseData;

begin
   writeln('Reading file: ', fn);
   TParseData.Init(p);
   p.ReadMethod := TParseExtMethod(@readf);
   p.Read(fn);

   if(ioE <> 0) then begin
      writeln('Error(', ioE, ') reading file.');
      halt(1);
   end;
end;

{ write the extensions descriptor file }
procedure WriteFile();
var
   f: text;
   i: longint;

begin
   writeln('Writing file: ', outFN);

   Assign(f, outFN);
   Rewrite(f);
   if(ioerror() = 0) then begin
      writeln(f, '{File generated via oxbuildglextdscr.}');
      writeln(f);

      writeln(f, '   oglnExtensionDescriptors = ', nExts, ';');
      writeln(f);

      writeln(f, '{ extension IDs }');
      for i := 0 to (nExts-1) do begin
         writeln(f, '   c' + Exts[i], ' = ', i, ';');
      end;
      writeln(f);

      writeln(f, 'TYPE');
      writeln(f, '   oglTExtensionDescriptors = array[0 .. oglnExtensionDescriptors - 1] of oglTExtensionDescriptor;');
      writeln(f);
      writeln(f, 'CONST');
      writeln(f);

      writeln(f, '{ extension descriptors }');
      writeln(f, '   oglcExtensionDescriptors: oglTExtensionDescriptors = (');
      for i := 0 to (nExts-1) do begin
         write(f, '      (Name: '''+Exts[i], '''; Present: false)');
         if(i < nExts-1) then
            writeln(f,',')
         else
               writeln(f);
      end;
      writeln(f, '   );');
   end;

   Close(f);
   ioerror();
end;

procedure ReadBaseFile();
begin
   ReadFile(listFN);
end;

procedure ReadPlatformSpecificFile();
begin
   if(psListFN <> '') then begin
      ReadFile(psListFN);
   end;
end;

procedure processParameters();
var
   target: string;

begin
   target := ParamStr(1);

   {process parameters}
   if(target = '-gles') then begin
      listFN   := 'gles/exts.lst';
      outFN    := 'gles/oxglextdscr.inc';
   end else if (target = '') then begin
      listFN   := 'oxglexts.lst';
      outFN    := 'oxglextdscr.inc';
   end else begin 
      writeln('Unknown target: ', target);
      halt(1);
   end;
   
   if(target <> '') then
      writeln('Target: '+target);
end;

BEGIN
   processParameters();

   writeln('Building ',outFN,' from ',listFN,' ...');

   {process files}
   ReadBaseFile();
   ReadPlatformSpecificFile();

   writeln('Found ', nExts, ' extension(s).');
   if(nExts > 0) then begin
      WriteFile();
      if(ioE = 0) then
         writeln('Done')
      else
         writeln('Failed to write file.');
   end else
      writeln('No extension names found. Nothing to do.');
END.
