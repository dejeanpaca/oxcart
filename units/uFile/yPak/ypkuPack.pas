{
   ypkuPack, packing component
   Copyright (C) 2011. Dejan Boras

   Started On:    24.02.2011.
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT ypkuPack;

INTERFACE

   USES sysutils, uStd, StringUtils, ConsoleUtils,
     uFile, uFiles, ufhStandard,
     uyPak, yPakU;

procedure Pack();

IMPLEMENTATION

CONST
   alloc_step = 256;

{add a new entry to the list}
function New(): ypkPEntry;
var
   free: longint;

begin
   free := pak.entries.n;
   inc(pak.entries.n);

   if(pak.entries.a < pak.entries.n) then begin
      inc(pak.entries.a, alloc_step);

      try
         SetLength(pak.entries.list, pak.entries.a);
      except
         exit();
      end;
   end;

   result := @pak.entries.list[free];
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
   p: ypkPEntry;

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
            p^.fn := fname;
            CorrectDirSeparators(p^.fn);
            p^.size := size;

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
               ext := LowerCase(ExtractFileExt(src.Name));
               if(src.Name <> 'ypak') then begin
                  {exclusion filter}
                  if(pak.filterMode = FLTR_MODE_EXCLUDE) then begin
                     if(pos(ext, pak.excluded) = 0) then
                        ProcessFile(src.Name);
                  {inclusion filter}
                  end else begin
                     if(pos(ext, pak.included) <> 0) then
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
   for i := 0 to (pak.entries.n - 1) do begin
      fname := pak.entries.list[i].fn;
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
   offs := ypkHEADER_SIZE + pak.entries.n*ypkENTRY_SIZE;

   {set offset information for all entries}
   for i := 0 to (pak.entries.n - 1) do begin
      pak.entries.list[i].offs := offs;
      inc(offs, pak.entries.list[i].size);
   end;

   ypk.WriteEntries(pak.f, pak.entries);
end;

{ PACK }

procedure Pack();
begin
   writeln('Packing to file: ', pak.fn);

   {create a new file}
   pak.f.New(pak.fn);
   if(pak.f.error = 0) then begin
      ypkfSetBuffer();

      {find files to package}
      writeln('Finding files to package...');
      findFiles();
      if(pak.f.error = 0) then begin
         writeln('Done finding files.');

         {write header}
         ypk.WriteHeader(pak.f, pak.entries.n);

         {populate information}
         writeln('Setting information...');
         SetInformation();
         if(pak.f.error = 0) then begin
            writeln('Done setting information.');

            {package files}
            writeln('Inserting files...');
            insertFiles();
            if(pak.f.error = 0) then begin
               writeln('Done inserting files.');
            end;
         end;

      end;
   end else
      console.e('Failed to create YPAK file.');

   {done}
   pak.f.Close();
   if(pak.f.error = 0) then
      writeln('Done packing ', pak.entries.n, ' files.')
   else
      console.e(sf(pak.f.error) + ' - Failed packing.');
end;

END.
