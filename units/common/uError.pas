{
   uError
   Copyright (C) Dejan Boras 2020.
}

{$INCLUDE oxheader.inc}
UNIT uError;

INTERFACE

   USES
      sysutils, uStd;

CONST
   {error names constants}
   {$INCLUDE errorcodenames.inc}

{adds an error procedure}
procedure eAddErrorProc(var newerrorproc: TErrorProc; var olderrorproc: TErrorProc);

function getRunTimeErrorDescription(errorCode: longint): StdString;
function getRunTimeErrorString(errorCode: longint; includeCode: boolean = true): StdString;

{get the name of an error code}
function GetErrorCodeString(code: longint): StdString;
{get the name of an error code}
function GetErrorCodeName(code: longint): StdString;

{return a string for the current call stack}
function DumpCallStack(skip: longint = 0): StdString;
function DumpExceptionHeader(e: Exception): StdString;
function DumpExceptionCallStack(e: Exception): StdString;
function DumpExceptionCallStack(exceptAddr: Pointer; frameCount: longint; frames: PPointer): StdString;

IMPLEMENTATION

VAR
   oldExitProc: pointer;

procedure eAddErrorProc(var newerrorproc: TErrorProc;
                        var olderrorproc: TErrorProc);
begin
   {check the validity of arguments passed}
   if(newerrorproc <> nil) and (olderrorproc = nil) then begin
      {add a new error procedure}
      olderrorproc := ErrorProc;
      Errorproc := newerrorproc;
   end else
      ioE := eNIL;
end;

function getRunTimeErrorDescription(errorCode: longint): StdString;
var
   s: StdString;

begin
   s := 'unknown';

   case errorCode of
      1:    s := 'Invalid function number';
      2:    s := 'File not found';
      3:    s := 'Path not found';
      4:    s := 'Too many open files';
      5:    s := 'Access denied';
      6:    s := 'Invalid file handle';
      12:   s := 'Invalid file access code';
      15:   s := 'Invalid drive number';
      16:   s := 'Cannot remove current directory';
      17:   s := 'Cannot rename across drives';
      100:  s := 'Disk read error';
      101:  s := 'Disk write error';
      102:  s := 'File not assigned';
      103:  s := 'File not open';
      104:  s := 'File not open for input';
      105:  s := 'File not open for output';
      106:  s := 'Invalid numeric format';
      150:  s := 'Disk is write-protected.';
      151:  s := 'Bad drive request struct length';
      152:  s := 'Drive not ready';
      154:  s := 'CRC error in data';
      156:  s := 'Disk seek error';
      157:  s := 'Unknown media type';
      158:  s := 'Sector not found';
      159:  s := 'Printer out of paper';
      160:  s := 'Device write fault';
      161:  s := 'Device read fault';
      162:  s := 'Hardware failure';
      200:  s := 'Division by zero';
      201:  s := 'Range check error';
      202:  s := 'Stack overflow';
      203:  s := 'Heap overflow';
      204:  s := 'Invalid pointer operation';
      205:  s := 'Floating point overflow';
      206:  s := 'Floating point underflow';
      207:  s := 'Invalid floating point operation';
      210:  s := 'Object not initialized';
      211:  s := 'Call to abstract method';
      212:  s := 'Stream registration error';
      213:  s := 'Collection index out of range';
      214:  s := 'Collection overflow';
      216:  s := 'General protection fault';
      217:  s := 'Unhandled exception occurred';
      227:  s := 'Assertion failed';
      else
            s := 'Unknown';
   end;

   Result := s;
end;

function getRunTimeErrorString(errorCode: longint; includeCode: boolean): StdString;
var
   codeString: ShortString;

begin
   if(includeCode) then begin
      Str(errorCode, codeString);

      Result := '(' + codeString + ') ' + getRunTimeErrorDescription(errorCode);
   end else
      Result := getRunTimeErrorDescription(errorCode);
end;

function GetErrorCodeString(code: longint): StdString;
var
   number: StdString;

begin
   Result := GetErrorCodeName(code);
   str(code, number);

   if(Result <> '') then
      Result := '[' + number + '] ' + Result
   else
      Result := '[' + number + ']';
end;

function GetErrorCodeName(code: longint): StdString;
begin
   case code of
      eNONE:                  Result := esNONE;
      eERR:                   Result := esERR;
      eNO_MEMORY:             Result := esNO_MEMORY;
      eUNABLE:                Result := esUNABLE;
      eEXTERNAL:              Result := esEXTERNAL;
      eUNEXPECTED:            Result := esUNEXPECTED;
      eFAIL:                  Result := esFAIL;
      eIO:                    Result := esIO;
      eWRITE:                 Result := esWRITE;
      eREAD:                  Result := esREAD;
      eHARDWARE_FAILURE:      Result := esHARDWARE_FAILURE;
      eMEMORY:                Result := esMEMORY;
      eCANT_FREE:             Result := esCANT_FREE;
      eNIL:                   Result := esNIL;
      eNOT_NIL:               Result := esNOT_NIL;
      eINVALID_ARG:           Result := esINVALID_ARG;
      eINVALID_ENV:           Result := esINVALID_ENV;
      eINVALID:               Result := esINVALID;
      eCORRUPTED:             Result := esCORRUPTED;
      eUNSUPPORTED:           Result := esUNSUPPORTED;
      eNOT_INITIALIZED:       Result := esNOT_INITIALIZED;
      eINITIALIZED:           Result := esINITIALIZED;
      eINITIALIZATION_FAIL:   Result := esINITIALIZATION_FAIL;
      eDEINITIALIZATION_FAIL: Result := esDEINITIALIZATION_FAIL;
      eEMPTY:                 Result := esEMPTY;
      eFULL:                  Result := esFULL;
      eNOT_OPEN:              Result := esNOT_OPEN;
      eOPEN_FAIL:             Result := esOPEN_FAIL;
      eNOT_CLOSED:            Result := esNOT_CLOSED;
      eCLOSE_FAIL:            Result := esCLOSE_FAIL;
      eNOT_FOUND:             Result := esNOT_FOUND;
      else
         Result := '';
   end;
end;

procedure RunTimeErrorDisplay(addr: pointer);
var
   s: StdString;

begin
   {display the error message}
   if(addr <> nil) and (isConsole) then begin
      writeln(stdout, '┻━┻ ︵ ╯(°□° ╯)');

      s := getRunTimeErrorDescription(ErrorCode);

      writeln(stdout, 'Error (', ErrorCode, '): ', s, ' @ $', addr2str(addr));
   end;
end;

procedure RunTimeError();
begin
   {restore the previous error handler}
   ExitProc := oldExitProc;

   RunTimeErrorDisplay(ErrorAddr);
end;

procedure UnhandledException(obj: TObject; addr: Pointer; {%H-}frameCount: Longint; {%H-}frames: PPointer);
begin
   writeln(stdout, '(╯°□°)╯︵ ┻━┻');
   writeln(stdout, 'Unhandled exception @ $',  addr2str(addr), ' :');

   if(obj is Exception) then begin
      writeln(stdout, DumpExceptionCallStack(Exception(obj)));
   end else begin
      writeln(stdout, 'Exception object ', obj.ClassName, ' is not of class Exception.');
      writeln(stdout, DumpExceptionCallStack(addr, frameCount, frames));
   end;

   writeln(stdout,'');
end;

function DumpCallStack(skip: longint): StdString;
var
   i: Longint;
   prevbp: Pointer;
   CallerFrame,
   CallerAddress,
   bp: Pointer;
   Report: StdString;

const
   MaxDepth = 20;

begin
   Report := '';
   bp := get_caller_frame(get_frame);

   try
      prevbp := bp - 1;

      i := 0;

      while bp > prevbp do begin
         CallerAddress := get_caller_addr(bp);
         CallerFrame := get_caller_frame(bp);

         if (CallerAddress = nil) then
            Break;

         if(skip = 0) or (i >= skip) then
            Report := Report + BackTraceStrFunc(CallerAddress) + LineEnding;

         Inc(i);

         if (i >= MaxDepth) or (CallerFrame = nil) then
            Break;

         prevbp := bp;
         bp := CallerFrame;
     end;
   except
      { prevent endless dump if an exception occured }
   end;

   Result := Report;
end;

function DumpExceptionHeader(e: Exception): StdString;
begin
   if(e <> nil) then
      Result := 'Exception ' + E.ClassName + ' ' + E.Message + ' (unit: ' + e.UnitName + ')' + LineEnding
   else
      Result := '';
end;

function DumpExceptionCallStack(e: Exception): StdString;
begin
   Result := DumpExceptionHeader(e);

   Result := Result + DumpExceptionCallStack(ExceptAddr, ExceptFrameCount, ExceptFrames);
end;

function DumpExceptionCallStack(exceptAddr: Pointer; frameCount: longint; frames: PPointer): StdString;
var
   i: loopint;

begin
   Result := BackTraceStrFunc(exceptAddr);

   for i := 0 to frameCount - 1 do
      Result := Result + LineEnding + BackTraceStrFunc(frames[I]);
end;

INITIALIZATION
   {store the old exit proc and set the new one}
   oldExitProc := ExitProc;
   ExitProc := @RunTimeError;

   ExceptProc := @UnhandledException;

END.
