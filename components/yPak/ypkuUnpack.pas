{
   ypkuUnpack, unpacking component
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ypkuUnpack;

INTERFACE

   USES
      sysutils, uStd, uFile, uFiles, ufhStandard, ConsoleUtils, StringUtils,
      yPakU, uyPakFile;

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

   for i := 0 to (pak.Entries.n - 1) do begin
      {get path}
      path := '';
      // TODO: Get path
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
   for i := 0 to (pak.Entries.n - 1) do begin
      // TODO: fname := pak.Entries.list[i].fn;
      fname := '';

      ReplaceDirSeparators(fname);
      writeln('creating file: ', fname);

      fCopy(pak.f, fname, pak.Entries.list[i].size);

      if(pak.f.error <> 0) or (ioE <> 0) then begin
         writeln('Error(', pak.f.error, ioE ,'): Cannot create file.');
         break;
      end;
   end;
end;

procedure Unpack();
var
   hdr: ypkfTHeader;

begin
   writeln('Unpacking: ', pak.fn);

   {open}
   pak.f.Open(pak.fn);
   if(pak.f.error = 0) then begin
      ypkfSetBuffer();

      {read header}
      ypkf.ReadHeader(hdr);
      if(pak.f.Error = 0) then begin
         writeln('Reading entries...');
         ypkf.ReadEntries(pak.Entries, hdr.Files);

         {read pak.Entries}
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
         console.e(pak.f.GetErrorString() + ' - Header invalid or file unsupported.');
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
