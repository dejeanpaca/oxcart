{
   ypkuUnpack, unpacking component
   Copyright (C) 2011. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT ypkuUnpack;

INTERFACE

   USES sysutils, uStd, uFile, uFiles, ufhStandard, ConsoleUtils, StringUtils,
     uyPak, yPakU;

procedure Unpack();

IMPLEMENTATION

procedure CreateDirectories();
var
   i: longint;
   s,
     path: string;
   ppath: string;
   lvl: longint;

begin
   ppath := '';
   lvl := 0;

   for i := 0 to (pak.entries.n - 1) do begin
      {get path}
      path := pak.entries.list[i].fn;
      writeln('creating: ', path);
      ReplaceDirSeparators(path);
      path := ExtractFilePath(path);

      {we'll only try to create paths if they differ}
      if(path <> ppath) then begin
         repeat
            {get directory and create it}
            s := CopyToDel(path, DirectorySeparator);

           if(s <> '') then begin
               mkdir(s);
               IOResult();

               {go into the created directory}
               chdir(s);
               IOResult();
               inc(lvl);
            end;
         until (path = '');

         {return to the original directory if we moved}
         if(lvl > 0) then repeat
            chdir('..');
            dec(lvl);
         until (lvl = 0);
      end;
      {}
      ppath := path;
   end;
end;

procedure CreateFiles();
var
   i: longint;
   fname: string;

begin
   for i := 0 to (pak.entries.n - 1) do begin
      fname := pak.entries.list[i].fn;
      ReplaceDirSeparators(fname);
      writeln('creating file: ', fname);

      fCopy(pak.f, fname, pak.entries.list[i].size);

      if(pak.f.error <> 0) or (ioE <> 0) then begin
         writeln('Error(', pak.f.error, ioE ,'): Cannot create file.');
         break;
      end;
   end;
end;

procedure Unpack();
var
   hdr: ypkTHeader;

begin
   writeln('Unpacking: ', pak.fn);

   {open}
   pak.f.Open(pak.fn);
   if(pak.f.error = 0) then begin
      ypkfSetBuffer();

      {read header}
      ypk.ReadHeader(pak.f, hdr);
      if(ypk.error = 0) then begin
         writeln('Reading entries...');
         ypk.ReadEntries(pak.f, pak.entries, hdr.Files);

         {read pak.entries}
         if(pak.f.error = 0)then begin
            if(hdr.Files > 0) then begin
               writeln('Done reading entries.');
               {create directories}
               writeln('Creating directories...');
               CreateDirectories();

               if(pak.f.error = 0) then begin
                  writeln('Done creating directories.');

                  writeln('Creating files...');
                  CreateFiles();

                  if(pak.f.error <> 0) and (ioE = 0) then
                     writeln('Done creating files.');
               end;
            end else
               writeln('The YPK file is empty. Nothing to do.');
         end else
            console.e('Cannot read the YPAK file.');
      end else begin
         console.e(sf(ypk.error) + ' - Header invalid or file unsupported.');
         writeln('ID:         ', hdr.ID);
         writeln('Endian:     ', hexstr(hdr.Endian, 4));
         writeln('Version:    ', hexstr(hdr.Version, 4));
         writeln('File count: ', hdr.Files);
      end;
   end else
      console.e('Cannot open file.');

   pak.f.Close();
end;

END.
