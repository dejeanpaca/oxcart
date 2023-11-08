{
   ypkuList, listing component
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ypkuList;

INTERFACE

   USES
      uStd, ConsoleUtils,
      uFile, uFiles, yPakU, uyPakFile;

procedure List();

IMPLEMENTATION

procedure List();
var
   hdr: ypkfTHeader;
   i: loopint;

begin
   writeln('Listing: ', pak.fn);
   writeln();

   {open}
   pak.f.Open(pak.fn);

   if(pak.f.Error = 0) then begin
      pak.SetBuffer();

      {read header}
      ypkf.ReadHeader(hdr);

      if(pak.f.Error = 0) then begin
         pak.data.Files := hdr.Files;
         pak.data.BlobSize := hdr.BlobSize;
         ypkf.ReadBlob(pak.data);
         ypkf.ReadEntries(pak.data);

         {read pak.Entries}
         if(pak.f.Error = 0)then begin
            if(pak.data.Files > 0) then begin
               writeln('name offset size');
               writeln();
               for i := 0 to pak.data.Files - 1 do begin
                  writeln(pak.data.GetFn(i)^, ' ', pak.data.Entries[i].Offset, ' ', pak.data.Entries[i].Size);
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
