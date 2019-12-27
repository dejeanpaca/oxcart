{
   A small program to test dFile.

   Started On:    14.12.2007.
}

{$MODE OBJFPC}{$H+}{$I-}
PROGRAM test;

   USES uStd, StringUtils, uTiming, uFile, uFileSub, uFileMem, uFileStd;

CONST
   subfile: string = 'defghijklmnopqrstuv';
   cTestFileName = 'test.file.dat';

   {status codes}
   CODE_OK           = 0;
   CODE_ERROR        = 1;

   {test numbers}
   TEST_INVALID      = -1;
   TEST_0            = 0;
   TEST_READ         = 1;
   TEST_WRITE        = 2;
   TEST_MAX          = 2;

   {counts}
   TEST_READ_COUNT   = 128 * 1024 * 1024; {128 MiB}
   TEST_WRITE_COUNT  = 128 * 1024 * 1024; {128 MiB}

   {buffer}
   DEFAULT_BUFFER_SIZE: longint = 8 * 1024;

VAR
   xFile, yFile: TFile;

   buf: shortstring;
   fsize: fileint;
   mFile: pointer = nil;

   testNo: longint = 0;
   bBuffering: boolean = false;


{end the program}
procedure endProgram(code: longint);
begin
   halt(code);
end;

{parse parameters}
procedure parseParams();
var
   code: longint;
   bnBuffering: longint = 1;

begin
   writeln('dFile test...');
   if(paramcount() > 0) then begin
      val(UpCase(paramstr(1)), testNo, code);
      if(code <> 0) then begin
         writeln('Error: Did not provide a numerical value for test number.');
         endProgram(CODE_ERROR);
      end;
      if(testNo < 0) or (testNo > TEST_MAX) then begin
         writeln('Error: Test number must be 0 to ', TEST_MAX);
         endProgram(CODE_ERROR);
      end;
      if(paramcount() > 1) then begin
         val(paramstr(2), bnBuffering, code);
         if(code <> 0) or (bnBuffering < 0) or (bnBuffering > 1) then begin
            writeln('Error: Buffering must be either 0 or 1');
            endProgram(CODE_ERROR);
         end else
            writeln('Buffering set: ', bnBuffering > 0);
         bBuffering := (bnBuffering > 0);
      end;
   end;
end;

{setups buffering on the xFile}
procedure setBuffering();
begin
   if(bBuffering) then
      fBuffer(xFile, DEFAULT_BUFFER_SIZE)
   else fDisposeBuffer(xFile);
end;

{small test for basic functionality}
procedure Test0();
begin
   buf[0] := #26;

   fOpen(xFile, cTestFileName);
   if(fError <> 0) then writeln('Error opening file: ', fError);

   fRead(xFile, buf[1], 50);
   if(fError <> 0) then writeln('Error reading file: ', fError);
   writeln(buf);

   fClose(xFile);
   if(fError <> 0) then writeln('Error closing file: ', fError);

   writeln('Loading file to memory...');
   fsize := fLoadToMem(cTestFileName, mFile);
   if(fError <> 0) then writeln('Error loading file: ', fError);

   writeln('Saving memory to file...');
   fsize := fSaveMem(cTestFileName, mFile^, fsize);
   if(fError <> 0) then writeln('Error saving file: ', fError);

   fNew(xFile, 'out.dat');
   if(fError <> 0) then writeln('Error creating file: ', fError);
   fWrite(xFile, mFile^, fsize);
   if(fError <> 0) then writeln('Error writing to file: ', fError);
   fClose(xFile);
   if(fError <> 0) then writeln('Error closing file: ', fError);

   FreeMem(mFile);
end;

{this test writes 1 GiB, byte by byte}
procedure TestRead();
var
   i: longint;
   buf: longint = 0;

begin
   writeln('Test: READ');

   fOpen(xFile, 'test.dat');
   if(fError <> 0) then begin
      writeln('Error: Can not open test.dat file.'); exit;
   end;

   setBuffering();

   writeln('Reading data...');
   for i := 0 to TEST_READ_COUNT-1 do begin
      fRead(xFile, buf, 1);
      if(fError <> 0) then break;
   end;
   if(fError <> 0) then writeln('Error('+sf(fError)+'): Failed reading byte ', i, ' of the file.');

   fErrorReset();

   fClose(xFile);
   if(fError <> 0) then writeln('Error: Failed to close the file properly.');
end;

{this test writes, byte by byte}
procedure TestWrite();
var
   i: longint;
   buf: longint = 0;

begin
   writeln('Test: WRITE');

   fNew(xFile, 'test.dat');
   if(fError <> 0) then begin
      writeln('Error: Cannot create test.dat file.'); exit();
   end;

   setBuffering();

   writeln('Writing data...');
   for i := 0 to TEST_WRITE_COUNT-1 do begin
      fWrite(xFile, buf, 1);
      if(fError <> 0) then break;
   end;
   if(fError <> 0) then writeln('Error: Failed writing byte ', i, 'of the file.');

   fClose(xFile);
end;

{start timing}
procedure startTimer();
begin
   timStart();
end;

{end timing, and write out how long the test took}
procedure endTimer();
var
   ms: longint;
begin
   timUpdate();
   ms := timElapsed();
   writeln('Test time: ', ms, ' ms');
end;

BEGIN
   parseParams();

   fInit(xFile);
   fInit(yfile);

   writeln('Running test no: ', testNo);
   startTimer();

   case testNo of
      TEST_INVALID: writeln('Error: Invalid test selected.');
      TEST_0:        Test0();
      TEST_READ:     TestRead();
      TEST_WRITE:    TestWrite();
   end;

   endTimer();
   writeln('Done.');

   endProgram(CODE_OK);
END.
