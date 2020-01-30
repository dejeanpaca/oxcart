{
   imguRW, image file read/write support for dImage
   Copyright (C) 2007. Dejan Boras

   Started On:    02.04.2013.
}

{$INCLUDE oxheader.inc}
UNIT imguRW;

INTERFACE

   USES
      uStd, uLog,
      uFileHandlers, uFile, {%H-}uFiles,
      uImage, imguOperations,
      {oX}
      uOX, oxuFile, oxuGlobalInstances;

TYPE
   imgPFileData = ^imgTFileData;
   imgPRWOptions = ^imgTRWOptions;

   imgTRWOptions = record
      SupressLog,
      SetToDefaultOrigin: boolean;
      Image: imgTImage;
   end;

   { imgTFileData }

   imgTFileData = record
      Image: imgTImage;
      PFile: oxPFileRWData;
      f: PFile;

      {These routines are meant as a help for loaders to make performing
      common operations easier. This also helps to reduce the size of code
      when multiple loaders are used as it reduces the number of redundant
      operations(operations each loader performs). They can also be used
      when manually manipulating images.}

      {used by loaders to calculate the image size and number of pixels}
      procedure Calculate();
      {used by loaders to allocate memory for the image}
      function Allocate(): longint;
      {used by loaders to read the palette from the file}
      function ReadPalette(padBytes: longint): longint;
      {process the image origin}
      procedure ProcessOrigin();
      {process the image colors}
      procedure ProcessFormat();
      {process the image channel order}
      procedure ProcessColorChannelOrder();

      {seeks a image file}
      function Seek(pos: fileint): fileint;
      {reads in a image block}
      function BlockRead(out buf; size: fileint): fileint;
      {reads in a image block}
      function BlockWrite(var buf; size: fileint): fileint;

      {perform post loading tasks}
      procedure PostLoad(var props: imgTRWOptions);

      procedure SetError(newError: TError; const description: string = '');
      function GetError(): TError;
   end;

   imgPFile = ^imgTFile;

   { imgTFile }

   imgTFile = object(oxTFileRW)
      {initialize a loader data record}
      class procedure Init(out props: imgTRWOptions); static;
      {initialize a loader data record}
      class procedure Init(out ld: imgTFileData); static;

      {read an image}
      function Read(const name: string): imgTImage;
      {read an image}
      function Read(const name: string; var options: imgTRWOptions): loopint;

      {load a image from a file}
      function Write(var image: imgTImage; const fileName: string): loopint;
      function Write(var image: imgTImage; const fileName: string; var options: imgTRWOptions): loopint;

      function OnRead(var data: oxTFileRWData): loopint; virtual;
      function OnWrite(var data: oxTFileRWData): loopint; virtual;

      { LOGGING }

      {log all image loaders and writes}
      procedure LogHandlers();
   end;

VAR
   imgFile: imgTFile;

IMPLEMENTATION

class procedure imgTFile.Init(out props: imgTRWOptions);
begin
   ZeroPtr(@props, SizeOf(props));
   props.setToDefaultOrigin := img.settings.setToDefaultOrigin;
end;

class procedure imgTFile.Init(out ld: imgTFileData);
begin
   ZeroPtr(@ld, SizeOf(ld));
end;

function imgTFile.Read(const name: string): imgTImage;
var
   options: imgTRWOptions;

begin
   Init(options);

   inherited Read(name, @options);

   Result := options.Image;
end;

function imgTFile.Read(const name: string; var options: imgTRWOptions): loopint;
begin
   Result := inherited Read(name, @options);
end;

function imgTFile.Write(var image: imgTImage; const fileName: string): loopint;
var
   options: imgTRWOptions;

begin
   Init(options);
   options.Image := image;

   Result := inherited Write(fileName, @options);
end;

function imgTFile.Write(var image: imgTImage; const fileName: string; var options: imgTRWOptions): loopint;
begin
   options.Image := image;
   Result := inherited Write(fileName, @options);
end;

function imgTFile.OnRead(var data: oxTFileRWData): loopint;
var
   pOptions: imgPRWOptions;
   options: imgTRWOptions;
   imageData: imgTFileData;

begin
   Init(imageData);
   pOptions := data.Options;

   if(pOptions = nil) then begin
      Init(options);
      pOptions := @options;
   end;

  if(pOptions^.Image = nil) then
      pOptions^.Image := imgTImage.Create();

   imageData.Image := pOptions^.Image;
   imageData.PFile := @data;
   imageData.f := data.f;

   data.External := @imageData;
   data.Handler^.CallHandler(@data);

   Result := data.GetError();

   {finishing touches}
   if(Result = 0) then
       imageData.PostLoad(pOptions^);
end;

function imgTFile.OnWrite(var data: oxTFileRWData): loopint;
var
   imageData: imgTFileData;

begin
   Init(imageData);

   if(data.Options = nil) then
       exit(imgeGENERAL);

   imageData.Image := imgPRWOptions(data.Options)^.Image;
   imageData.PFile := @data;
   imageData.f := data.f;

   data.External := @imageData;
   data.Handler^.CallHandler(@data);

   Result := data.GetError();
end;

{ LOADER HELPER ROUTINES }

procedure imgTFileData.Calculate();
begin
   image.Calculate();
end;

function imgTFileData.Allocate(): longint;
begin
   Result := Image.Allocate();
end;

function imgTFileData.ReadPalette(padBytes: longint): longint;
var
   i,
   elements,
   channels,
   pos: longint;
   buf: array[0..31] of byte;
   palette: imgTPalette;

begin
   Result := eNONE;

   if(pal.Valid(image)) then begin
      palette := image.palette;

      {if there are no padding bytes we can read in the table directly}
      if(padBytes = 0) then begin
         BlockRead(image.palette.Data^, image.palette.GetSize());

         if(PFile^.Error <> 0) then
            exit(PFile^.Error);
      {otherwise read bit by bit and skip the padding bytes}
      end else begin
         {get the number of elements and channels}
         elements := palette.nColors;
         channels := img.PIXFChannels(palette.PixF);

         pos := 0;
         for i := 0 to (elements-1) do begin
            {read the current color and padding bytes}
            BlockRead(buf, fileint(channels) + fileint(padBytes));

            if(PFile^.Error <> 0) then
               exit(PFile^.Error);

            {move the color into the palette}
            move(buf, (image.palette.Data + pos)^, channels);
            inc(pos, channels);
         end;
      end;
   end;
end;

procedure imgTFileData.ProcessOrigin();
begin
   imgOperations.SetDefaultOrigin(image);
end;

procedure imgTFileData.ProcessFormat();
begin
   if(img.settings.setToDefaultPixelFormat) then
      imgOperations.SetDefaultPixelFormat(image);
end;

procedure imgTFileData.ProcessColorChannelOrder();
begin
   if(img.settings.setToDefaultColorChannelOrder) then
      imgOperations.SetDefaultColorChannelOrder(image);
end;


function imgTFileData.Seek(pos: fileint): fileint;
begin
   Result := f^.Seek(pos);

   if(f^.Error <> 0) then begin
      PFile^.SetError(eIO);
      Result := -1;
   end;
end;

function imgTFileData.BlockRead(out buf; size: fileint): fileint;
begin
   Result := f^.Read(buf, size);

   if(f^.Error <> 0) then begin
      PFile^.SetError(eIO);
      Result := -1;
   end;
end;

function imgTFileData.BlockWrite(var buf; size: fileint): fileint;
begin
   Result := f^.Write(buf, size);

   if(f^.Error <> 0) then begin
      PFile^.SetError(eIO);
      Result := -1;
   end;
end;

procedure imgTFileData.PostLoad(var props: imgTRWOptions);
begin
   {set the origin}
   if(props.setToDefaultOrigin) then
      ProcessOrigin();

   {set the colors}
   ProcessFormat();
   {set the channel order}
   ProcessColorChannelOrder();
end;

procedure imgTFileData.SetError(newError: TError; const description: string);
begin
   PFile^.SetError(newError, description);
end;

function imgTFileData.GetError(): TError;
begin
   Result := PFile^.Error;
end;

{ LOGGING }

procedure imgTFile.LogHandlers();
var
   curext: fhPExtension = nil;

procedure writeLog(const s: string; start: fhPExtension);
var
   exts: string = '';

begin
   curext := start;
   if(curext <> nil) then repeat
      if(curext^.Next <> nil) then
         exts := exts + curext^.Ext + ' '
      else
         exts := exts + curext^.ext;

      curext := curext^.Next;
   until (curext = nil);

   log.i(s + exts);
end;

begin
   log.Enter('dImage');

   if(imgFile.Readers.nExtensions > 0) then
      writeLog('Readers: ', imgFile.Readers.eStart);

   if(imgFile.Writers.nExtensions > 0) then
      writeLog('Writers: ', imgFile.Writers.eStart);

   log.Leave();
end;

INITIALIZATION
   imgFile.Create();

   oxGlobalInstances.Add('imgTFile', @imgFile);

END.
