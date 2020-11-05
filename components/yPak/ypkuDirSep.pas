{
   ypkuDirSep, replaces directory separators
   Copyright (C) 2011. Dejan Boras
}

{$MODE OBJFPC}{$H+}
UNIT ypkuDirSep;

INTERFACE

   USES uFile, uFiles, ufhStandard, uyPak, yPakU,
      ConsoleUtils, StringUtils;

procedure ReplaceDirSep();

IMPLEMENTATION

procedure ReplaceDirSep();
var
   hdr: ypkTHeader;

begin
   writeln('Replacing directory separators in: ', pak.fn);

   {open}
   pak.f.Open(pak.fn);
   if(pak.f.error = 0) then begin
      ypkfSetBuffer();

      {read header}
      ypk.ReadHeader(pak.f, hdr);
      if(ypk.error = 0) then begin
         writeln('Reading entries...');
         ypk.ReadEntries(pak.f, pak.entries, hdr.Files);

         {read entries}
         if(pak.f.error = 0)then begin
            if(hdr.Files > 0) then begin
               writeln('Done reading entries.');

               { TODO: replace directories here }
            end else
               writeln('The YPK file is empty. Nothing to do.');
         end else
            console.e('Cannot read the YPAK file.');
      end else begin
         console.e(sf(ypk.error)+' - Header invalid or file unsupported.');
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
