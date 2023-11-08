{
   iniParser, .INI & .INF file format parser
   Copyright (C) 2007. Dejan Boras

   Started On:    10.08.2007.
}

{BUG: The unit does not add lines which only have keys.}

{$MODE OBJFPC}{$H+}{$I-}
UNIT iniParser;

INTERFACE

  USES uStd, uLog, StringUtils, dyArrays;

CONST
   inicVersion                = $011E; {1.3}

   {types of items the parser recognises}
   inicSECTION                = $00;
   inicKEY                    = $01;
   inicVALUE                  = $02;
   inicSTRING                 = $03;
   inicCOMMENT                = $04;
   inicSEPARATOR              = $05;
   inicLINE_CONTINUATOR       = $06;
   inicEQUAL                  = $07;
   inicGARBAGE                = $08;

   {note that the separator and equal items are not stored into the structure
   as they would present unrequired redundant data}

   inicLINE_CONTINUATOR_CHAR  = '\';

   {file sources}
   inicSOURCE_FILE            = 00;
   inicSOURCE_MEMORY          = 01;

   {parsing modes}
   inicMODE_NORMAL            = 00;
   inicMODE_LISTENING         = 01;

CONST
   inicWriteSpacesWithEqual: boolean   = false;
   inicWriteSpaceBeforeEqual: boolean  = true;
   inicWriteSpaceAfterEqual: boolean   = true;

TYPE
   {stores loading or writing settings}
   iniTSettings = record
      comment,
      empty, 
      invalid: boolean;
   end;

   iniPItem = ^iniTItem;
   iniTItem = record
      typeItem: word;
      data: string;
   end;

   iniTItems = ^iniTItem;

   iniPLine = ^iniTLine;
   iniTLine = record
      nItems: longint;
      Items: iniTItems;
   end;

   iniTLines = ^iniPLine;

   iniPSection = ^iniTSection;
   iniTSection = record
      Name, Comment: string;
      Lines: iniTLines;
      nLines: longint;
   end;

   iniTSections = ^iniPSection;

   iniPStructure = ^iniTStructure;
   iniTStructure = record
      FileName: string;
      Sections: iniTSections;
      nSections: longint;
   end;

   {a listening procedure}
   iniTListenProc = procedure(typ: dword; item: pointer);

VAR
   iniError: TError;

{FILE READING}
{loading settings}
procedure iniLoadSettings(comment, empty, invalid: boolean);
procedure iniPushLoadSettings(var settings: iniTSettings);
procedure iniPopLoadSettings(var settings: iniTSettings);
{loading and parsing a file}
procedure iniLoadFile(const FileName: string; var struct: iniTStructure);
procedure iniLoadFile(mem: pointer; size: dword; var struct: iniTStructure);
procedure iniLoadFile(const FileName: string; lp: iniTListenProc);
procedure iniLoadFile(mem: pointer; size: dword; lp: iniTListenProc);

{write settings}
procedure iniWriteSettings(comment, empty, invalid: boolean);
procedure iniPushWriteSettings(var settings: iniTSettings);
procedure iniPopWriteSettings(var settings: iniTSettings);
{writing a file}
procedure iniWriteFile(const FileName: string; var struct: iniTStructure);

{STRUCTURE MAINTENANCE}
{ITEMS}
{init}
procedure iniInitItem(var item: iniTItem); inline;
{add}
procedure iniAddItem(var line: iniTLine);
{dispose}
procedure iniDisposeItem(var item: iniTItem);
procedure iniDisposeItems(var line: iniTLine);

{LINES}
{init}
procedure iniInitLine(var line: iniTLine); inline;
{make}
function iniMakeLine: iniPLine;
{add}
procedure iniAddLine(var section: iniTSection);
procedure iniAddLineEmpty(var section: iniTSection);
{dispose}
procedure iniDisposeLine(var line: iniTLine);
procedure iniDisposeLine(var line: iniPLine);
procedure iniDisposeLines(var section: iniTSection);

{SECTIONS}
{init}
procedure iniInitSection(var section: iniTSection); inline;
{make}
function iniMakeSection: iniPSection;
{add}
procedure iniAddSection(var struct: iniTStructure);
{dispose}
procedure iniDisposeSection(var section: iniTSection);
procedure iniDisposeSection(var section: iniPSection);
procedure iniDisposeSections(var struct: iniTStructure);

{STRUCTURE}
{init}
procedure iniInitStructure(var struct: iniTStructure); inline;
function iniMakeStructure(): iniPStructure;
procedure iniDisposeStructure(var struct: iniTStructure);
procedure iniDisposeStructure(var struct: iniPStructure);

{ITEM ADDING ROUTINES}
procedure iniAddItemNormal(var line: iniTLine; itemType: word);
procedure iniAddItemData(var line: iniTLine; itemType: word; var data: string);

{ FINDING }

{finds a section}
function iniFindSection(const name: string; var s: iniTStructure): iniPSection;
{finds a line}
function iniFindLine(const key: string; var s: iniTSection): iniPLine;

IMPLEMENTATION

VAR
   loadSettings, writeSettings: iniTSettings;

VAR
   procListen: iniTListenProc    = nil;
   fMem: pointer                 = nil;
   fMemSize: dword               = 0;
   fMemPos: dword                = 0;

{ERROR SUPPORT}
procedure inieError(err: TError);
begin
   iniError := err;
end;

procedure iniErrorReset();
begin
   iniError := 0;
end;

{SUPPORT ROUTINES}
procedure mReadln(var st: string);
var
   c: char;
   chars: longint    = 0;
   s: string         = '';

begin
   repeat
      c := char((fMem+fMemPos)^); 
      inc(fMemPos);

      if(c = #13) or (c = #10) then 
         break;
      if(fMemPos >= fMemSize) then 
         break;

      inc(chars); 
      s[chars] := c;
   until (chars = 255);

   if(chars = 0) then 
      exit;
   SetLength(s, chars);

   st := s;
end;

{LOADING}
procedure iniLoadSettings(comment, empty, invalid: boolean);
begin
   loadSettings.Comment := comment;
   loadSettings.Empty   := empty;
   loadSettings.Invalid := invalid;
end;

procedure iniPushLoadSettings(var settings: iniTSettings);
begin
   settings := loadSettings;
end;

procedure iniPopLoadSettings(var settings: iniTSettings);
begin
   loadSettings := settings;
end;

{FILE READING}
procedure loadFile(const FileName: string; var struct: iniTStructure);
var
   f: text;

   lineContinue, 
   foundEqual, 
   foundLineContinuator, 
   addedLine,
   sectionMode, 
   keyRead: boolean;
   nItems, 
   itemType: dword;
   st, itemData: string;
   pSection: iniPSection      = nil;
   xSection: iniTSection;
   pLine: iniPLine            = nil;
   xLine: iniTLine;

function feof: boolean;
begin
   if(fMem = nil) then
      feof := eof(f);
   else
      feof := not(fMemPos < fMemSize);
end;

function ReadupUntil(c: char): boolean;
var
   i: longint;
   foundChar: boolean = false;

begin
   ReadUpUntil := false; 
   itemData := '';
   if(length(st) = 0) then e
      xit;

   for i := 1 to length(st) do begin
      if(st[i] = c) then begin 
         foundChar := true; 
         break; 
      end;
   end;

   if(foundChar = true) then begin
      itemData := copy(st, 1, i-1);
      delete(st, 1, i);
   end else begin
      itemData := copy(st, 1, i);
      delete(st, 1, i);
   end;

   ReadupUntil := foundChar;
end;

{read the key}
procedure ReadKey();
var
   equalFound: boolean = false;
   i: longint;

begin
   for i := 1 to Length(st) do begin
      if(st[i] in ['=', '\', ';']) then begin {read until the equal sign is found}
         equalFound := true; 
         break;
      end;
   end;

   if(equalFound = true) then begin
      itemData := copy(st, 1, i-1);
      delete(st, 1, i);
   end else begin
      itemData := copy(st, 1, i);
      delete(st, 1, i);
   end;
end;

{read a value}
procedure ReadValue();
var
   foundSeparator: boolean = false;
   i: longint;

begin
   i := 0;
   repeat
      inc(i);

      if(st[i] = inicLINE_CONTINUATOR_CHAR) then begin
         if((i-1) > 0) then
            if(st[i-1] in [' ', inicLINE_CONTINUATOR_CHAR, #9]) then begin
               foundSeparator := true; 
               break;
            end;
      end;

      if(st[i] in [',', ';']) then begin {read until a separator(whitespace, comment or ,) is found}
         foundSeparator := true; 
         break;
      end;
   until i = Length(st);

   if(foundSeparator = true) then begin
      itemData := copy(st, 1, i - 1);
      delete(st, 1, i - 1);
   end else begin
      itemData := copy(st, 1, i);
      delete(st, 1, i);
   end;
end;

{reads an item from the string}
procedure ReadUpItem();
begin
   itemData := ''; itemType := inicGARBAGE;

   if(st[1] = ';') then begin {comment}
      delete(st, 1, 1); 
      itemData := copy(st, 1, length(st)); 
      delete(st, 1, length(st));
      itemType := inicCOMMENT;
      exit;
   end;
   if(st[1] = '=') then begin {equal sign}
      foundEqual := true; 
      itemType := inicEQUAL; 
      delete(st, 1, 1);
      exit;
   end;
   if(st[1] = '"') then begin {string}
      if(foundEqual = false) and (lineContinue = false) then begin
         delete(st, 1, 255); 
         exit;
      end;
      delete(st, 1, 1);
      if(ReadupUntil('"') = true) then begin
         itemType := inicString; 
         inc(nItems);
      end else 
         delete(st, 1, 255);
      exit;
   end;
   if(st[1] = ',') then begin {value separator}
      itemType := inicSEPARATOR;
      delete(st, 1, 1);
      exit;
   end;
   if(st[1] = '[') then begin {section}
      delete(st, 1, 1); 
      lineContinue := false;
      if(ReadupUntil(']') = true) then begin
         itemType := inicSECTION;
         delete(st, 1, 1);
      end else 
         delete(st, 1, 255);
      exit;
   end;
   if(st[1] = inicLINE_CONTINUATOR_CHAR) then begin {line continuator}
      lineContinue := true; 
      foundLineContinuator := true;
      delete(st, 1, 1); 
      itemType := inicLINE_CONTINUATOR;
      exit;
   end;
   begin {key or value}
      if(keyRead = false) and (lineContinue = false) then begin
         ReadKey();
         itemType := inicKEY; 
         foundEqual := true; 
         keyRead := true;
      end else begin
         ReadValue(); 
         itemType := inicVALUE; 
         inc(nItems);
      end;
      if(itemType = inicGARBAGE) then 
         delete(st, 1, 1);
      exit;
   end;
end;

procedure CleanUp();
begin
   if(procListen <> nil) then begin
      iniDisposeSection(xSection); 
      iniDisposeLine(xLine);
   end;
end;

function newSection(): boolean;
begin
   newSection := false;

   if(procListen = nil) then begin
      iniAddSection(struct);
      if(iniError <> 0) then begin
         CleanUp(); 
         exit; 
      end;
      pSection := struct.Sections[struct.nSections - 1];
   end else begin
      iniDisposeSection(xSection);
   end;

   newSection := true;
end;

function newLine(): boolean;
begin
   newLine := false;

   if(procListen = nil) then begin
      iniAddLine(pSection^);
      if(iniError <> 0) then 
         exit;
      pLine := pSection^.Lines[pSection^.nLines - 1];
   end else begin
      iniDisposeLine(xLine);
   end;

   newLine := true;
end;

begin
   iniErrorReset();

   if(Filename = '') then begin 
      inieError(eINVALID_ARG); 
      exit; 
   end;

   Assign(f, Filename);
   Reset(f);
   if(ioerror <> 0) then begin 
      inieError(eIO); 
      exit; 
   end;

   if(procListen = nil) then begin
      if(newSection() = false) then 
         exit;
   end else begin
      iniInitSection(xSection); 
      pSection := @xSection;
   end;

   foundEqual := false;

   if(procListen <> nil) then begin
      iniInitLine(xLine);
      pLine := @xLine;
   end;

   {process the file}
   repeat
      if(eof(f) = true) then break;

      {read line}
      foundLineContinuator := false;
      if(fMem = nil) then
         readln(f, st) 
      else 
         mReadln(st);
      if(ioerror <> 0) then begin 
         CleanUp(); 
         inieError(eIO); 
         exit; 
      end;

      dStripLeadingWhiteSpace(st);
      if(Length(st) = 0) then begin
         iniAddLineEmpty(pSection^); 
         continue;
      end;

      {reset stuff after each line}
      addedLine   := false; 
      sectionMode := false; 
      foundEqual  := false;
      keyRead     := false;

      {first analyze the string for potential sections and such things}
      nItems := 0;
      repeat
         ReadupItem();
         dStripTrailingWhiteSpace(itemData);

         {some debugging information}
         (*case itemType of
            inicSECTION: logWrite('['+itemData+']');
            inicKEY: logWrite(itemData+' = ');
            inicVALUE: begin
               if(nItems > 1) then
                  logWrite(', ');
               logWrite(itemData);
            end;
            inicString: begin
               if(nItems > 1) then
                  logWrite(', ');
               logWrite('"'+itemData+'"');
            end;
            inicCOMMENT: logWrite('; '+itemData);
         end;*)

         {add a new line if none was added}
         if(itemType <> inicSECTION) and (itemType <> inicGARBAGE) then begin
            if(addedLine = false) then begin
               if(newLine = false) then begin 
                  CleanUp(); 
                  exit; 
               end;
               addedLine := true;
            end;
         end;

         {process items}
         case itemType of
            {section}
            inicSECTION: begin {add a new section, and set section mode to true}
               newSection(); 
               sectionMode := true;
               pSection^.Name := itemData;
            end;
            {key}
            inicKEY: begin
               if(sectionMode = false) then begin
                  iniAddItemData(pLine^, inicKEY, itemData);
                  if(iniError <> 0) then begin 
                     CleanUp(); 
                     exit; 
                  end;
               end;
            end;
            {value}
            inicVALUE: begin
               if(sectionMode = false) then begin
                  iniAddItemData(pLine^, inicVALUE, itemData);
                  if(iniError <> 0) then begin 
                     CleanUp(); 
                     exit; 
                  end;
               end;
            end;
            {separator}
            inicSEPARATOR: begin
            end;
            {comment}
            inicCOMMENT: begin
               if(sectionMode = false) and (loadSettings.Comment = true) then begin
                  iniAddItemData(pLine^, inicCOMMENT, itemData);
                  if(iniError <> 0) then begin 
                     CleanUp(); 
                     exit; 
                  end;
               end else 
                  pSection^.Comment := itemData;
            end;
            {string}
            inicString: begin
               if(sectionMode = false) then begin
                  iniAddItemData(pLine^, inicString, itemData);
                  if(iniError <> 0) then begin 
                     CleanUp(); 
                     exit; 
                  end;
               end;
            end;
            inicLINE_CONTINUATOR: begin
               if(sectionMode = false) then begin
                  iniAddItemNormal(pLine^, inicLINE_CONTINUATOR);
                  if(iniError <> 0) then begin 
                     CleanUp(); 
                     exit; 
                  end;
               end;
            end;
         end;

         dStripLeadingWhiteSpace(st);
      until(Length(st) = 0);

      {report a section in listening mode}
      if(sectionMode = true) and (procListen <> nil) then
         procListen(0, @xSection);

      {reset the line}
      if(foundLineContinuator = false) then begin
         if(sectionMode = false) and (procListen <> nil) then
            procListen(1, @xLine);
         lineContinue := false; 
         foundEqual := false;
      end;
   until feof();

   Close(f);
   if(ioerror <> 0) then begin
      inieError(eIO); 
      exit; 
   end;
end;

{loading and parsing a file}
procedure iniLoadFile(const FileName: string; var struct: iniTStructure);
begin
   fMem := nil; 
   procListen := nil;
   loadFile(FileName, struct);
end;

procedure iniLoadFile(mem: pointer; size: dword; var struct: iniTStructure);
var
   fn: string = '';

begin
   fMem := mem; 
   fMemSize := size; 
   fMemPos := 0;
   procListen := nil;
   loadFile(fn, struct);
end;

procedure iniLoadFile(const FileName: string; lp: iniTListenProc);
var
   struct: iniTStructure = (
      FileName: ''; 
      Sections: nil; 
      nSections: 0
   );

begin
   fMem := nil; 
   procListen := lp;
   loadFile(FileName, struct);
end;

procedure iniLoadFile(mem: pointer; size: dword; lp: iniTListenProc);
var
   fn: string = '';
   struct: iniTStructure = (
      FileName: ''; 
      Sections: nil; 
      nSections: 0
   );

begin
   fMem := mem; 
   fMemSize := size; 
   fMemPos := 0; 
   procListen := lp;
   loadFile(fn, struct);
end;

{WRITTING}

procedure iniWriteSettings(comment, empty, invalid: boolean);
begin
   writeSettings.Comment   := comment;
   writeSettings.Empty     := empty;
   writeSettings.Invalid   := invalid;
end;

procedure iniPushWriteSettings(var settings: iniTSettings);
begin
   settings := writeSettings;
end;

procedure iniPopWriteSettings(var settings: iniTSettings);
begin
   writeSettings := settings;
end;

procedure iniWriteFile(const FileName: string; var struct: iniTStructure);
var
   f: text;
   i, j, k: dword;
   lineContinued, 
   lineContinuatorFound: boolean;
   pSection: iniPSection;
   pLine: iniPLine;
   pItem: iniPItem;
   nItems: longint;

   procedure eIOCleanUp();
   begin
      inieError(eIO); close(f);
   end;

begin
   iniErrorReset();

   Assign(f, Filename);
   Rewrite(f);
   if(ioerror <> 0) then begin 
      inieError(eIO); 
      exit; 
   end;

   {process the file if there are any sections to process}
   if(struct.nSections > 0) then begin
      {go one section after another}
      for i := 0 to (struct.nSections-1) do begin
         pSection := struct.Sections[i];
         {write down the section name and comment if they exist}
         if(pSection = nil) then begin
            writeln(f);
         end else begin
            if(pSection^.Name <> '') then begin
               write(f, '[');
               write(f, pSection^.Name);
               write(f, ']');
            end;
            if(pSection^.Comment <> '') and (writeSettings.Comment = true) then begin
               if(pSection^.Name <> '') then write(f, ' ');
               write(f, ';', pSection^.Comment);
            end;
            if(pSection^.Name <> '') or (pSection^.Comment <> '') then 
               writeln(f);
            if(ioerror <> 0) then begin 
               eIOCleanUp(); 
               exit; 
            end;
         end;

         lineContinued := false; 
         lineContinuatorFound := false;

         {now process each line in the section if there are any}
         if(pSection^.nLines > 0) then begin
            for j := 0 to (pSection^.nLines-1) do begin
               pLine := pSection^.Lines[j];
               if(pLine = nil) then begin
                  writeln(f); 
                  if(ioerror <> 0) then begin 
                     eIOCleanUp(); 
                     exit; 
                  end;
                  continue; {next line}
               end;
               nItems := 0;

               if(lineContinued = true) then begin
                  write(f, '   ');
                  if(ioerror <> 0) then begin 
                     eIOCleanUp(); 
                     exit; 
                  end;
               end;

               {now process each item if there are any}
               if(pLine^.nItems > 0) then begin
                  for k := 0 to (pLine^.nItems-1) do begin
                     pItem := @(pLine^.Items[k]);

                     case pItem^.typeItem of
                        inicKEY: begin
                           if(pItem^.Data <> '') then 
                              write(f, pItem^.Data);
                           if(pLine^.nItems > 1) then
                              {confusing, is it not?}
                              if(not inicWriteSpacesWithEqual) then
                                 write(f, '=')
                              else begin
                                 if(inicWriteSpaceBeforeEqual) and (inicWriteSpaceAfterEqual) then
                                    write(f, ' = ')
                                 else if(not inicWriteSpaceBeforeEqual) and (inicWriteSpaceAfterEqual) then
                                    write(f, '= ')
                                 else
                                    write(f, ' =');
                              end;
                        end;
                        inicVALUE: begin
                           if(nItems > 0) then write(f, ', ');
                           if(pItem^.Data <> '') then
                              write(f, pItem^.Data); inc(nItems);
                        end;
                        inicString: begin
                           if(nItems > 0) then write(f, ', ');
                           if(pItem^.Data <> '') then
                              write(f, '"', pItem^.Data, '"'); inc(nItems);
                        end;
                        inicCOMMENT: begin
                           if(writeSettings.Comment = true) then begin
                              write(f, ';');
                              if(pItem^.Data <> '') then
                                 write(f, pItem^.Data);
                            end;
                        end;
                        inicLINE_CONTINUATOR: begin
                           lineContinuatorFound := true;
                           write(f, ' ', inicLINE_CONTINUATOR_CHAR);
                        end;
                     end;
                     if(ioerror <> 0) then begin 
                        eIOCleanUp(); 
                        exit; 
                     end;
                  end;

                  writeln(f);
                  lineContinued := lineContinuatorFound = true;
               end;
            end;
         end;
      end;
   end;

   Close(f);
   if(ioerror <> 0) then begin 
      inieError(eIO); 
      exit; 
   end;
end;

{ITEMS}
procedure iniInitItem(var item: iniTItem); inline;
begin
   Zero(item, SizeOf(iniTItem));
end;

procedure iniAddItem(var line: iniTLine);
begin
   {get a new pointer for the line}
   if(daSetLength(line.Items, line.nItems,  1, SizeOf(iniTItem))) then begin
      {make a line and assign it}
      iniInitItem(line.Items[line.nItems - 1]);
   end else 
      inieError(eNO_MEMORY);
end;

procedure iniDisposeItem(var item: iniTItem);
begin
   item.Data := '';
end;

procedure iniDisposeItems(var line: iniTLine);
var
   i: dword;

begin
   if(line.nItems > 0) then begin
      for i := 0 to line.nItems-1 do
            iniDisposeItem(line.Items[i]);

      daDispose(line.Items); 
      line.nItems := 0;
   end;
end;

{LINES}
{init}
procedure iniInitLine(var line: iniTLine); inline;
begin
   Zero(line, SizeOf(iniTLine));
end;
{make}
function iniMakeLine: iniPLine;
var
   line: iniPLine = nil;

begin
   new(line);
   if(line <> nil) then 
      iniInitLine(line^)
   else 
      inieError(eNO_MEMORY);

   result := line;
end;

{add}
procedure iniAddLine(var section: iniTSection);
begin
   {get a new pointer for the line}
   if(daSetLength(section.Lines, section.nLines, 1, SizeOf(iniPLine))) then begin
      {make a line and assign it}
      section.Lines[section.nLines-1] := iniMakeLine();
   end else
      inieError(eNO_MEMORY);
end;

procedure iniAddLineEmpty(var section: iniTSection);
begin
   {get a new pointer for the line}
   if(daSetLength(section.Lines, section.nLines, 1, SizeOf(iniPLine))) then begin
      {make a line and assign it}
      section.Lines[section.nLines - 1] := nil;
   end else 
      inieError(eNO_MEMORY);
end;

{dispose}
procedure iniDisposeLine(var line: iniTLine);
begin
   iniDisposeItems(line);
end;

procedure iniDisposeLine(var line: iniPLine);
begin
   if(line <> nil) then begin
      iniDisposeLine(line^); 
      dispose(line);
      line := nil;
   end;
end;

procedure iniDisposeLines(var section: iniTSection);
var
   i: dword;

begin
   if(section.nLines > 0) then begin
      {dispose line data}
      for i := 0 to section.nLines-1 do
         if(section.Lines[i] <> nil) then
            iniDisposeLine(section.Lines[i]);

      {dispose pointers}
      daDispose(section.Lines); 
      section.nLines := 0;
   end;
end;

{SECTIONS}
{init}
procedure iniInitSection(var section: iniTSection); inline;
begin
   Zero(section, SizeOf(iniTSection));
end;

{make}
function iniMakeSection(): iniPSection;
var
   section: iniPSection = nil;

begin
   new(section);
   if(section <> nil) then 
      iniInitSection(section^)
   else 
      inieError(eNO_MEMORY);

   result := section;
end;

{add}
procedure iniAddSection(var struct: iniTStructure);
begin
   {get a new pointer for the line}
   if(daSetLength(struct.Sections, struct.nSections, 1, SizeOf(iniPSection))) then begin
      {make a line and assign it}
      struct.Sections[struct.nSections - 1] := iniMakeSection();
   end else 
      inieError(eNO_MEMORY);
end;

{dispose}
procedure iniDisposeSection(var section: iniTSection);
begin
   section.Name      := '';
   section.Comment   := '';
   iniDisposeLines(section);
end;

procedure iniDisposeSection(var section: iniPSection);
begin
   if(section <> nil) then begin
      iniDisposeSection(section^); 
      dispose(section); 
      section := nil;
   end;
end;

procedure iniDisposeSections(var struct: iniTStructure);
var
   i: dword;

begin
   if(struct.nSections > 0) then begin
      for i := 0 to struct.nSections-1 do
         if(struct.Sections[i] <> nil) then
            iniDisposeSection(struct.Sections[i]);

      daDispose(struct.Sections); 
      struct.nSections := 0;
   end;
end;

{STRUCTURE}
{init}
procedure iniInitStructure(var struct: iniTStructure); inline;
begin
   Zero(struct, SizeOf(iniTStructure));
end;

{make}
function iniMakeStructure(): iniPStructure;
var
   struct: iniPStructure = nil;

begin
   new(struct);
   if(struct <> nil) then 
      iniInitStructure(struct^)
   else 
      inieError(eNO_MEMORY);

   result := struct;
end;

{dispose}
procedure iniDisposeStructure(var struct: iniTStructure);
begin
   struct.FileName := '';
   iniDisposeSections(struct);
end;

procedure iniDisposeStructure(var struct: iniPStructure);
begin
   if(struct <> nil) then begin
      iniDisposeStructure(struct^); 
      dispose(struct); 
      struct := nil;
   end;
end;

{ITEM ADDING ROUTINES}
procedure iniAddItemNormal(var line: iniTLine; itemType: word);
begin
   iniAddItem(line);
   if(iniError = 0) then
      line.Items[line.nItems - 1].typeItem := itemType;
end;

procedure iniAddItemData(var line: iniTLine; itemType: word; var data: string);
var
   pItem: iniPItem;

begin
   iniAddItem(line);
   if(iniError <> 0) then 
      exit;

   pItem             := @line.Items[line.nItems-1];
   pItem^.typeItem   := itemType;
   pItem^.Data       := data;
end;

{ FINDING }

function iniFindSection(const name: string; var s: iniTStructure): iniPSection;
var
   i: longint;
   lname: string;

begin
   result := nil;

   if(s.nSections > 0) then begin
      lname := LowerCase(name);
      for i := 0 to (s.nSections-1) do begin
         if(LowerCase(s.Sections[i]^.Name) = lname) then
            exit(s.Sections[i]);
      end;
   end;
end;

function iniFindLine(const key: string; var s: iniTSection): iniPLine;
var
   i: longint;
   lkey: string;
   pLine: iniPLine;

begin
   iniFindLine := nil;
   if(s.nLines > 0) then begin
      lkey := LowerCase(key);
      for i := 0 to (s.nLines-1) do begin
         if(s.Lines[i] <> nil) then begin
            pLine := s.Lines[i];
            if(pLine^.nItems > 0) then
               if(pLine^.Items[0].typeItem = inicKEY) then
                  if(LowerCase(pLine^.Items[0].data) = lkey) then 
                     exit(pLine);
         end;
      end;
   end;
end;

BEGIN
   {set load settings to defaults}
   loadSettings.comment    := true;
   loadSettings.empty      := true;

   {set write settings to defaults}
   writeSettings.comment   := true;
   writeSettings.empty     := true;
END.
