{
   yPakU, yPak tool base unit
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ypkuBuilder;

INTERFACE

   USES
      uStd, ustrBlob,
      uFile, uFiles, ufhStandard, uFileUtils,
      {ypk}
      yPakU, uyPakFile;


TYPE
   ypkTBuilderFile = record
      FileNameOffset: loopint;

      Source,
      Destination: StdString;
   end;

   ypkTBuilderFiles = specialize TSimpleList<ypkTBuilderFile>;

   { ypkTBuilder }

   ypkTBuilder = record
      OutputFN: string;

      Files: ypkTBuilderFiles;

      {ypk data blob}
      Blob: PByte;
      Total: loopint;

      class procedure Initialize(out ypkb: ypkTBuilder); static;

      procedure Reset();
      function Build(): boolean;
      procedure AddFile(const source, destination: StdString);

      procedure Dispose();
   end;

IMPLEMENTATION

{ ypkTBuilder }

class procedure ypkTBuilder.Initialize(out ypkb: ypkTBuilder);
begin
   ZeroOut(ypkb, SizeOf(ypkb));

   ypkTBuilderFiles.InitializeValues(ypkb.Files);
end;

procedure ypkTBuilder.Reset();
begin
   Files.Dispose();
end;

function ypkTBuilder.Build(): boolean;
var
   i,
   currentOffset,
   filesOffset: loopint;

   sb: TShortStringBlob;
   entries: ypkfTEntries;

   hdr: ypkfTHeader;
   f: TFile;

begin
   Result := true;

   TShortStringBlob.Initialize(sb);
   ypkfTEntries.Initialize(entries);

   for i := 0 to Files.n - 1 do begin
      sb.Analyze(Files[i].Destination);
   end;

   sb.Allocate();

   for i := 0 to Files.n - 1 do begin
      Files.List[i].FileNameOffset := sb.Offset;
      sb.Insert(Files[i].Destination);
   end;

   entries.Allocate(Files.n);

   filesOffset := SizeOf(hdr) + sb.Total + (Files.n * SizeOf(ypkfTEntry));

   {setup all file entries}
   currentOffset := 0;

   for i := 0 to Files.n - 1 do begin
      entries.List[i].FileNameOffset := Files.List[i].FileNameOffset;
      entries.List[i].Offset := currentOffset + filesOffset;
      entries.List[i].Size := FileUtils.Exists(Files.List[i].Source);

      inc(currentOffset, entries[i].Size);
   end;

   {setup header}

   ypkf.InitializeHeader(hdr);

   hdr.Files := entries.n;
   hdr.BlobSize := sb.Total;
   hdr.FilesSize := currentOffset;
   hdr.FilesOffset := filesOffset;

   {create output file}
   fFile.Init(f);
   f.New(OutputFN);

   {copy source files to ypk file}
   if(f.Error <> 0) then begin
      ypkf.WriteHeader(f, hdr);

      if(f.Error = 0) then begin

         if(sb.Total > 0) then
            ypkf.WriteBlob(f, sb.Blob, sb.Total);

         if(entries.n > 0) then
            ypkf.WriteEntries(f, entries);

         for i := 0 to Files.n - 1 do begin
            if(fCopy(Files.List[i].Source, f) < 0) then begin
               Result := false;
               break;
            end;

            if(f.Error <> 0) then begin
               Result := false;
               break;
            end;
         end;
      end;
   end;

   {done}
   f.CloseAndDestroy();

   sb.Dispose();
   entries.Dispose();
end;

procedure ypkTBuilder.AddFile(const source, destination: StdString);
var
   f: ypkTBuilderFile;

begin
   f.Source := source;
   f.Destination := destination;

   Files.Add(f);
end;

procedure ypkTBuilder.Dispose();
begin
   Files.Dispose();
end;

END.
