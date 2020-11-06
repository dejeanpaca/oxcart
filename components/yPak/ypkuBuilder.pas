{
   yPakU, yPak tool base unit
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ypkuBuilder;

INTERFACE

   USES
      uStd, uFile, uFileUtils, ustrBlob,
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

      procedure Reset();
      procedure Build();
      procedure AddFile(const source, destination: StdString);
   end;

IMPLEMENTATION

{ ypkTBuilder }

procedure ypkTBuilder.Reset();
begin
   Files.Dispose();
end;

procedure ypkTBuilder.Build();
var
   i,
   currentOffset,
   filesOffset: loopint;

   sb: TShortStringBlob;
   entries: ypkfTEntries;

   hdr: ypkfTHeader;

begin
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

   { TODO: write to file }

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

INITIALIZATION
END.
