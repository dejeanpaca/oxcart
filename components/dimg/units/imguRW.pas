{
   imguRW, image file read/write support for dImage
   Copyright (C) 2007. Dejan Boras

   Started On:    02.04.2013.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT imguRW;

INTERFACE

USES
   uStd, uLog, StringUtils,
      uFileHandlers, uFile, {%H-}uFiles,
      uImage, imguOperations;

TYPE
   imgPFileData = ^imgTFileData;

   imgTRWProperties = record
      SupressLog,
      SetToDefaultOrigin: boolean;
      Error: imgTErrorData;
   end;

   { imgTFileData }

   imgTFileData = record
      Image: imgTImage;
      Error: longint;
      eDescription: string;
      FileType: longword;
      f: PFile;
      fn: string;

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
      procedure PostLoad(var props: imgTRWProperties);
   end;

   { imgTFileGlobal }

   imgTFileGlobal = record
      public
      Loaders: fhTHandlerInfo; {image loaders}
      Writers: fhTHandlerInfo; {image writers}

      {initialize a loader data record}
      procedure Init(out props: imgTRWProperties);
      {initialize a loader data record}
      procedure Init(out ld: imgTFileData);
      {fills out error data from file loader data}
      procedure SetErrorData(var errorData: imgTErrorData; const data: imgTFileData);

      {load a image from a file}
      function Load(var image: imgTImage; const fileName: string): longint;
      function Load(var image: imgTImage; const fileName: string; var props: imgTRWProperties): longint;
      function Load(var image: imgTImage; const fileName: string; var f: TFile; var props: imgTRWProperties): longint;

      {load a image from a file}
      function Write(var image: imgTImage; const fileName: string): longint;
      function Write(var image: imgTImage; const fileName: string; var props: imgTRWProperties): longint;

      { LOGGING }

      {log all image loaders and writes}
      procedure LogHandlers();
   end;

VAR
   imgFile: imgTFileGlobal;

IMPLEMENTATION

procedure imgTFileGlobal.Init(out props: imgTRWProperties);
begin
   ZeroOut(props, SizeOf(props));
   props.setToDefaultOrigin := img.settings.setToDefaultOrigin;
end;

procedure imgTFileGlobal.Init(out ld: imgTFileData);
begin
   ZeroOut(ld, SizeOf(ld));
end;

procedure imgTFileGlobal.SetErrorData(var errorData: imgTErrorData; const data: imgTFileData);
begin
   errorData.e := data.error;

   if(data.f <> nil) then begin
      errorData.f    := data.f^.error;
      errorData.io   := data.f^.ioError;
   end;

   errorData.description := data.eDescription;
end;

procedure imgLogError(const fn, what: string; const data: imgTFileData);
begin
   if(not img.settings.log) then begin
      log.i(imgcName + ' > error ' + what + ': ' + fn);

      if(data.f <> nil) then
         log.i('Error: ' + sf(data.error) + ', file: ' + sf(data.f^.error) + ', IO: ' + sf(data.f^.ioError))
      else
         log.i('Error: ' + sf(data.error));
   end;
end;

function imgTFileGlobal.Load(var image: imgTImage; const fileName: string): longint;
var
   props: imgTRWProperties;

begin
   Init(props);

   Result := Load(image, fileName, props);
end;

function imgTFileGlobal.Load(var image: imgTImage; const fileName: string; var props: imgTRWProperties): longint;
var
   f: TFile;

begin
   fFile.Init(f);

   Result := Load(image, fileName, f, props);
end;

function imgTFileGlobal.Load(var image: imgTImage; const fileName: string; var f: TFile; var props: imgTRWProperties): longint;
var
   data: imgTFileData;
   fd: fhTFindData;
   {if file is existing, and not needed to be opened}
   existing: boolean;

begin
   Result := eNONE;

   assert(@image <> nil, 'imgLoad received a nil image parameter.');

   {initialize}
   if(fileName <> '') then begin
      Init(data);

      {set up the loader data}
      data.f := @f;
      data.fn := fileName;

      {check if the file is already open, in which case we don't do any file open/close}
      existing := f.fMode <> fcfNONE;

      if(img.Settings.logNameAlways) and (not props.supressLog) and (not existing) then
         log.i(imgcName + ' > Loading: ' + fileName);

      {find a file handler for this image}
      imgFile.Loaders.FindHandler(fileName, fd);

      {if a loader has been found}
      if(fd.Handler <> nil) then begin
         if(image = nil) then
            image := imgTImage.Create()
         else
            image.DisposeData();

         data.Image := image;

         {store the fileName if specified}
         if(img.settings.storeFileNames = true) then
            image.FileName := fileName;

         {open the file if instructed to do so}
         if(not fd.handler^.DoNotOpenFile) and (not existing) then begin
            f.Open(fileName);
            if(f.error <> 0) then begin
               SetErrorData(props.error, data);
               exit(eIO);
            end;

            if(f.GetSize() <= 0) then begin
               f.CloseAndDestroy();
               props.error.e := eEMPTY;
               exit(eEMPTY);
            end;
         end;

         {call the loader}
         fd.handler^.CallHandler(@data);

         {if there is no error, perform post-loading tasks}
         if(data.error = 0) then
            data.PostLoad(props)
         else begin
            SetErrorData(props.error, data);

            if(not props.supressLog) then
               imgLogError(fileName, 'loading', data);
         end;

         {close the file if instructed to do so}
         if(not fd.handler^.DoNotOpenFile) and (not existing) then
            f.CloseAndDestroy();

         Result := data.Error;

         if(data.Error <> 0) and (f.Error = 0) then
            log.e('Image handler (' + fd.Handler^.Name + ') returned error ' + GetErrorCodeName(data.Error) + ' for: ' + image.FileName);
      end else begin
         props.error.f := imgeLOADER_NOT_FOUND;
         exit(imgeLOADER_NOT_FOUND);
      end;
   end;
end;

function imgTFileGlobal.Write(var image: imgTImage; const fileName: string): longint;
var
   props: imgTRWProperties;

begin
   Init(props);

   Result := Write(image, fileName, props);
end;

function imgTFileGlobal.Write(var image: imgTImage; const fileName: string; var props: imgTRWProperties): longint;
var
   data: imgTFileData;
   fd: fhTFindData;
   f: TFile;

begin
   Result := eNONE;
   assert(@image <> nil, 'imgWrite received a nil image parameter.');

   {initialize}
   if(length(fileName) <> 0) then begin
      fFile.Init(f);
      Init(data);

      {set up the loader data}
      data.f   := @f;
      data.image := image;
      data.fn := fileName;

      if(img.Settings.logNameAlways) and (not props.supressLog) then
         log.i(imgcName+' > Writing: ' + fileName);

      {call the file handler which will figure out what loader to call}
      imgFile.Writers.FindHandler(fileName, fd);

      {if a loader has been found}
      if(fd.handler <> nil) then begin
         {open the file if instructed to do so}
         if(not fd.handler^.DoNotOpenFile) then begin
            f.New(fileName);

            if(f.error <> 0) then
               exit(eIO);
         end;

         {call the loader}
         fd.handler^.CallHandler(@data);
         if(data.error <> 0) then begin
            SetErrorData(props.error, data);

            if(not props.supressLog) then
               imgLogError(fileName, 'writing', data);
         end;

         {close the file if instructed to do so}
         if(not fd.Handler^.DoNotOpenFile) then begin
            f.CloseAndDestroy();

            if(f.error <> 0) then begin
               data.error := eIO;
               SetErrorData(props.error, data);
               exit(eIO);
            end;
         end;

		   exit(data.error);
      end else begin
         props.error.e := imgeWRITER_NOT_FOUND;
         exit(imgeWRITER_NOT_FOUND);
      end;
   end;
end;

{ LOADER HELPER ROUTINES }

procedure imgTFileData.Calculate();
begin
   image.Calculate();
end;

function imgTFileData.Allocate(): longint;
begin
   Result := image.Allocate();
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

   if(pal.Valid(image)) and (fileType = imgcFILE_TYPE_NORMAL) then begin
      palette := image.palette;

      {if there are no padding bytes we can read in the table directly}
      if(padBytes = 0) then begin
         BlockRead(image.palette.Data^, image.palette.GetSize());

         if(error <> 0) then
            exit(error);
      {otherwise read bit by bit and skip the padding bytes}
      end else begin
         {get the number of elements and channels}
         elements := palette.nColors;
         channels := img.PIXFChannels(palette.PixF);

         pos := 0;
         for i := 0 to (elements-1) do begin
            {read the current color and padding bytes}
            BlockRead(buf, fileint(channels) + fileint(padBytes));

            if(error <> 0) then
               exit(error);

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
   Result := TFile(f^).Seek(pos);
   if(TFile (f^).error <> 0) then begin
      error := eIO;
      Result := -1;
   end;
end;

function imgTFileData.BlockRead(out buf; size: fileint): fileint;
begin
   Result := TFile(f^).Read(buf, size);
   if(TFile(f^).error <> 0) then begin
      error := eIO;
      Result := -1;
   end;
end;

function imgTFileData.BlockWrite(var buf; size: fileint): fileint;
begin
   Result := TFile(f^).Write(buf, size);
   if(TFile(f^).error <> 0) then begin
      error := eIO;
      Result := -1;
   end;
end;

procedure imgTFileData.PostLoad(var props: imgTRWProperties);
begin
   {set the origin}
   if(props.setToDefaultOrigin) then
      ProcessOrigin();

   {set the colors}
   ProcessFormat();
   {set the channel order}
   ProcessColorChannelOrder();
end;

{ LOGGING }

procedure imgTFileGlobal.LogHandlers();
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

   if(imgFile.Loaders.nExtensions > 0) then
      writeLog('Loaders: ', imgFile.Loaders.eStart);

   if(imgFile.Writers.nExtensions > 0) then
      writeLog('Writers: ', imgFile.Writers.eStart);

   log.Leave();
end;

END.

