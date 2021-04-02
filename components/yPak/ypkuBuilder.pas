{
   ypkuBuilder, yPak file builder
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ypkuBuilder;

INTERFACE

   USES
      uStd, ustrBlob, StringUtils,
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

      ErrorDescription: string;

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
   ypkf: ypkTFile;

procedure raiseError(const description: string);
begin
   ErrorDescription := description;
   f.CloseAndDestroy();
   Result := false;
end;

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
   entries.n := Files.n;

   filesOffset := SizeOf(hdr) + sb.Total + (Files.n * SizeOf(ypkfTEntry));

   {setup all file entries}
   currentOffset := 0;

   for i := 0 to Files.n - 1 do begin
      entries.List[i].FileNameOffset := Files.List[i].FileNameOffset;
      entries.List[i].Offset := currentOffset + filesOffset;
      entries.List[i].Size := FileUtils.Exists(Files.List[i].Source);

      inc(currentOffset, entries[i].Size);
      inc(Total, entries[i].Size);
   end;

   {setup header}

   ypkf.InitializeHeader(hdr);

   hdr.Files := entries.n;
   hdr.BlobSize := sb.Total;
   hdr.FilesSize := currentOffset;
   hdr.FilesOffset := filesOffset;

   Total := hdr.DataSize();

   {create output file}
   fFile.Init(f);
   f.New(OutputFN);

   ypkTFile.Initialize(ypkf);
   ypkf.f := @f;

   {copy source files to ypk file}
   if(f.Error = 0) then begin
      ypkf.WriteHeader(hdr);

      if(f.Error <> 0) then begin
         raiseError('Failed to write ypk file header');
         exit(False);
      end;

      if(sb.Total > 0) then begin
         ypkf.WriteBlob(sb.Blob, sb.Total);

         if(f.Error <> 0) then begin
            raiseError('Failed to write blob (' + sf(sb.Total) + ') to ypk ' + f.GetErrorString());
            exit(false);
         end;
      end;

      if(entries.n > 0) then begin
         ypkf.WriteEntries(entries);

         if(f.Error <> 0) then begin
            raiseError('Failed to write entries to ypk ' + f.GetErrorString());
            exit(false);
         end;
      end;

      for i := 0 to Files.n - 1 do begin
         if(fCopy(Files.List[i].Source, f) < 0) then begin
            if(f.Error <> 0) then
               raiseError('Failed to write to ypk ' + f.GetErrorString())
            else
               raiseError('Failed to read source file');

            break;
         end;

         if(f.Error <> 0) then begin
            raiseError('File I/O error: ' + f.GetErrorString());
            break;
         end;
      end;

      {done}
      f.CloseAndDestroy();
   end else
      raiseError('Failed to create ypk file');

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
