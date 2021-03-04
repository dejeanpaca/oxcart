{
   file2code, makes code files out of data files(binary or text)
   Copyright (C) 2015. Dejan Boras

   Created by Dejan Boras in Turbo Pascal 7.0.

   Created on:    05.12.2004.
   Port To FPC:   17.02.2008.

   Moved from asm2File to file2code: 01.02.2015.

   TODO: Refactor all of this, and make PAS output array instead of a procedure (not a good idea to read from
   executable code).
}

{$INCLUDE oxheader.inc}
PROGRAM file2code;

   USES uStd, uAppInfo, StringUtils, ParamUtils, uFileUtils;

TYPE
   TAssemblyTarget = (
      ASM_TARGET_NONE,
      ASM_TARGET_PAS,
      ASM_TARGET_MASM
   );

   { TFileWriter }

   TFileWriter = class
      public
         FSize,
         Count: fileint;

      procedure Writeln(const s: StdString);
      procedure Write(const s: StdString);
      procedure Start(); virtual;
      procedure WriteChar({%H-}ch: char); virtual;
      procedure Done(); virtual;
   end;

   { TPascalWriter }

   TPascalWriter = class(TFileWriter)
      procedure Start(); override;
      procedure WriteChar(ch: char); override;
      procedure Done(); override;
   end;

   { TMASMWriter }

   TMASMWriter = class(TFileWriter)
      procedure Start(); override;
      procedure WriteChar(ch: char); override;
      procedure Done(); override;
   end;

VAR
   env: record
     nName: longint;

     {names}
     sourceFN,
     outFN,
     dataName: StdString;

     {buffers}
     inBuf,
     outBuf: array[0..8191] of char;

     {files}
     fIn,
     fOut: text;

     {the target format of the assembly file}
     AsmTarget: TAssemblyTarget;

     {use unix line endings}
     LineEndings: TLineEndingType;

     Writer: TFileWriter;
   end;

procedure endProgramE(const msg: StdString);
begin
   writeln('Error: ' + msg); 
   halt(1);
end;

{writes out an IO error string and halts the program}
procedure Error(etext: StdString);
begin
   ioerror();

   if ioE <> 0 then begin
      writeln('IO Error: ', ioE);
      writeln(etext);
      halt;
  end;
end;

{writes out a warning string}
procedure Warning(wtext: StdString);
begin
   ioerror();

   if(ioE <> 0) then begin
      writeln('IO Error: ', ioE);
      writeln('Warning: ', wtext);
   end;
end;

{converts a data file into assembly}
procedure Convert();
var
   xch: char;

begin
   env.Writer.FSize := FileUtils.Exists(env.sourceFN);

   if(env.Writer.FSize <= 0) then
      endProgramE('File ' + env.sourceFN + ' does not exist or empty.');

   writeln('Will convert ' + sf(env.Writer.FSize) + ' bytes to code ...');

   env.Writer.Count := 0;

   {open files and set text buffers}
   Assign(env.fIn, env.sourceFN);
   SetTextBuf(env.fIn, env.inBuf);
   Reset(env.fIn);
   error('Can not open data file.');

   Assign(env.fOut, env.outFN);
   SetTextBuf(env.fOut, env.outBuf);
   Rewrite(env.fOut);
   Error('Can not create output file.');

   {write the header}
   env.Writer.Start();

   {write out the data as assembly data}
   repeat
      read(env.fIn, xch);
      inc(env.Writer.Count);

      if(ioerror() <> 0) then begin
         writeln('Error reading from source file.');
         break;
      end;

      env.Writer.WriteChar(xch);

      if(ioE <> 0) then begin
         writeln('Error writing to output file.');

         break;
      end;
   until (env.Writer.Count >= env.Writer.FSize) or (ioE <> 0);
  
   {Done}
   env.Writer.Done();

   {Close files}
   Close(env.fIn);
   Warning('Can not close data file.');
   Flush(env.fOut);
   Warning('Could not flush the output file.');
   Close(env.fOut);
   Warning('Can not close output file.');
end;

{sets the assembly target to the one specified}
procedure SetTarget(newTarget: TAssemblyTarget);
begin
   if(env.AsmTarget = ASM_TARGET_NONE) then
      env.AsmTarget := newTarget
   else
      endProgramE('Target already set.');
end;

function ProcessParams(const pstr: StdString; const lstr: StdString): boolean;
begin
   Result := true;

   (*if (lstr = '-masm') then
      SetTarget(TARGET_MASM)
   else *)if (lstr = '-pas') then
      SetTarget(ASM_TARGET_PAS)
   else if(lstr = '-lf') or (lstr = '-unix') then
      env.LineEndings := UNIX_LINE_ENDINGS
   else if(lstr = '-crlf') or (lstr = '-win') then
      env.LineEndings := WINDOWS_LINE_ENDINGS
   else begin
      inc(env.nName);

      case env.nName of
         1: env.sourceFN  := pStr;
         2: env.outFN     := pStr;
         3: env.dataName  := pStr;
         else
            endProgramE('Too many parameters. Check your typing.');
      end;
   end;
end;

procedure ParseParameters();
var
   pStr: StdString;

begin
   pStr := ParamStr(1);

   {Check parameters}
   if(pStr = '?') or (pStr = '-?') or (pStr = '/?') or (pStr = '-help') or (pStr = '--help') then begin
      writeln(
      appInfo.GetVersionString() + #10 +
         'Converts files into code.'#10 +
         'Copyright (c) 2004. Dejan Boras'#10#10 +
         'file2code -(pas) filename outfilename [procname]' +
         (*'-masm         use MASM data format as target' +*)
         '-pas          use Pascal array format as target'+
         '-lf           use unix line endings' +
         '-unix         use unix line endings' +
         '-crlf         use dos/windows line endings' +
         '-win          use dos/windows line endings' +
         'filename      source filename' +
         'outfilename   output filename' +
         'procname      name (identifier) of the data structure');
      halt(0);
   end;

   parameters.Process(@ProcessParams);

   {set the pascal target to the default if one was not set}
   if(env.AsmTarget = ASM_TARGET_NONE) then
      env.AsmTarget := ASM_TARGET_PAS;
   
   if(env.sourceFN = '') then
      endProgramE('No file name entered.')
   else if (env.outFN = '') then
      endProgramE('No output file name entered.');

   case env.AsmTarget of
      ASM_TARGET_PAS: env.Writer := TPascalWriter.Create();
      ASM_TARGET_MASM: env.Writer := TMASMWriter.Create();
   end;
end;

procedure initProgram();
begin
   appInfo.setName('file2code');
   appInfo.sVersion := '2.0';

   env.dataName := 'data';
end;

{ TMASMWriter }

procedure TMASMWriter.Start();
begin
   Writeln('; File generated from: ' + env.sourceFN);
   Write('   ' + env.dataName);
end;

procedure TMASMWriter.WriteChar(ch: char);
begin
end;

procedure TMASMWriter.Done();
begin
end;

{ TPascalWriter }

procedure TPascalWriter.Start();
begin
   Writeln('{File generated from: ' + env.sourceFN + '}');
   Writeln(env.dataName + ': array[0..' + sf(FSize - 1) + '] of byte = (');
end;

procedure TPascalWriter.WriteChar(ch: char);
begin
   if(Count < FSize) then begin
      if(Count mod 16 <> 0) then
         write(sf(byte(ch)) + ', ')
      else
         writeln(sf(byte(ch)) + ',');
   end else
      write(sf(byte(ch)));
end;

procedure TPascalWriter.Done();
begin
   Writeln('');
   Writeln(');');
end;

{ TFileWriter }

procedure TFileWriter.Writeln(const s: StdString);
begin
   if(env.LineEndings = PLATFORM_LINE_ENDINGS) then
      system.WriteLn(env.fOut, s)
   else if(env.LineEndings = UNIX_LINE_ENDINGS) then
      system.write(env.fOut, s + #$0A)
   else
      system.write(env.fOut, s + #$0D#$0A);

   ioerror();
end;

procedure TFileWriter.Write(const s: StdString);
begin
   system.write(env.fOut, s);
   ioerror();
end;

procedure TFileWriter.Start();
begin

end;

procedure TFileWriter.WriteChar(ch: char);
begin

end;

procedure TFileWriter.Done();
begin

end;

BEGIN
   env.LineEndings := PLATFORM_LINE_ENDINGS;

   initProgram();
   ParseParameters();
   Convert();

   if(ioE = 0) then
      writeln('Finished writing: ' + env.outFN);

   env.Writer.Free();
END.
