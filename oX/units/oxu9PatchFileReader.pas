{
   oxu9PatchFileReader, reads oX specific 9patch files
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxu9PatchFileReader;

INTERFACE

   USES
      sysutils,
      uStd, uFile, uFileHandlers, uLog, StringUtils,
      {ox}
      oxuTypes, oxuTexture, oxuTextureGenerate,
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
   texture: oxTTexture;

   p: loopint;

   {break down a line into its components}
   function breakdown(): boolean;
   var
      wd: StdString;

   begin
      f.Readln(s);

      if(f.Error <> 0) then
         exit(false);

      {get the left component}
      wd := CopyToDel(s, '-');
      StripWhitespace(wd);

      if(not row.left.FromString(wd)) then
         exit(false);

      {get the middle component (it's a single number, not WxD)}
      wd := CopyToDel(s, '-');
      StripWhitespace(wd);

      if(not loopint.TryParse(wd, row.middle.w)) then
         exit(false);

      row.middle.h := row.middle.w;

      {get the right component (what is left of the current line)}
      StripWhitespace(s);

      if(not row.right.FromString(s)) then
         exit(false);

      Result := true;
   end;

begin
   texture := nil;

   row.left := oxNullDimensions;
   row.middle := oxNullDimensions;
   row.right := oxNullDimensions;

   {top}
   if(not breakdown()) then begin
      data.SetError(eINVALID, 'Failed to process top row');
      exit;
   end;

   rows[0] := row;

   {middle}
   if(not breakdown()) then begin
      data.SetError(eINVALID, 'Failed to process middle row');
      exit;
   end;

   rows[1] := row;

   {bottom}
   if(not breakdown()) then begin
      data.SetError(eINVALID, 'Failed to process bottom row');
      exit;
   end;

   rows[2] := row;

   repeat
      f.Readln(s);
      p := pos('texture: ', s);

      if(p > 0) then begin
         {we have a texture}
         s := Copy(s, Length('texture: ') + 1, Length('texture: ') - p + 2);

         oxTextureGenerate.Generate(ExtractFilePath(f.fn) + s, texture);

         break;
      end;
   until f.EOF() or (f.Error <> 0);

   if(f.Error <> 0) then
      exit;

   {TODO: Do some validation}

   rows[0].middle.h := rows[0].left.h;
   rows[1].middle.h := rows[1].left.h;
   rows[2].middle.h := rows[2].left.h;

   patch := oxT9Patch.Create();

   patch.Texture := texture;

   {get sizes}

   patch.Sizes.Width  := rows[0].left.w + rows[0].middle.w + rows[0].right.w;
   patch.Sizes.Height := rows[0].left.h + rows[1].middle.h + rows[2].right.h;

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

   patch.Build();

   data.Result := patch;
end;

procedure handle(data: pointer);
begin
   handleFile(oxTFileRWData(data^).f^, oxTFileRWData(data^));
end;

INITIALIZATION
   oxf9Patch.Readers.RegisterHandler(handler, '9patch', @handle);
   oxf9Patch.Readers.RegisterExt(ext, '.9p', @handler);

END.
