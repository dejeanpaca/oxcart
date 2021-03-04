{$INCLUDE oxheader.inc}
PROGRAM test;

   USES uLog, uStd, uFileHandlers;

CONST
   logName: string = 'test.log';

   bmpLoaderName: string = 'BMP';
   bmpExtension:  string = '.bmp';
   tgaLoaderName: string = 'TGA';
   tgaExtension:  string = '.tga';

VAR
   inf: fhTHandlerInfo;
   bmpLoader: fhTHandler;
   bmpExt:    fhTExtension;
   tgaLoader: fhTHandler;
   tgaExt:    fhTExtension;

   f: file;
   fn: string;

procedure bmpLoad();
begin
end;

procedure tgaLoad();
begin
end;

BEGIN
   logInitStd(logName, '', logcREWRITE);

   {BMP LOADER}
   {setup the extension}
   bmpExt.ext := bmpExtension;
   bmpExt.Handler := @bmpLoader;

   {setup the loader}
   bmpLoader.Name := bmpLoaderName;
   bmpLoader.Handle := fhTHandleProc(@bmpLoad);

   {register the extension and the loader}
   {$PUSH}{$HINTS OFF}fhRegisterExt(@bmpExt, inf);{$POP}
   fhRegisterHandler(@bmpLoader, inf);

   {TGA LOADER}
   {setup the extension}
   tgaExt.ext := tgaExtension;
   tgaExt.Handler := @tgaLoader;

   {setup the loader}
   tgaLoader.Name := tgaLoaderName;
   tgaLoader.Handle := fhTHandleProc(@tgaLoad);

   {register the extension and the loader}
   fhRegisterExt(@tgaExt, inf);
   fhRegisterHandler(@tgaLoader, inf);

   {try to load a file}
   fn := 'img.tga';
   {$PUSH}{$HINTS OFF}fhLoad(fn, inf, f, nil);{$POP}
   if(fhError <> 0) then writeln('Error: ', fhError, '(',ioE,')');
   fn := 'img.bmp';
   fhLoad(fn, inf, f, nil);
   if(fhError <> 0) then writeln('Error: ', fhError, '(',ioE,')');
END.
