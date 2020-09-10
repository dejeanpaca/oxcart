{
   oxuTFD, textured font descriptor (TFD) support
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuTFD;

INTERFACE

   USES
      uStd, uLog, StringUtils, uFile, {%H-}uFiles,
      {ox}
      uOX;

CONST
   {TFD}
   oxeTFD_INVALID_ID             = $0200;
   oxeTFD_INVALID_VERSION        = $0201;
   oxeTFD_INVALID_ENDIAN         = $0203;
   oxeTFD_OOR                    = $0204;
   oxeTFD_CORRUPT                = $0205;

 
TYPE
   oxTTFDID = array[0..4] of char;

TYPE
   {a texture file descriptor}
   oxTTFD = record
      Width,
      Height,
      SpaceX,
      SpaceY,
      Base,
      Chars,
      CPLine,
      Lines: longint;

      TextureName,
      Name,
      Author,
      Description: string;
   end;

   { file tfd types }
   oxTfTFDHeader = packed record
      ID: oxTTFDID;

      Endian,
      Version: word;
   end;

   oxTfTFD = packed record
      Header: oxTfTFDHeader;

      Width,
      Height,
      SpaceX,
      SpaceY,
      Base,
      Chars,
      CPLine,
      Lines: longint;
      {texture name,
      font name,
      author name,
      description}
   end;

   oxTTFDGlobal = record
      ID: oxTTFDID;
      Version: word;

      {initialize a TFD record}
      procedure Init(out tfd: oxTTFD);

      {load a TFD from file}
      function Load(var tfd: oxTTFD; const fn: string): longint;
      function Load(var tfd: oxTTFD; var f: TFile): longint;

      {save a TFD to file}
      function Save(var tfd: oxTTFD; const fn: string): longint;
      function Save(var tfd: oxTTFD; var f: TFile): longint;
   end;

VAR
   oxTFD: oxTTFDGlobal;
   
IMPLEMENTATION

procedure oxTTFDGlobal.Init(out tfd: oxTTFD);
begin
   ZeroOut(tfd, SizeOf(tfd));
end;

{ LOADING }

function oxTTFDGlobal.Load(var tfd: oxTTFD; const fn: string): longint;
var
   f: TFile;

begin
   result := eNONE;

   fFile.Init(f);
   f.Open(fn);
   
   if(f.error = 0) then begin
      Load(tfd, f);

      if(f.error <> 0) then
         log.e('oxTFD > Error(' + sf(f.error) + ',' + sf(f.IoError) + ') reading file: ' + fn);
   end else
      log.e('oxTFD > Error(' + sf(f.error) + ',' + sf(f.IoError) + ') opening file: ' + fn);

   f.Close();

   if(f.error <> 0) then
      result := eIO;
end;

function oxTTFDGlobal.Load(var tfd: oxTTFD; var f: TFile): longint;
var
   h: oxTfTFD;

begin
   result := eNONE;
   ZeroOut(h, SizeOf(h));

   f.Read(h, SizeOf(h));
   if(f.error = 0) then begin
      { check header }
      if(h.Header.ID = ID) then begin
         if(h.Header.Endian = ENDIAN_WORD) then begin
            if(h.Header.Version = version) then begin

               {assign attributes}
               tfd.Width      := h.Width;
               tfd.Height     := h.Height;
               tfd.SpaceX     := h.SpaceX;
               tfd.SpaceY     := h.SpaceY;
               tfd.Base       := h.Base;
               tfd.Chars      := h.Chars;
               tfd.CPLine     := h.CPLine;
               tfd.Lines      := h.Lines;

               {read strings}
               f.ReadAnsiString(tfd.TextureName);
               if(f.error = 0) then begin
                  f.ReadAnsiString(tfd.Name);

                  if(f.error = 0) then begin
                     f.ReadAnsiString(tfd.Author);

                     if(f.error = 0) then
                        f.ReadAnsiString(tfd.Description);
                  end;
               end;

            end else
               result := oxeTFD_INVALID_VERSION;
         end else
            result := oxeTFD_INVALID_ENDIAN;
      end else
         result := oxeTFD_INVALID_ID;
   end;

   if(f.error <> 0) then
      result := eIO
end;

{ SAVING }

function oxTTFDGlobal.Save(var tfd: oxTTFD; const fn: string): longint;
var
   f: TFile;

begin
   result := eNONE;

   fFile.Init(f);
   f.New(fn);

   if(f.error = 0) then begin
      Save(tfd, f);

      if(f.error <> 0) then
         log.e('oxTFD > Error(' + sf(f.error) + ',' + sf(f.IoError) + ') writing file: ' + fn);
   end else
      log.e('oxTFD > Failed to create: ' + fn);

   f.Close();

   if(f.error <> 0) then
      result := eIO;
end;

function oxTTFDGlobal.Save(var tfd: oxTTFD; var f: TFile): longint;
var
   h: oxTfTFD;

begin
   result := eNONE;

   h.Header.ID          := ID;
   h.Header.Endian      := ENDIAN_WORD;
   h.Header.Version     := Version;

   h.Width           := tfd.Width;
   h.Height          := tfd.Height;
   h.SpaceX          := tfd.SpaceX;
   h.SpaceY          := tfd.SpaceY;
   h.Base            := tfd.Base;
   h.Chars           := tfd.Chars;
   h.CPLine          := tfd.CPLine;
   h.Lines           := tfd.Lines;

   f.Write(h, SizeOf(h));
   if(f.error = 0) then begin
      f.WriteAnsiString(tfd.TextureName);

      if(f.error = 0) then begin
         f.WriteAnsiString(tfd.Name);

         if(f.error = 0) then begin
            f.WriteAnsiString(tfd.Author);

            if(f.error = 0) then
               f.WriteAnsiString(tfd.Description);
         end;
      end;
   end;

   if(f.error <> 0) then
      result := eIO;
end;

INITIALIZATION

   oxTFD.ID := 'OXTFD';
   oxTFD.Version := $0100;

END.
