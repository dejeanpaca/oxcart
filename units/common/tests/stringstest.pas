{$INCLUDE oxheader.inc}
PROGRAM Test;

   USES sysutils, StringUtils, uTiming;

CONST
   TIMETEST_COUNT       = 1024 * 1024 * 2;
   CONCATTEST_COUNT     = 1024 * 1024 * 2;

VAR
   s: string;
   filename: string = '\\orcinus-x\C'+DirectorySeparator+'Media'+DirectorySeparator+'Music'+
         DirectorySeparator+'Apocalyptica'+DirectorySeparator+'Fatal error.mp3';

{$DEFINE TIMETEST}

Procedure Testit(const filename: String);
var
   i,
   ms: longint;

begin
   timStart();

   writeln();
   writeln(' >>> SysUtils');
   writeln('Filename: ', filename);
   writeln('File Name: ', sysutils.ExtractFileName(filename));
   writeln('File Ext: ', sysutils.ExtractFileExt(filename));
   writeln('File Dir: ', sysutils.ExtractFileDir(filename));
   writeln('File Path: ', sysutils.ExtractFilePath(filename));
   writeln('File Drive: ', sysutils.ExtractFileDrive(filename));

   {$IFDEF TIMETEST}
   timStart();
   
   for i := 0 to TIMETEST_COUNT-1 do begin
      sysutils.ExtractFileName(filename);
      sysutils.ExtractFileExt(filename);
      sysutils.ExtractFileDir(filename);
      sysutils.ExtractFilePath(filename);
      sysutils.ExtractFileDrive(filename);
   end;

   timUpdate();
   ms := timElapsed();
   writeln('Took: ', ms, ' miliseconds');
   {$ENDIF}
end;

procedure dTestIt(const filename: string);
var
   i, ms: longint;

begin
   writeln();
   writeln(' >>> StringUtils');
   
   writeln('Filename: ', filename);
   writeln('File Name: ', StringUtils.ExtractFileName(filename));
   writeln('File Ext: ', StringUtils.ExtractFileExt(filename));
   writeln('File Dir: ', StringUtils.ExtractFileDir(filename));
   writeln('File Path: ',StringUtils.ExtractFilePath(filename));
   writeln('File Drive: ', StringUtils.ExtractFileDrive(filename));

   {$IFDEF TIMETEST}
   timStart();
   
   for i := 0 to TIMETEST_COUNT-1 do begin
      StringUtils.ExtractFileName(filename);
      StringUtils.ExtractFileExt(filename);
      StringUtils.ExtractFileDir(filename);
      StringUtils.ExtractFilePath(filename);
      StringUtils.ExtractFileDrive(filename);
   end;

   timUpdate();
   ms := timElapsed();
   writeln('Took: ', ms, ' miliseconds');
   {$ENDIF}
end;

{$IFDEF TIMETEST}
procedure ConcatTest();
var
   i, ms: longint;
   s, p: string;
   a: longint = 123;
   b: single = 0.9;
   c: longint = 0;

begin
   {regular str}
   writeln(' >>> Regular str');
   timStart();

   for i := 0 to (CONCATTEST_COUNT - 1) do begin
     str(a, p);
     s := p;

     str(b:0:2, p);
     s := s + p;

     str(c, p);
     s := s + p;
   end;

   timUpdate();
   ms := timElapsed();
   writeln('Took: ', ms, ' miliseconds');

   {uStr concatenation}
   writeln(' >>> uStr Concatenation');
   timStart();

   for i := 0 to (CONCATTEST_COUNT-1) do
      s := sf(a) + sf(b, 6) + sf(c);

   timUpdate();
   ms := timElapsed();
   writeln('Took: ', ms, ' miliseconds');
end;
{$ENDIF}

{$IFDEF TIMETEST}
CONST
   string_buffer_test_string = 'avblkjdlasdjkdsnfsfdsslčjsfklasjkldaslANSKLDAKDKAWHDANDASNDJKABDKJASHFSA';

procedure TestNoStringBufferPerformance();
var
   r, s: string;
   i, ms: longint;

begin
   timStart();

   r := string_buffer_test_string;

   for i := 0 to TIMETEST_COUNT - 1 do
      s := '<div></div><span>' + r + '<div></div><span>' + r + '<div></div><span>' + r + '</span>' + '</span>' + '</span>';

   timUpdate();
   ms := timElapsed();
   writeln('Took: ', ms, ' miliseconds');
end;

procedure TestStringBufferPerformance();
var
   i, ms: longint;
   r, s: string;
   buf: TSimpleAnsiStringBuffer;

begin
   timStart();

   r := string_buffer_test_string;

   for i := 0 to TIMETEST_COUNT - 1 do begin
     buf.Reset();
     buf.Write('<div></div><span>');
     buf.Write(r);
     buf.Write('<div></div><span>');
     buf.Write(r);
     buf.Write('<div></div><span>');
     buf.Write(r);
     buf.Write('</span>');
     buf.Write('</span>');
     buf.Write('</span>');
     s := buf.Get();
   end;

   timUpdate();
   ms := timElapsed();
   writeln('Took: ', ms, ' miliseconds');
end;

{$ENDIF}

BEGIN
(*   {TEST: Whitespace}
   s := ' Hello world '#9;
   StripWhiteSpace(s);
   writeln('strip white space: ', s);

   s := ' h e l l o w o r l d ';
   EliminateWhiteSpace(s);
   writeln('eliminate whitespace: ', s);

   {TEST: dReplaceDirSeparators}
   s := '/mo/monies/needed/';
   ReplaceDirSeparators(s);
   writeln('replace dir separators: ', s);

   {TEST: StringFrom and StringTo}
   s := '123456789';

   writeln('stringfrom: ', StringFrom(s, 5));
   writeln('stringto  : ', StringTo(s, 5));

   {TEST: CopyToDel}
   s := 'blah'#9'woot';
   writeln('CopyToDel     : ', CopyToDel(s), '-', s);
   s := 'blah@woot';
   writeln('CopyToDel char: ', CopyToDel(s, '@'), '-', s);

   {TEST: CopyAfterDel}
   s := 'blah'#9'woot';
   writeln('CopyAfterDel     : ', CopyAfterDel(s), '-', s);
   s := 'blah@woot';
   writeln('CopyAfterDel char: ', CopyAfterDel(s, '@'), '-', s);

   {TEST: Padding}
   s := '123';
   AddLeadingPadding(s, '0', 5);
   writeln('Leading padding: ', s);
   s := '123';
   AddTrailingPadding(s, '0', 5);
   writeln('Trailing padding: ', s);

   {TEST: File Name Strings}
   TestIt(FileName);
   dTestIt(FileName);

   writeln();

   {TEST: Concatenation test}
   ConcatTest();
*)
   {buffer performance}
   writeln('No String Buffer >');
   TestNoStringBufferPerformance();
   writeln('Simple String Buffer >');
   TestStringBufferPerformance();
END.
