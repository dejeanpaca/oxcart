{
   q3uParser, Q3 file parser
   Copyright (C) 2007. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT q3uParser;

INTERFACE

   USES uStd, uLog, StringUtils;

CONST
   {these are pretty much all the things the parser can recognise}
   q3pcINT                    = $00;
   q3pcSTRING                 = $01;
   q3pcKEYWORD                = $02;
   q3pcPREPROCESSOR           = $03;
   q3pcFLOAT                  = $05;
   q3pcCOMMENT                = $06;
   q3pcOPENBRACKET            = $07;
   q3pcCLOSEBRACKET           = $08;
   q3pcOPENARGBRACKET         = $09;
   q3pcCLOSEARGBRACKET        = $0A;
   q3pcSEPARATOR              = $0B;
   q3pcLINEEND                = $0C;
   q3pcSUBTRACT               = $0D;
   q3pcADD                    = $0E;
   q3pcGARBAGE                = $0F; {this is either invalid or something the parser does not support}

   {These are the numerical values supported by the parser, although these
   come down to integers and floats when they are converted}
   q3pcNUMINTEGER             = $00;
   q3pcNUMHEX                 = $01;
   q3pcNUMFLOAT               = $02;
   q3pcNUMSUBTRACT            = $03;
   q3pcNUMADD                 = $04;
   q3pcNUMINVALID             = $05; {the given item is not a valid numerical value}

   q3pLogGarbage: boolean     = true;
   q3pLogNameAlways: boolean  = false;
   q3pTabSpacing: longint     = 0;

   q3pcSeparatorChar          = ',';

TYPE
   {holds a q3 item on a line}
   q3pPItem = ^q3pTItem;
   q3pTItem = record
      typeItem: word;
      data: pointer; {note that in case the item is either a integer or a
         floating point their value is stored into the pointer}
   end;

   q3pTItems = array of q3pTItem;

   {holds a single line of a q3 file}
   q3pPLine = ^q3pTLine;
   q3pTLine = record
      nItems: longint;
      Items: q3pTItems;
   end;

   q3pTLines = array of q3pPLine;
   
   q3pTSection = record
      lines: q3pTLines;
   end;

   {holds the entire structure of a q3 file}
   q3pPStructure = ^q3pTStructure;
   q3pTStructure = record
      FileName: string;
      nLines: longint;
      Lines: q3pTLines;
   end;

   {holds user parsing information}
   q3pTParsing = record
      obLine, 
      cbLine, 
      obItem, 
      cbItem: longint;
      FindDone: boolean;
      s: q3pPStructure;
   end;

   q3pListenProc = procedure(item: q3pPItem);

VAR
   q3pError: TError;

{ ERROR HANDLING }
procedure q3peRaise(err: TError);

{ FILE PARSING }
procedure q3pLoadOptions(comments: boolean);
procedure q3pLoadFile(const FileName: string; var struct: q3pTStructure);
procedure q3pLoadFile(f: pointer; size: longint; var struct: q3pTStructure);
procedure q3pLoadFile(const FileName: string; lp: q3pListenProc);
procedure q3pLoadFile(f: pointer; size: longint; lp: q3pListenProc);

{FILE WRITTING}
procedure q3pWriteFile(const FileName: string; var struct: q3pTStructure);

{STRUCTURE MANAGEMENT}
{items}
{init}
procedure q3pInitItem(out item: q3pTItem);
{add}
procedure q3pAddItem(var line: q3pTLine);
procedure q3pAddItems(var line: q3pTLine; no: longint);
{dispose}
procedure q3pDisposeItem(var item: q3pTItem);
procedure q3pDisposeItems(var line: q3pTLine);
{lines}
{init}
procedure q3pInitLine(out line: q3pTLine);
{make}
function q3pMakeLine(): q3pPLine;
{add}
procedure q3pAddLine(var struct: q3pTStructure);
procedure q3pAddLineEmpty(var struct: q3pTStructure);
procedure q3pAddLines(var struct: q3pTStructure; no: longint);
{dispose}
procedure q3pDisposeLine(var line: q3pTLine);
procedure q3pDisposeLine(var line: q3pPLine);
procedure q3pDisposeLines(var struct: q3pTStructure);
{structure}
{init}
procedure q3pInitStructure(out struct: q3pTStructure);
{make}
function q3pMakeStructure: q3pPStructure;
{dispose}
procedure q3pDisposeStructure(var struct: q3pTStructure);
procedure q3pDisposeStructure(var struct: q3pPStructure);

{ADDING ITEMS TO THE STRUCTURE}

{these routines are intended to make adding items to a line easier}

{add a normal item which has no data}
procedure q3pAddItemNormal(var line: q3pTLine; typeItem: word);
{add an item which is consisted of a string}
procedure q3pAddItemString(var line: q3pTLine; typeItem: word; const s: string);
{add a integer item(q3pcINT) with the given value}
procedure q3pAddItemInt(var line: q3pTLine; value: longint);
{add a float item(q3pcFLOAT) with the given value}
procedure q3pAddItemFloat(var line: q3pTLine; value: single);

{composes an item}
procedure q3pComposeItem(var item: q3pTItem; typeItem: word; const s: string; i: longint; f: single);

{ USER PARSING }

{initialize a q3pTParsing record}
procedure q3pInitParsingRecord(var p: q3pTParsing); inline;
{finds the next bracket set}
function q3pFindNextBracketSet(var p: q3pTParsing): boolean;

IMPLEMENTATION

CONST
   ParserName                    = 'q3Parser';
   OnlyListen: boolean           = false;

   loadComments: boolean         = true;

VAR
   procListen: q3pListenProc     = nil;
   fMem: pointer                 = nil;
   fMemSize: longint             = 0;
   fMemPos: longint              = 0;

{ERRORS}

procedure q3peRaise(err: TError);
begin
   q3pError := err;
end;

procedure q3pErrorReset();
begin
   q3pError := 0;
end;

{SUPPORT ROUTINES}
procedure mReadln(var st: string);
var
   c: char;
   chars: longint;
   s: shortstring = '';

begin
   chars := 0;
   repeat
      c := char((fMem+fMemPos)^); inc(fMemPos);

      if(c = #13) or (c = #10) then
         break;
      if(fMemPos >= fMemSize) then
         break;

      inc(chars);
      s[chars] := c;
   until (chars = 255);

   if(chars > 0) then
      SetLength(s, chars);

   st := s;
end;

{LOADING}

procedure q3pLoadOptions(comments: boolean);
begin
   loadComments := comments;
end;

procedure q3pLoadFile(const FileName: string; var struct: q3pTStructure);
var
   f: text;
   st, 
   item: string;
   stlen, 
   typeItem, 
   typeNum: word;
   isComment, 
   isSpecial: boolean;
   numInteger: longint;
   numFloat: single;

   pLine: q3pPLine;
   nLines: longint;
   spos: longint; {string position}

function ReadItem(): word;
var
   count: word;

{this will read a word until white-space or special characters are encountered,
or until the " character if it is a string}
procedure ReadupItem(isstring: boolean);
var
   j: shortint;
   isSlash: boolean;

begin
   if(stlen = 0) then
      exit();

   {analyze the string}
   isSpecial   := false;
   isSlash     := false;
   j           := spos;
   repeat
      if(j <= stlen) then begin
         if(isstring = false) then begin
            if(st[j] = '/') then begin
               {if a comment has been found then leave it}
               if(isSlash) then begin
                  if(st[j-1] = '/') then begin
                     j := j-1;
                     break;
                  end;
               end else
                  isSlash := true;
            end else begin
               if(st[j] in ['(', ')', #9, #32, '{', '}', q3pcSeparatorChar]) then begin
                  isSpecial := true;
                  break;
               end;
            end;
         end else begin
            if(st[j] = '"') then begin
               isSpecial := true;
               break;
            end;
         end;
      end;

      inc(j);
   until (j > stlen + 1);

   if(isSpecial) then
      count := j - spos
   else
     count := j - spos - 1;

   {get the item and remove it from the string}
   if(isstring = false) then
      item := copy(st, spos, count)
   else
      item := copy(st, spos, count);

   if(isstring = false) then
      inc(spos, count)
   else
     inc(spos, count + 1);
end;

{reads in a comment}
procedure ReadupComment;
begin
   item := copy(st, spos, 255);
   inc(spos, 255);
end;

{allowed numerical formats:
1234        integer
0x12AB      hex
.75         floating point, < 1.0
1234.1234   floating point}
{readup a numerical value}
function ReadupNumerical(): boolean;
var
   j,
   Digits,
   HexChars,
   CHex,
   IllegalChars,
   PossibleFloat,
   Code: word;

begin
   ReadupNumerical   := false;
   typeNum           := q3pcNUMINVALID;
   ReadupItem(false);

   {check if these are numerical operators}
   if(item = '-') then begin
      typeNum := q3pcNUMSUBTRACT;
      exit();
   end else if(item = '+') then begin
      typeNum := q3pcNUMADD;
      exit();
   end;

   {analyze string}
   Digits         := 0; 
   HexChars       := 0; 
   CHex           := 0; 
   IllegalChars   := 0;
   PossibleFloat  := 0;
   for j := 1 to length(item) do begin
      if(item[j] = '.') then
         inc(PossibleFloat)
      else if((item[j] >= 'A') and (item[j] <= 'F')) or ((item[j] >= 'a') and (item[j] <= 'f')) then
         inc(HexChars)
      else if(item[j] = 'x') or (item[j] = 'X' )then
         inc(CHex)
      else if((item[j] >= '0') and (item[j] <= '9')) then
         inc(Digits)
      else if(item[j] = '+') or (item[j] = '-') then begin
      end else begin
         {If any illegal characters(letters, underscore '_') or other
         have been encountered this is most likely not a number}
         inc(IllegalChars);
         exit;
      end;
   end;

   {First we need to ensure as much as possible that this is a numerical
   value, although it need no be}

   {this is most certainly a hexadecimal number}
   if((st[1] = '0') and (st[2] = 'x')) then begin
      if(CHex > 0) then
         exit;

      if(Digits < 2) and (HexChars = 0) then
         exit; {no numerical value after 0x}

      {this ensures that it'll look like a pascal representation of a hex number}
      inc(spos, 1);
      item[1] := '$';

      {convert the number}
      Val(item, numInteger, code);
      if(code > 0) then
         exit; {convert fail}

      {convert success}
      typeNum           := q3pcNUMHEX;
      ReadupNumerical   := true;
      exit;
   end else begin
      {a normal number should not have 'x' characters}
      if(CHex > 0) then
         exit;

      if(PossibleFloat > 0) then begin
         {float values may not contain more than one '.' character}
         if(PossibleFloat > 1) then
            exit;

         {convert the number to a float}
         Val(item, numFloat, code);
         if(code > 0) then
            exit; {convert fail}

         {convert success}
         typeNum := q3pcNUMFLOAT;
         ReadupNumerical := true;
         exit;
      end;

      {everything else must be a conventional integer value}

      {convert the number}
      Val(item, numInteger, code);
      if(code > 0) then
         exit; {convert fail}

      {convert success}
      typeNum           := q3pcNUMINTEGER;
      ReadupNumerical   := true;
      exit;
   end;
end;

{sets up the item type based on the numerical item type}
procedure SetupnumericalItemType();
begin
   case typeNum of
      q3pcNUMINTEGER, q3pcNUMHEX:
         typeItem := q3pcINT;
      q3pcNUMFLOAT:
         typeItem := q3pcFLOAT;
      q3pcNUMSUBTRACT:
         typeItem := q3pcSUBTRACT;
      q3pcNUMADD:
         typeItem := q3pcADD;
      q3pcNUMINVALID:
         typeItem := q3pcGARBAGE;
   end;
end;

begin
   item := '';
   ReadItem := q3pcKEYWORD;

   {determine what kind of item it is}
   case st[spos] of
      {possibly a comment}
      '/': begin
         {check if it is a comment or not}
         isComment := false;
         if(Length(st) > 1) then
            if(st[spos+1] = '/') then
               isComment := true;

         {readup a comment}
         if(isComment) then begin
            inc(spos, 2);
            ReadupComment;
            exit(q3pcCOMMENT);
         {readup an item}
         end else begin
            ReadUpItem(false);
            exit(q3pcKEYWORD);
         end;
      end;

      {open bracket}
      '{':begin
         inc(spos, 1);
         exit(q3pcOPENBRACKET);
      end;

      {close bracket}
      '}': begin
         inc(spos, 1);
         exit(q3pcCLOSEBRACKET);
      end;

      {open argument bracket}
      '(': begin
         inc(spos, 1);
         exit(q3pcOPENARGBRACKET);
      end;

      {close argument bracket}
      ')': begin
         inc(spos, 1);
         exit(q3pcCLOSEARGBRACKET);
      end;

      {possible numerical(integer or floating point) value}
      '0'..'9', '+', '-': begin
         ReadupNumerical();
         SetupnumericalItemType();
         exit(typeItem);
      end;
      {possible floating point value}
      '.': begin
         ReadupNumerical();
         SetupnumericalItemType();
         exit(typeItem);
      end;

      {preprocessor}
      '#': begin
         inc(spos, 1);
         ReadupItem(false);
         exit(q3pcPREPROCESSOR);
      end;

      {separator character}
      q3pcSeparatorChar: begin
         inc(spos, 1);
         exit(q3pcSEPARATOR);
      end;

      {a string}
      '"': begin
         inc(spos, 1);
         ReadUpItem(true);
         exit(q3pcSTRING);
      end;
   end;

   {otherwise it must be a keyword}
   ReadUpItem(false);
   exit(q3pcKEYWORD);

   inc(spos, 1);
   exit(q3pcGARBAGE);
end;

procedure StackItem();
var
   q3Item: q3pTItem;

begin
   if(not OnlyListen) then begin
      {now put the item to the item stack}
      case typeItem of
         q3pcINT:
            q3pAddItemInt(pLine^, numInteger);
         q3pcSTRING:
            q3pAddItemString(pLine^, q3pcSTRING, item);
         q3pcKEYWORD:
            q3pAddItemString(pLine^, q3pcKEYWORD, item);
         q3pcPREPROCESSOR:
            q3pAddItemString(pLine^, q3pcPREPROCESSOR, item);
         q3pcFLOAT:
            q3pAddItemFloat(pLine^, numFloat);
         q3pcCOMMENT:
            if(LoadComments) then
               q3pAddItemString(pLine^, q3pcCOMMENT, item);
         q3pcOPENBRACKET:
            q3pAddItemNormal(pLine^, q3pcOPENBRACKET);
         q3pcCLOSEBRACKET:
            q3pAddItemNormal(pLine^, q3pcCLOSEBRACKET);
         q3pcOPENARGBRACKET:
            q3pAddItemNormal(pLine^, q3pcOPENARGBRACKET);
         q3pcCLOSEARGBRACKET:
            q3pAddItemNormal(pLine^, q3pcCLOSEARGBRACKET);
         q3pcSEPARATOR:
            q3pAddItemNormal(pLine^, q3pcSEPARATOR);
         else;
      end;
   end else begin
      {compose the item}
      {$PUSH}{$HINTS OFF}
      q3pComposeItem(q3Item, typeItem, item, numInteger, numFloat);{$POP}
      {call the listening procedure}
      procListen(@q3Item);
      {dispose of the item}
      q3pDisposeItem(q3Item);
   end;
end;

procedure CleanUp();
begin
   if(fMem = nil) then
      close(f);
end;

function feof(): boolean;
begin
   if(fMem = nil) then begin
      feof := eof(f);
   end else begin
      feof := not(fMemPos < fMemSize);
   end;
end;

procedure stripleadingwhitespace(var s: string);
var
   i,
   count: longint;

begin
   if(stlen > 0) then begin
      if(spos <= stlen) then begin
         count := 0;

         for i := spos to stlen do
            if(s[i] in [#9, ' ']) then
               inc(count)
            else
              break;

         if(count > 0) then
            inc(spos, count);
      end;
   end;
end;

begin
   q3pErrorReset();

   if(q3pLogNameAlways) then
      log.i(ParserName+' > Parsing file: '+FileName);

   if(fMem = nil) then begin
      if(length(FileName) = 0) then
         exit;
      Assign(f, FileName);
      Reset(f);
      if(ioerror <> 0) then begin
         q3peRaise(eIO);
         exit;
      end;
   end else begin
      fMemPos := 0;
   end;

   if(ioerror <> 0) then begin
      CleanUp();
      q3peRaise(eIO);
      exit;
   end;

   if(not OnlyListen) then begin
      q3pInitStructure(struct);
      struct.FileName := FileName;
   end;

   typeItem := q3pcGARBAGE;
   nLines   := 0;
   repeat
      inc(nLines);
      if(feof) then
         break;

      {read line}
      if(fMem = nil) then
         readln(f, st)
      else
         mReadln(st);
      StripWhitespace(st); {strip any leading white space}

      if(ioerror <> 0) then begin
         CleanUp();
         q3peRaise(eIO);
         exit;
      end;

      spos  := 1;
      stlen := Length(st);

      if(stlen = 0) then begin
         {add a new empty line to the structure}
         if(not OnlyListen) then
            q3pAddLineEmpty(struct);

         continue;{if the line is empty then go to the next one}
      end else begin
         {add a new line to the structure}
         if(not OnlyListen) then begin
            q3pAddLine(struct);
            pLine := struct.Lines[struct.nLines - 1];
         end;
      end;

      {analyze the line and read all items from it}
      repeat
         {only leading white space can be created after reading an item}
         stripleadingwhitespace(st);
         if(spos > stlen) then break;

         {read item}
         item           := '';
         numInteger     := 0;
         numFloat       := 0;
         typeItem       := ReadItem();

         {log the garbage if indicated to do so}
         if(q3pLogGarbage) and (typeItem = q3pcGARBAGE) and
            (item <> '') then
               log.i('q3p > Garbage at line('+sf(nLines) + '):' + item);

         StackItem();
         if(q3pError <> 0) then begin
            CleanUp();
            exit;
         end;
      until (spos > stlen);
   until (feof);

   if(ioerror <> 0) then
      q3peRaise(eIO);
   CleanUp();
end;

procedure q3pLoadFile(const FileName: string; lp: q3pListenProc);
var
   struct: q3pTStructure;

begin
   OnlyListen  := true;
   procListen  := lp;
   {$PUSH}{$HINTS OFF}q3pLoadFile(FileName, struct);{$POP}
   OnlyListen  := false;
   procListen  := nil;
end;

procedure q3pLoadFile(f: pointer; size: longint; var struct: q3pTStructure);
begin
   fMem        := f;
   fMemSize    := size;
   q3pLoadFile('', struct);
   fMem        := nil;
end;

procedure q3pLoadFile(f: pointer; size: longint; lp: q3pListenProc);
var
   struct: q3pTStructure;

begin
   OnlyListen := true;
   procListen := lp;
   {$PUSH}{$HINTS OFF}q3pLoadFile(f, size, struct);{$POP}
   OnlyListen := false;
   procListen := nil;
end;

procedure q3pWriteFile(const FileName: string; var struct: q3pTStructure);
var
   f: text;

   i,
   j,
   level,
   itemno: longint;

   pItem: q3pPItem;
   pLine: q3pPLine;

   procedure CleanUp();
   begin
      Close(f);
   end;

   procedure ResetLine();
   var
      xstr: shortstring = '';

   begin
      if(q3pTabSpacing <> 0) then begin
         FillChar(xstr[1], level * q3pTabSpacing, #32);
         SetLength(xstr, level * q3pTabSpacing);
      end else begin
         FillChar(xstr[1], level, #9);
         SetLength(xstr, level);
      end;
      write(f, xstr);
      if(ioerror <> 0) then begin
         q3peRaise(eIO);
         exit;
      end;
   end;

   procedure WriteItem();
   begin
      if(itemno = 0) then
         ResetLine()
      else
         write(f, ' ');

      inc(itemno);
   end;

begin
   q3pErrorReset();

   log.i(ParserName+' > Writing file: ' + FileName);

   if(Length(struct.Lines) = 0) or (struct.nLines = 0) then begin
      q3peRaise(eInvalid);
      CleanUp();
      exit;
   end;

   Assign(f, FileName);
   Rewrite(f);
   if(ioerror <> 0) then begin
      q3peRaise(eIO);
      CleanUp();
      exit;
   end;

   level := 0;

   for i := 0 to (struct.nLines - 1) do begin
      pLine    := struct.Lines[i];
      itemno   := 0;

      if(pLine <> nil) then if(pLine^.nItems > 0) then
         for j := 0 to (pLine^.nItems - 1) do begin
            pItem := @pLine^.Items[j];
            case pItem^.typeItem of
               q3pcINT: begin
                  WriteItem();
                  write(f, plongint(@pItem^.data)^);
               end;
               q3pcSTRING: begin
                  WriteItem(); write(f, '"', pShortString(pItem^.data)^, '"');
               end;
               q3pcKEYWORD: begin
                  WriteItem(); write(f, pShortString(pItem^.data)^);
               end;
               q3pcPREPROCESSOR: begin
                  WriteItem(); write(f, '#', pShortString(pItem^.data)^);
               end;
               q3pcFLOAT: begin
                  WriteItem(); write(f, single((@pItem^.data)^):0:2);
               end;
               q3pcCOMMENT: begin
                  WriteItem(); write(f, '//'+pShortString(pItem^.data)^);
               end;
               q3pcOPENBRACKET: begin
                  WriteItem(); inc(level); write(f, '{');
               end;
               q3pcCLOSEBRACKET: begin
                  if(level > 0) then
                     dec(level); WriteItem(); write(f, '}');
               end;
               q3pcOPENARGBRACKET: begin
                  WriteItem(); write(f, '(');
               end;
               q3pcCLOSEARGBRACKET: begin
                  WriteItem(); write(f, ')');
               end;
               q3pcSEPARATOR: begin
                  WriteItem(); write(f, q3pcSeparatorChar);
               end;
            end;
         end;

      writeln(f);
      flush(f);
   end;


   CleanUp();
   if(ioerror <> 0) then
      q3peRaise(eIO);
end;

{STRUCTURE}
{items}
procedure q3pInitItem(out item: q3pTItem);
begin
   ZeroOut(item, SizeOf(item));
end;

procedure q3pAddItem(var line: q3pTLine);
begin
   inc(line.nItems);

   SetLength(line.Items, line.nItems);
   if(Length(line.Items) >= line.nItems) then
      q3pInitItem(line.Items[line.nItems - 1])
   else
      q3peRaise(eNO_MEMORY);
end;

procedure q3pAddItems(var line: q3pTLine; no: longint);
var
   i, pnItems: longint;

begin
   {check arguments}
   if(no > 0) then begin
      {setup appropriate variables}
      pnitems := line.nItems;
      inc(line.nItems, no);

      {add enough space for pointers}
      SetLength(line.Items, line.nItems);
      if(Length(line.Items) >= line.nItems) then begin
         {make and assign new items}
         for i := 0 to no-1 do begin
            q3pInitItem(line.Items[pnItems + i]);
         end;
      end else
         q3peRaise(eNO_MEMORY);
   end;
end;

{dispose}
procedure q3pDisposeItem(var item: q3pTItem);
begin
   {in case the item has memory allocate for data then free it}
   if(item.typeItem in [q3pcKEYWORD, q3pcCOMMENT, q3pcGARBAGE, q3pcPREPROCESSOR, q3pcSTRING]) then
         XFreeMem(item.Data);

   item.typeItem := 0;
end;

procedure q3pDisposeItems(var line: q3pTLine);
var
   i: longint;

begin
   {dispose off all items}
   if(line.nItems > 0) then begin
      for i := 0 to (line.nItems-1) do
         q3pDisposeItem(line.Items[i]);

      SetLength(line.Items, 0);
      line.Items := nil;
      line.nItems := 0;
   end;
end;

{ LINES }

{init}
procedure q3pInitLine(out line: q3pTLine);
begin
   ZeroOut(line, SizeOf(q3pTLine));
end;

{make}
function q3pMakeLine(): q3pPLine;
var
   line: q3pPLine = nil;

begin
   new(line);
   if(line <> nil) then
      q3pInitLine(line^)
   else
      q3peRaise(eNO_MEMORY);

   result := line;
end;

{add}
procedure q3pAddLine(var struct: q3pTStructure);
begin
   {create a new pointer}
   inc(struct.nLines);

   SetLength(struct.Lines, struct.nLines);
   if(Length(struct.Lines) < struct.nLines) then
      struct.Lines[struct.nLines-1] := q3pMakeLine()
   else
      q3peRaise(eNO_MEMORY);
end;

procedure q3pAddLineEmpty(var struct: q3pTStructure);
begin
   inc(struct.nLines);

   SetLength(struct.Lines, struct.nLines);
   if(Length(struct.Lines) < struct.nLines) then
      struct.Lines[struct.nLines-1] := nil
   else
      q3peRaise(eNO_MEMORY);
end;

procedure q3pAddLines(var struct: q3pTStructure; no: longint);
var
   i, pnLines: longint;

begin
   {check arguments}
   if(no >= 1) then begin
      {setup appropriate variables}
      pnLines := struct.nLines;
      inc(struct.nLines, no);

      {add enough space for pointers}
      SetLength(struct.Lines, struct.nLines);
      if(Length(struct.Lines) < struct.nLines) then begin
         {make and assign new lines}
         for i := 0 to no-1 do
            struct.Lines[pnLines + i] := q3pMakeLine();
      end else
         q3peRaise(eNO_MEMORY);
   end;
end;

{dispose}
procedure q3pDisposeLine(var line: q3pTLine);
begin
   q3pDisposeItems(line);
end;

procedure q3pDisposeLine(var line: q3pPLine);
begin
   if(line <> nil) then begin
      q3pDisposeLine(line^);
      dispose(line);
      line := nil;
   end;
end;

procedure q3pDisposeLines(var struct: q3pTStructure);
var
   i: longint;

begin
   if(struct.nLines > 0) then begin
      for i := 0 to (struct.nLines-1) do
         q3pDisposeLine(struct.Lines[i]);

      SetLength(struct.Lines, 0);
      struct.Lines := nil;
      struct.nLines := 0;
   end;
end;

{structure}
{init}
procedure q3pInitStructure(out struct: q3pTStructure);
begin
   ZeroOut(struct, SizeOf(q3pTStructure));
end;

{make}
function q3pMakeStructure: q3pPStructure;
var
   struct: q3pPStructure = nil;

begin
   new(struct);
   if(struct <> nil) then
      q3pInitStructure(struct^)
   else
      q3peRaise(eNO_MEMORY);

   result := struct;
end;

{dispose}
procedure q3pDisposeStructure(var struct: q3pTStructure);
begin
   q3pDisposeLines(struct);
   struct.FileName := '';
end;

procedure q3pDisposeStructure(var struct: q3pPStructure);
begin
   if(struct <> nil) then begin
      q3pDisposeStructure(struct^);
      dispose(struct);
      struct := nil;
   end;
end;

{ADDING ITEMS TO THE STRUCTURE}
{add a normal item which has no data}
procedure q3pAddItemNormal(var line: q3pTLine; typeItem: word);
begin
   q3pAddItem(line);
   if(q3pError = 0) then
      line.Items[line.nItems - 1].typeItem := typeItem;
end;

{add an item which is consisted of a string}
procedure q3pAddItemString(var line: q3pTLine; typeItem: word; const s: string);
var
   item: q3pPItem;

begin
   q3pAddItem(line);
   if(q3pError = 0) then begin
      item              := @line.Items[line.nItems-1];
      item^.typeItem    := typeItem;
      item^.data        := pointer(MakepShortString(s));
   end;
end;

{note that for integers and floats no memory is allocated. Their values are stored into the pointer. By all means, don't use the data pointer as a reqular pointer if the item types are q3pcINT or q3pcFLOAT}

{add a integer item(q3pcINT) with the given value}
procedure q3pAddItemInt(var line: q3pTLine; value: longint);
var
   item: q3pPItem;

begin
   q3pAddItem(line);
   if(q3pError = 0) then begin
      item                       := @(line.Items[line.nItems-1]);
      item^.typeItem             := q3pcINT;
      longint((@item^.data)^)    := value;
   end;
end;

{add a float item(q3pcFLOAT) with the given value}
procedure q3pAddItemFloat(var line: q3pTLine; value: single);
var
   item: q3pPItem;

begin
   q3pAddItem(line);
   if(q3pError = 0) then begin
      item                    := @(line.Items[line.nItems-1]);
      item^.typeItem          := q3pcFLOAT;
      single((@item^.data)^)  := value;
   end;
end;

procedure q3pComposeItem(var item: q3pTItem; typeItem: word; const s: string; i: longint; f: single);
var
   ps: pshortstring = nil;

begin
   item.typeItem := typeItem;
   if(typeItem = q3pcSTRING) or (typeItem = q3pcKEYWORD) or (typeItem = q3pcCOMMENT) or (typeItem = q3pcPREPROCESSOR) then begin
      XGetMem(ps, Length(s)+1);
      if(ps <> nil) then begin 
         ps^         := s;
         item.data   := ps;
      end else
      q3peRaise(eNO_MEMORY);
   end else if(typeItem = q3pcFLOAT) then
      item.data := pointer((@i)^)
   else if(typeItem = q3pcINT) then
      item.data := pointer((@f)^);
end;

{ USER PARSING }

{initialize a q3pTParsing record}
procedure q3pInitParsingRecord(var p: q3pTParsing); inline;
begin
   Zero(p, SizeOf(q3pTParsing));
end;

{finds the next bracket set}
function q3pFindNextBracketSet(var p: q3pTParsing): boolean;
begin
   result := false;

   {reset the search}
   if(p.FindDone) then begin
      p.obLine    := 0;
      p.cbLine    := 0;
      p.obItem    := 0;
      p.cbItem    := 0;
      p.FindDone  := false;
   end;
end;

END.
