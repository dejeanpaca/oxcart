{
   txt2passstr, converts a text file into a pascal string
   Copyright (c) 2011. Dejan Boras
}

{$MODE OBJFPC}{$H+}
PROGRAM txt2passtr;

   USES sysutils, uSimpleParser;

VAR
   fileName: string;
   parseData: TParseData;
   first: boolean = true;

function readFile(var d: TParseData): boolean;
var
   ns: string;

begin
   Result := true;

   ns := StringReplace(d.currentLine, '''', '''''', [rfReplaceAll]);

   if(not first) then
      writeln('#10+  ''' + ns + '''')
   else
      writeln('''' + ns + '''');

   first := false;
end;


procedure ProcessParameters();
begin
   if(ParamStr(1) <> '') then
      fileName := ParamStr(1)
   else begin
      writeln('No filename is specified.');
      halt(1);
   end;
end;

BEGIN
   ProcessParameters();

   TParseData.Init(parseData);
   parseData.ReadMethod       := TParseMethod(@readFile);
   parseData.ReadEmptyLines   := true;
   parseData.StripWhitespace  := false;

   parseData.Read(fileName);
END.

