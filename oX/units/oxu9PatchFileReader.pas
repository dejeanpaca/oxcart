{
   oxu9PatchFileReader, reads oX specific 9patch files
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxu9PatchFileReader;

INTERFACE

   USES
      sysutils,
      uStd, uFile, uFileHandlers, uLog, StringUtils,
      {ox}
      oxuTypes,
      oxuFile, oxu9Patch, oxu9PatchFile;

IMPLEMENTATION

TYPE
   TPatchRow = record
      left,
      middle,
      right: oxTDimensions;

   end;

VAR
   ext: fhTExtension;
   handler: fhTHandler;

procedure handleFile(var f: TFile; var data: oxTFileRWData);
var
   s: StdString;

   row: TPatchRow;
   rows: array[0..2] of TPatchRow;

   patch: oxT9Patch;

   {break down a line into its components}
   function breakdown(): boolean;
   var
      wd: StdString;

   begin
      f.Readln(s);

      if(f.Error <> 0) then
         exit(false);

      {get the left component}
      wd := CopyToDel(s);

      if(not row.left.FromString(wd)) then
         exit(false);

      {get the middle component (it's a single number, not WxD)}
      wd := CopyToDel(s);

      if(not loopint.TryParse(wd, row.middle.w)) then
         exit(false);

      row.middle.h := row.middle.w;

      {get the right component}
      wd := CopyToDel(s);

      if(not row.right.FromString(wd)) then
         exit(false);

      Result := true;
   end;

begin
   {top}
   if(not breakdown()) then
      exit;

   rows[0] := row;

   {middle}
   if(not breakdown()) then
      exit;

   rows[1] := row;

   {bottom}
   if(not breakdown()) then
      exit;

   rows[2] := row;

   {TODO: Do some validation}

   patch := oxT9Patch.Create();

   {get sizes}

   patch.Sizes.Width := rows[0].left.w + rows[0].middle.w + rows[0].right.w;
   patch.Sizes.Height := rows[0].left.h + rows[1].left.h + rows[2].left.h;

   {top}
   patch.Sizes.TopLeft[0]  := rows[0].left.w;
   patch.Sizes.TopLeft[1]  := rows[0].left.h;

   patch.Sizes.Up[0]       := rows[0].middle.w;
   patch.Sizes.Up[1]       := rows[0].middle.h;

   patch.Sizes.TopRight[0] := rows[0].right.w;
   patch.Sizes.TopRight[1] := rows[0].right.h;

   {middle}
   patch.Sizes.Left[0]     := rows[1].left.w;
   patch.Sizes.Left[1]     := rows[1].left.h;

   patch.Sizes.Center[0]   := rows[1].middle.w;
   patch.Sizes.Center[1]   := rows[1].middle.h;

   patch.Sizes.Right[0]    := rows[1].right.w;
   patch.Sizes.Right[1]    := rows[1].right.h;

   {bottom}
   patch.Sizes.BottomLeft[0]  := rows[2].left.w;
   patch.Sizes.BottomLeft[1]  := rows[2].left.h;

   patch.Sizes.Down[0]        := rows[2].middle.w;
   patch.Sizes.Down[1]        := rows[2].middle.h;

   patch.Sizes.BottomRight[0] := rows[2].right.w;
   patch.Sizes.BottomRight[1] := rows[2].right.h;
end;

procedure handle(data: pointer);
begin
   handleFile(oxTFileRWData(data^).f^, oxTFileRWData(data^));
end;

INITIALIZATION
   oxf9Patch.Readers.RegisterHandler(handler, '9patch', @handle);
   oxf9Patch.Readers.RegisterExt(ext, '.9p', @handler);

END.
