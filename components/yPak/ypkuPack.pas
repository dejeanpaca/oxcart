{
   ypkuPack, packing component
   Copyright (C) 2011. Dejan Boras

   // TODO: Use ypkuBuilder
}

{$INCLUDE oxheader.inc}
UNIT ypkuPack;

INTERFACE

   USES
      sysutils, uStd, StringUtils, ConsoleUtils,
      uFile, uFiles, ufhStandard,
      yPakU, uyPakFile;

procedure Pack();

IMPLEMENTATION

CONST
   alloc_step = 256;

{add a new entry to the list}
function New(): ypkfPEntry;
var
   free: longint;

begin
   free := pak.Entries.n;
   inc(pak.Entries.n);

   if(pak.Entries.a < pak.Entries.n) then begin
      inc(pak.Entries.a, alloc_step);

      try
         SetLength(pak.Entries.list, pak.Entries.a);
      except
         exit();
      end;
   end;

   result := @pak.Entries.list[free];
end;

procedure CorrectDirSeparators(var s: shortstring);
var
   i, n: longint;

begin
   n := Length(s);

   for i := 1 to n do begin
      if(s[i] in ['/', '\']) then
         s[i] := ypkDirSep;
   end;
end;

{current path, relative to starting position}
VAR
   path: string;

{process a file, determine size and path}
function ProcessFile(const fn: string): longint;
var
   fname: string;
   f: file;
   size: longint;
   p: ypkfPEntry;

begin
   if(path <> '') then
      fname := path+DirectorySeparator+fn
   else
      fname := fn;

   {check if the filename exceeds maximum length}
   if(Length(fname) > ypkMAX_FN_LENGTH) then begin
      writeln('Filename too long: ', fname);
      exit(eINVALID);
   end;

   if(fname <> pak.fn) then begin
      {try to open the file}
      Assign(f, fn);
      Reset(f, 1);

      if(IOResult() = 0) then begin
         {determine size and close file}
         size := FileSize(f);
         Close(f);

         {get a new entry}
         if(IOResult() = 0) then begin
            p := New();
            {TODO: Process this}

            writeln('Found: ', fname, ' (', size, ')');
         end;
      end else begin
         console.e('Failed to get information for file > '+fname);
         exit(eIO);
      end;
   end;
end;

procedure ProcessDirectory(const name: string);
var
   src: TSearchRec;
   result: longint;
   ext: string;

begin
   if(name <> '') then begin
      if(path <> '') then
         path := path + DirectorySeparator + name
      else
         path := name;
   end;

   {find first}
   result := FindFirst('*', faReadOnly or faDirectory, src);
   if(result = 0) then begin
      repeat
         if(src.Name <> '.') and (src.Name <> '..') then begin
            if(src.Attr and faDirectory > 0) then begin
               chdir(src.Name);
               ProcessDirectory(src.Name);

               if(pak.f.error <> 0) then
                  exit;

               chdir('..');
            end else begin
               ext := LowerCase(ExtractFileExt(string(src.Name)));
               if(src.Name <> 'ypak') then begin
                  {exclusion filter}
                  if(pak.FilterMode = FLTR_MODE_EXCLUDE) then begin
                     if(pos(ext, pak.Excluded) = 0) then
                        ProcessFile(src.Name);
                  {inclusion filter}
                  end else begin
                     if(pos(ext, pak.Included) <> 0) then
                        ProcessFile(src.Name);
                  end;

                  if(pak.f.error <> 0) then
                     exit;
               end;
            end;
         end;
         result := FindNext(src);
      until (result <> 0);
   end;

   path := ExcludeTrailingPathDelimiter(ExtractFilePath(path));

   {we're done}
   FindClose(src);
end;

procedure findFiles();
begin
   path := '';
   ProcessDirectory('');
end;

{ INSERT FILES }

procedure insertFiles();
var
   error, i: longint;
   fname: string;

begin
   for i := 0 to (pak.Entries.n - 1) do begin
      // TODO: fname := pak.Entries.list[i].;
      fname := '';
      ReplaceDirSeparators(fname);
      writeln('Inserting(', i, '): ', fname);

      error := fCopy(fname, pak.f);
      if(error <> 0) or (pak.f.error <> 0) then begin
         if(pak.f.error <> 0) then
            writeln('Failed to write to target ypk file.')
         else
            writeln('Failed to read from source file: '+fname);
         exit;
      end;
   end;
end;

{ SET INFORMATION }
procedure setInformation();
var
   i: longint;
   offs: longint;

begin
   offs := ypkHEADER_SIZE + pak.Entries.n * ypkENTRY_SIZE;

   {set offset information for all entries}
   for i := 0 to (pak.Entries.n - 1) do begin
      pak.Entries.list[i].Offset := offs;
      inc(offs, pak.Entries.List[i].Size);
   end;

   ypkf.WriteEntries(pak.Entries);
end;

{ PACK }

procedure Pack();
var
   hdr: ypkfTHeader;

begin
   writeln('Packing to file: ', pak.fn);

   {create a new file}
   pak.f.New(pak.fn);

   if(pak.f.Error = 0) then begin
      ypkfSetBuffer();

      ypkTFile.InitializeHeader(hdr);
      // TODO: Build header

      {find files to package}
      writeln('Finding files to package...');
      findFiles();

      if(pak.f.Error = 0) then begin
         writeln('Done finding files.');

         {write header}
         ypkf.WriteHeader(hdr);

         {populate information}
         writeln('Setting information...');
         SetInformation();
         if(pak.f.Error = 0) then begin
            writeln('Done setting information.');

            {package files}
            writeln('Inserting files...');
            insertFiles();
            if(pak.f.Error = 0) then begin
               writeln('Done inserting files.');
            end;
         end;

      end;
   end else
      console.e('Failed to create YPAK file.');

   {done}
   pak.f.Close();

   if(pak.f.Error = 0) then
      writeln('Done packing ', pak.Entries.n, ' files.')
   else
      console.e(sf(pak.f.Error) + ' - Failed packing.');
end;

END.
