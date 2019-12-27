{
   testfs, tests a simple filesystem based on YPAK

   Started On:    06.03.2011.
}

PROGRAM testfs;

   USES sysutils, uLog, uStd, uFile, uFileStd, ypkuFS,
      uImage, imguTGA, imguwTGA;

CONST
   f1n = 'values/strings.xml';
   f2n = 'drawable-hdpi/asteroid2.tga';

VAR
   img: imgTImage;
   imgerror: longint;
   f: TFile;
   a: TFile;
   buf: array[0..4*1024*1024-1] of byte;
   i: longint;

BEGIN
   logInitStd('testfs.log', 'YPK VFS Test', logcREWRITE);

   {initialize filesystem}
   ypkfsAdd('data.ypk');
   ypkfsMount();

   {try to find some files}
   writeln(f1n, ': ', fExist(f1n));
   writeln(f2n, ': ', fExist(f2n));

   {try to extract a file}
   writeln('Extracting file: ', f1n);
   fOpen(f, f1n);
   if(fError = 0) then begin

      fNew(a, ExtractFileName(f1n));
      if(fError = 0) then begin
         fBuffer(a, fcMinimumBufferSize);
         fSeek(a, SizeOf(a)-1);

         for i := 0 to (fSize(f)-1) do begin
            fRead(f, buf, 1);
            fWrite(a, buf, 1);
         end;
         fClose(a);
      end else
         writeln('Cannot create new file.');
   end else writeln('Cannot open file.');

   fClose(f);

   {try to load the image from fs}
   writeln('Loading image from fs: ', f1n);
   imgerror := imgLoad(img, f2n);
   writeln('status: ', imgError, ' ', fError, ' ', ioE);
   writeln('Writing image: ', f1n);
   imgerror := imgWrite(img, 'new.tga');
   writeln('status: ', imgError, ' ', fError, ' ', ioE);


   {done}
   ypkfsUnmount();
END.
