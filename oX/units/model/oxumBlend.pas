{
   oxumBlend, blender model loader for oX
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxumBlend;

{Blender model loader for oX.

- This loader is based on the v3.0 of the blender file format and may malfunction
with higher(and maybe with lower?) versions since their structure may be
different, but I am not quite sure about that.
- This loader currently does not support any kind of animations.}

INTERFACE

   USES
      uStd, sysutils, StringUtils, uLog,
      uFile, uFileHandlers,
      {oX}
      uOX, oxuModelFile, oxuFile;

IMPLEMENTATION

TYPE
   PLoaderData = ^TLoaderData;
   TLoaderData = record
      Version: longint;
      BigEndian,
      Is64: boolean;
   end;

   TBlendHeader = packed record
      id: array[0..6] of char;
      PointerSize: char;
      Endiannes: char;
      VersionNumber: array[0..2] of char;
   end;

   {file block for 32 bit format}
   TBlendFileBlock32 = packed record
      Code: array[0..3] of char;
      Size: longint;
      OldMemoryAddress: Int32;
      SDNAIndex: longint;
      Count: longint;
   end;

   {file block for 64 bit format}
   TBlendFileBlock64 = packed record
      Code: array[0..3] of char;
      Size: longint;
      OldMemoryAddress: Int64;
      SDNAIndex: longint;
      Count: longint;
   end;

   {universal block that ends up with the data from 32 and 64 bit blocks}
   TBlendFileBlock = record
      Code: array[0..3] of char;
      Size: longint;
      OldMemoryAddress: int64; {cover both 32 and 64 bit}
      SDNAIndex: longint;
      Count: longint;
   end;

VAR
   mBlendLoader: fhTHandler;
   mBlendExt: fhTExtension;

function readFileBlock(var data: oxTFileRWData; out fileBlock: TBlendFileBlock): boolean;
var
   f32: TBlendFileBlock32;
   f64: TBlendFileBlock64;
   loaderData: PLoaderData;

begin
   loaderData := data.LoaderData;
   if(loaderData^.is64) then begin
      data.f^.Read(f64, SizeOf(TBlendFileBlock64));

      fileBlock.Code := f64.Code;
      fileBlock.Count := f64.Count;
      fileBlock.OldMemoryAddress := f64.OldMemoryAddress;
      fileBlock.SDNAIndex := f64.SDNAIndex;
      fileBlock.Size := f64.Size;
   end else begin
      data.f^.Read(f32, SizeOf(TBlendFileBlock32));

      fileBlock.Code := f32.Code;
      fileBlock.Count := f32.Count;
      fileBlock.OldMemoryAddress := f32.OldMemoryAddress;
      fileBlock.SDNAIndex := f32.SDNAIndex;
      fileBlock.Size := f32.Size;
   end;

   Result := false;
end;

{process a normal chunk}
procedure readBlend(var data: oxTFileRWData);
var
   header: TBlendHeader;
   loaderData: PLoaderData;
   fileBlock: TBlendFileBlock;

begin
   loaderData := data.LoaderData;

   data.f^.Read(header, SizeOf(header));
   if(header.id <> 'BLENDER') then begin
      data.SetError(eINVALID, 'Invalid file identifier');
      exit;
   end;

   if(header.PointerSize = '-') then
      loaderData^.Is64 := true
   else if(header.PointerSize = '_') then
      loaderData^.Is64 := false
   else begin
      data.SetError(eINVALID, 'Invalid/unknown endian format');
      exit;
   end;

   if(header.Endiannes = 'V') then begin
      loaderData^.BigEndian := true;
      data.SetError(eINVALID, 'Unsupported endian format');
      exit;
   end else if(header.Endiannes = 'v') then
      loaderData^.BigEndian := false
   else begin
      data.SetError(eINVALID, 'Invalid/unknown endian format');
      exit;
   end;

   loaderData^.Version := ('' + header.VersionNumber).ToInt64();
   if(oxfModel.LogExtended) then
      log.v(data.FileName + ' ' + sf(loaderData^.Version) + ', 64: ' + sf(loaderData^.Is64) + ', big-endian: ' + sf(loaderData^.BigEndian));

   {go through file blocks}
   repeat
      readFileBlock(data, fileBlock);
      data.f^.Seek(fileBlock.Size, fSEEK_CUR);
   until (data.f^.EOF()) or (fileBlock.Code = 'ENDB');
end;

{IMPORT ROUTINE}
procedure mLoad(data: pointer);
var
   pData: oxPFileRWData;
   loaderData: TLoaderData;

begin
   pData := data;
   pData^.LoaderData := @loaderData;

   readBlend(oxTFileRWData(pData^));
end;

procedure init();
begin
   oxfModel.Loaders.RegisterHandler(mBlendLoader, 'blend', @mLoad);
   oxfModel.Loaders.RegisterExt(mBlendExt, '.blend', @mBlendLoader);
end;

INITIALIZATION
   ox.Init.iAdd('model.blend', @init);
END.
