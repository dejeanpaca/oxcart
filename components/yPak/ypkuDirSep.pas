{
   ypkuDirSep, replaces directory separators
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ypkuDirSep;

INTERFACE

   USES
     ConsoleUtils, uFile, uFiles, ufhStandard,
     yPakU, uyPakFile;

procedure ReplaceDirSep();

IMPLEMENTATION

procedure ReplaceDirSep();
var
   hdr: ypkfTHeader;

begin
   writeln('Replacing directory separators in: ', pak.fn);

   {open}
   pak.f.Open(pak.fn);
   if(pak.f.Error = 0) then begin
      pak.SetBuffer();

      {read header}
      ypkf.ReadHeader(hdr);

      if(pak.f.Error = 0) then begin
         writeln('Reading entries...');
         ypkf.ReadEntries(pak.Entries, hdr.Files);

         {read entries}
         if(pak.f.Error = 0)then begin
            if(hdr.Files > 0) then begin
               writeln('Done reading entries.');

               { TODO: replace directories here }
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
