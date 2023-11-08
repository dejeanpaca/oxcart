{
   txt2passstr, converts a text file into a pascal string
   Copyright (c) 2011. Dejan Boras

   Started On:    17.11.2011.
}

{$MODE OBJFPC}{$H+}
PROGRAM txt2passtr;

   USES sysutils, uSimpleParser;

VAR
   fileName: string;
   parseData: TParseData;
   first: boolean = false;

function readFile(var d: TParseData): boolean;
var
   ns: string;

begin
   result := true;

   ns := StringReplace(d.currentLine, '''', '''''', [rfReplaceAll]);

   if(not first) then
      writeln('''' + ns + '''#10')
   else
      writeln('+''' + ns + '''#10');

   first := true;
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

   ParseInit(parseData);
   parseData.StripComments    := nil;
   parseData.ReadMethod       := TParseExtMethod(@readFile);
   parseData.readEmptyLines   := true;
   parseData.stripWhitespace  := false;

   parseData.Read(fileName);
END.

