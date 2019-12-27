{  
   q3uShaders, a q3 shader parser
   Copyright (C) 2009. Dejan Boras

   Started On:    29.10.2009.

   This unit is intended to help process Quake .shader files.
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT q3uShaders;

INTERFACE

   USES uStd, uLog,
      q3uParser, StringUtils;

CONST
   q3ShaderLog: boolean = false;

   {maximum number of data types for a field}
   q3cMAX_FIELD_DEF_DATA_TYPES         = 0008;

   {error codes}
   q3eSHADER_NO_DEFINITIONS            = $0400;
   q3eSHADER_EMPTY_FILE                = $0401;

   {found nothing related}
   q3SHADER_FIND_NOT                   = -0001;
   {found exact match, both definition and subdefinition}
   q3SHADER_FIND_EXACT                 =  0000;
   {found a match for a definition with a string or keyword but nothing else}
   q3SHADER_FIND_MATCH                 =  0002;

   {field properties}
   q3SHADER_FIELD_VALID                = $0001;
   q3SHADER_FIELD_CUSTOM               = $0002;

TYPE
   {this defines a field of the shader}
   q3PShaderDefinition = ^q3TShaderDefinition;
   q3TShaderDefinition = record
      sName: pshortstring;
      sSub: pshortstring;
      uID: longword;
      Properties: longword;
      DataTypes: packed array[0..q3cMAX_FIELD_DEF_DATA_TYPES - 1] of byte;
   end;

   {a definition array type}
   q3pPDefinitionArray = ^q3pTDefinitionArray;
   q3pTDefinitionArray = array[1..4096]  of q3TShaderDefinition;

   {this holds the definitions}
   q3PShaderDefinitions = ^q3TShaderDefinitions;
   q3TShaderDefinitions = record
      nDefs: longint;
      Defs: q3pPDefinitionArray;
   end;

   {a individual shader field data}
   q3TShaderFieldData = record
      i: longint;
      f: single;
      s: string;
   end;

   {shader field, individual information in a shader field}
   q3PShaderField = ^q3TShaderField;
   q3TShaderField = record
      ID, 
      uID, 
      Properties: longint;
      Data: array[0..q3cMAX_FIELD_DEF_DATA_TYPES-1] of q3TShaderFieldData;
   end;

   {shader callbacks}
   q3TShaderCallbacks = record
      newShader: function(var s: string): boolean;
      newStage: procedure();
      newField: procedure(var f: q3TShaderField; var def: q3TShaderDefinition);
      customField: procedure(var f: q3TShaderField; var def: q3TShaderDefinition; var line: q3pTLine);
      endShader: procedure();
   end;

VAR
   q3ShaderDefinitionsP: q3PShaderDefinitions = nil;

{ GENERAL }

{sets the specified definitions as selected}
procedure q3SelectShaderDefinitions(var defs: q3TShaderDefinitions); inline;

{ INIT, ADD }
{fields}
procedure q3InitShaderFieldRecord(var f: q3TShaderField); inline;

{ PARSING }

{this routine will parse the raw q3p data and form a shader structure out of it}
procedure q3ParseShaderData(var data: q3pTStructure; var c: q3TShaderCallbacks);

{ LOADING }

{this loads the shader using q3Parser unit and then uses q3ParseShaderData}
procedure q3LoadShader(const filename: string; var c: q3TShaderCallbacks);
procedure q3LoadShader(mem: pointer; size: longint; var c: q3TShaderCallbacks);

{ DEFINITIONS }
{this finds the best definition ID for the proposed names}
function q3FindShaderDefinition(const def, sub: string; var ID: longint; var pdef: q3PShaderDefinition): longint;

IMPLEMENTATION

TYPE
   TPosition = record
      s, e: longint;
   end;

   TPositions = array of TPosition;

{ HELPER ROUTINES }
procedure disposePositions(var p: TPositions; var nPos: longint);
begin
   if(nPos > 0) then begin
      SetLength(p, 0);
      p := nil;
      nPos := 0;
   end;
end;

{ GENERAL }

procedure q3SelectShaderDefinitions(var defs: q3TShaderDefinitions); inline;
begin
   q3ShaderDefinitionsP := @defs;
end;

{ INIT, ADD }

{ fields }
procedure q3InitShaderFieldRecord(var f: q3TShaderField); inline;
begin
   Zero(f, SizeOf(q3TShaderField));
end;

{ PARSING }
{This routine will count how many sections there are starting from a point.
The level at which the first open bracket is found is the default level(0)
and only sections on that level are counted (once their close bracket is found)}
procedure countLevelSections(var data: q3pTStructure; s, e: longint; var nPos: longint; var Pos: TPositions);
var
   level: longint       = 0;
   sections: longint    = 0;
   pLine: q3pPLine;
   index: boolean       = false;

{this does bulk of the work}
procedure doIt();
var
   i: longint;

begin
   for i := s to e do begin
      pLine := data.Lines[i];

      {find a line with a single bracket item}
      if(pLine <> nil) and (pLine^.nItems = 1) then begin
         case pLine^.Items[0].typeItem of
            {at opening bracket, we mark start position and increase level}
            q3pcOpenBracket: begin
               if(level = 0) and (index) then
                  Pos[sections].s := i;
               inc(level);
            end;
            {at closing bracket, we increase sections and decrease level
            and mark end position}
            q3pcCloseBracket: begin
               dec(level);
               if(level = 0) then begin
                  {note: i'm not sure why that +1 is required but without it
                  the end line is off by one.}
                  if(index) then
                     Pos[sections].e := i+1;
                  inc(sections);
               end else if(level < 0) then
                  break;
            end;
         end;
      end;
   end;
end;

begin
   nPos := 0;

   {check}
   if(e >= data.nLines) then
      e := data.nLines-1;

   {the first pass only counts how many sections there are}
   level          := 0;
   sections       := 0;
   index          := false;
   doIt();

   {if we have anything to index ...}
   if(sections > 0) then begin
      {we'll need to allocate sufficient memory for the index}
      SetLength(Pos, sections);
      if(Length(Pos) <> sections) then begin
         q3peRaise(eNO_MEMORY);
         exit;
      end;
      nPos        := sections;

      {the second pass indexes all sections, we set the sections to 0
      as doIt() uses it as a counter}
      level       := 0;
      sections    := 0;
      index       := true;
      doIt();
   end;
end;

{process a single field in a stage}
procedure processField(var line: q3pTLine; var c: q3TShaderCallbacks);
var
   kWord: string;
   nItems: longint                  = 0;
   nDT: longint                     = 0;
   potentialSub: boolean            = false;
   hasSub: boolean                  = false;
   isCustom: boolean                = false;
   i,
   istart,
   matchType: longint;
   defID: longint                   = -1;
   pDef: q3PShaderDefinition        = nil;
   field: q3TShaderfield;

{checks whether all data types match}
function dtmatch(n: longint): boolean;
var
   s: string;
   ni: longint;

begin
   ni := i + 1;

   result := false;
   case line.Items[ni].typeItem of
      q3pcInt:
         if pDef^.DataTypes[n] in
            [dtcINT8, dtcINT16, dtcINT32, dtcUINT8, dtcUINT16, dtcUINT32] then
               result := true;
      q3pcFloat:
         if pDef^.DataTypes[n] in [dtcSINGLE] then
               result := true;
      q3pcString, q3pcKeyword:
         if(pDef^.DataTypes[n] = dtcBOOL) then begin
            s := lowercase(pshortstring(line.Items[ni].data)^);
            if(s = 'false') or (s = 'true') then
               result := true
         end else begin
            if pDef^.DataTypes[n] in
               [dtcSHORTSTRING] then
                  result := true;
         end;
   end;
end;

function dtTranslate(n: longint): boolean;
var
   ni: longint;

begin
   result   := true;
   ni       := n + 1;

   case pDef^.DataTypes[n] of
      {all values are stored as longint}
      dtcINT8, dtcINT16, dtcINT32: begin
         field.Data[n].i   := plongint(@line.Items[ni].Data)^;
      end;
      {even if we requested a float the q3Parser might return ints,
      depending on the format in which the number was written}
      dtcSINGLE: begin
         if(line.Items[ni].typeItem = q3pcFloat) then
            field.Data[n].f := psingle(@line.Items[ni].Data)^
         else
            field.Data[n].f := plongint(@line.Items[ni].Data)^;
      end;
      dtcSHORTSTRING: begin
         field.Data[n].s := pshortstring(line.Items[ni].Data)^;
      end;
      else
         result := false;
   end;
end;

begin
   {prepare}
   nItems      := line.nItems;
   field.ID    := -1;
   field.uID   := -1;

   q3InitShaderFieldRecord(field);

   {get the keyword (field name)}
   kWord := pshortstring(line.Items[0].Data)^;

   {check if there is potential subfield name}
   if(nItems > 1) then begin
      if(line.Items[1].typeItem = q3pcKeyword) then
         potentialSub := true;
   end;

   {now we need to find the corresponding definition}
   if(not potentialSub) then
      matchType := q3FindShaderDefinition(kWord, '', defID, pDef)
   else
      matchType := q3FindShaderDefinition(kWord, pshortstring(line.Items[1].Data)^, defID, pDef);

   {if some kind of a valid definition was found then we'll use it}
   if(matchType <> q3SHADER_FIND_NOT) and (defID > 0) then begin
      {if this is a custom field then there is no need to process anything}
      if(pDef^.Properties and q3SHADER_FIELD_CUSTOM > 0) then
         isCustom := true
      else begin
         {if there is no sub in definition then we assume there is no sub}
         if(pdef^.sSub = nil) then
            potentialSub := false;

         {figure out how many data types this definition has}
         for i := 0 to (q3cMAX_FIELD_DEF_DATA_TYPES-1) do
            if(pdef^.DataTypes[i] <> dtcNIL) then
               inc(nDT)
            else
               break;

         {if we have more than one item}
         if(nItems > 1) then begin
            {first we need to figure out if this is a subfield}
            if(potentialSub) then begin
               if(line.Items[1].typeItem = q3pcKeyword) then begin
                  if(pdef^.DataTypes[0] = dtcSHORTSTRING) then begin
                     if(LowerCase(pshortstring(line.Items[1].data)^) =
                        LowerCase(pdef^.sSub^)) then
                           hasSub := true;
                  end;
               end;
            end;

            {if we have a sub and only 1 data type then there are no DTs to convert}
            if(hasSub) and (nDT = 1) then begin
               field.uID   := pDef^.uID;
               field.ID    := defID;
            {otherwise we need to convert the data}
            end else if(line.nItems = nDT+1) then begin
               istart := 0;
               if(hasSub) then
                  istart := 1;

               {check if all the data types match}
               for i := istart to (nItems-2) do begin
                  if(not dtmatch(i)) then
                     exit;
               end;

               {translate every data type}
               for i := istart to (nItems-2) do begin
                  if(not dtTranslate(i)) then
                     exit;
               end;
            {in case there is a mismatch between data type and item count}
            end else
               exit;

            {set the field as valid}
            field.Properties  := field.Properties or q3SHADER_FIELD_VALID;
         {in case we only have a single keyword(field) we can be sure that's what
         were looking for}
         end else begin
            field.Properties  := field.Properties or q3SHADER_FIELD_VALID;
            field.uID         := pDef^.uID;
            field.ID          := defID;
            if(pDef^.Properties and q3SHADER_FIELD_CUSTOM > 0) then
               isCustom       := true;
         end;
      end;

      {now report this field}
      if(not isCustom) then begin
         if(c.newField <> nil) then
            c.newField(field, pDef^)
      end else begin
         if(c.customField <> nil) then
            c.customField(field, pDef^, line);
      end;
   end;
end;

{process a specified stage of the shade}
procedure processStage(var data: q3pTStructure; var shaderName: string; var c: q3TShaderCallbacks; s, e: longint);
var
   i: longint;
   pLine: q3pPLine      = nil;
   fields: longint;

begin
   fields := e - s;

   {check if there are any fields}
   if(fields = 0) then begin
      if(q3ShaderLog) then
         log.i('q3Shader > Warning: Shader ' + shaderName+
            '(line: ' + sf(s - 2) + ') has an empty stage.');
      exit();
   end;

   {report a new stage}
   if(c.newStage <> nil) then c.newStage();

   {process all fields}
   for i := s to e do begin
      pLine := data.Lines[i];

      if(pLine <> nil) and (pLine^.nItems > 0) then
         if(pLine^.Items[0].typeItem = q3pcKeyword) then
            processField(pLine^, c);
   end;
end;

{this processes and individual shade}
procedure processShader(var data: q3pTStructure; var c: q3TShaderCallbacks; s, e: longint);
var
   sline, i: longint;
   stages: longint                  = 0;
   positions: TPositions            = nil;
   sstage, estage: longint;
   ValidShaderName: boolean         = false;
   hasMainStage: boolean            = false;
   shaderName: string;

procedure cleanup();
begin
   disposePositions(positions, stages);
end;

begin
   {first off we need to figure out the shader name}
   sline := (s-2);
   if(sline >= 0) then begin
      if(data.Lines[sline] <> nil) then
      if(data.Lines[sline]^.nItems = 1) then
         if(data.Lines[sline]^.Items[0].typeItem = q3pcKeyword) then begin
            shaderName        := pshortstring(data.Lines[sline]^.Items[0].data)^;
            ValidShaderName   := true;
         end;
   end else sline := (s-1);

   if(not ValidShaderName) then begin

      if(q3ShaderLog) then
         writeln('q3Shader > Warning: Shader (line: '+sf(sline+1)+') has no name.');
      exit();
   end;

   {now that we've figured out the shader name we need to report a new shader}
   if(c.newShader <> nil) then
      c.newShader(shaderName);

   {first we need to index all stages, if there are any}
   countLevelSections(data, s, e, stages, positions);
   if(q3pError <> 0) then
      exit();

   {determine where the main stage starts and ends}
   sstage := s;
   estage := e;

   if(positions <> nil) then
      estage := positions[0].s - 1;

   {process the main stage if there is any}
   if(estage - sstage > 0) then begin
      hasMainStage := true;
      processStage(data, shaderName, c, sstage, estage);
   end;

   {if there are any stages}
   if(stages > 0) then begin
      {process each stage of this shade}
      for i := 0 to (stages-1) do begin
         sstage := positions[i].s + 1;
         estage := positions[i].e - 1;

         if(estage - sstage >= 0) then
            processStage(data, shaderName, c, sstage, estage);
      end;

      {dispose of position index}
      disposePositions(positions, stages);
   end else begin
      if(not hasMainStage) {and (q3ShaderLog) }then
         log.w('q3Shader > Warning: Shader ' + shaderName + '(line: ' + sf(sline + 1) + ') is empty.')
   end;

   if(c.endShader <> nil) then
      c.endShader();

   {we're done}
   cleanup();
end;

procedure q3ParseShaderData(var data: q3pTStructure; var c: q3TShaderCallbacks);
var
   i: longint;
   shaders: longint           = 0;
   positions: TPositions      = nil;

{clean up}
procedure cleanup();
begin
   disposePositions(positions, shaders);
end;

begin
   {let's do some checks first}
   if(q3ShaderDefinitionsP = nil) then begin
      q3peRaise(q3eSHADER_NO_DEFINITIONS);
      exit();
   end;
   if(data.nLines < 3) then begin
      q3peRaise(q3eSHADER_EMPTY_FILE);
      exit();
   end;

   {first count the number of shaders this shader has}
   countLevelSections(data, 0, data.nLines - 1, shaders, positions);
   if(shaders > 0) then begin
   end;

   {process all the shaders}
   if(shaders > 0) then begin
      for i := 0 to (shaders-1) do begin
         {we must make sure we ignore empty shaders}
         {note: the +1 and -1 are to eliminate brackets}
         if((positions[i].e - 1) - (positions[i].s + 1) >= 0) then
            processShader(data, c, (positions[i].s + 1), (positions[i].e - 1));
      end;
   end;

   {we're done}
   cleanup();
end;

{ LOADING }

procedure q3LoadShader(const filename: string; var c: q3TShaderCallbacks);
var
   data: q3pTStructure = (
      FileName: ''; 
      nLines: 0; 
      Lines: nil
   );

begin
   q3pInitStructure(data); {initialize the data}

   {load and parse the file, this job performs the q3Parser}
   q3pLoadFile(filename, data);
   if(q3pError <> 0) then
      exit();

   {now parse the data into a shader structure}
   q3ParseShaderData(data, c);

   {dispose of the data now}
   q3pDisposeStructure(data);
end;

procedure q3LoadShader(mem: pointer; size: longint; var c: q3TShaderCallbacks);
var
   data: q3pTStructure = (
      FileName: ''; 
      nLines: 0; 
      Lines: nil
   );

begin
   q3pInitStructure(data); {initialize the data}

   {load and parse the file, this job performs the q3Parser}
   q3pLoadFile(mem, size, data);
   if(q3pError <> 0) then
      exit();

   {now parse the data into a shader structure}
   q3ParseShaderData(data, c);

   {dispose of the data now}
   q3pDisposeStructure(data);
end;


{ DEFINITIONS }

function q3FindShaderDefinition(const def, sub: string; var ID: longint; var pdef: q3PShaderDefinition): longint;
var
   i: longint;
   matchID: longint           = -1; {a good match}
   exactID: longint           = -1; {exact match}
   ldef, lsub: string; {lowercase versions of def and sub}
   cdef: q3PShaderDefinition; {current definition}

begin
   {prepare and check}
   result      := -1;
   ID          := -1;
   pdef        := nil;

   if(q3ShaderDefinitionsP <> nil) then begin
      ldef := LowerCase(def);
      lsub := LowerCase(sub);

      {search through the definitions array}
      for i := 1 to (q3ShaderDefinitionsP^.nDefs) do begin
         cdef := @q3ShaderDefinitionsP^.Defs^[i];
         if(cdef^.sName <> nil) then begin
            {got a definition name match, which is a prerequisite}
            if(ldef = LowerCase(cdef^.sName^)) then begin
               {if there is a sub then we'll search through it}
               if(Length(lsub) > 0) then begin
                  {if this definition has a sub field}
                  if(cdef^.sSub <> nil) then begin
                     {if the sub field matches then we got a match otherwise}
                     if(lsub = LowerCase(cdef^.sSub^)) then begin
                        exactID := i;
                        break;
                     end;
                  {if there is no sub field we look for the possibility that the
                   first data type is a keyword}
                  end else begin
                     if(cdef^.DataTypes[0] = dtcSHORTSTRING)
                      or (cdef^.DataTypes[0] = dtcBOOL) then
                         matchID := i;
                  end;
               {In case only the name matches and there is no sub we set it as exact match. Though this may not be 
                true, it's a problem of the definition.}
               end else begin
                  exactID := i;
                  break;
               end;
            end;
         end;
      end;

      {return the best found ID}
      if(exactID > 0) then
         ID := exactID
      else
         ID := matchID;

      if(ID < 1) then
         exit(q3SHADER_FIND_NOT)
      else if(ID > 0) then begin
         pdef := @q3ShaderDefinitionsP^.Defs^[ID];
         if(exactID > -1) then
            exit(q3SHADER_FIND_EXACT)
         else
            exit(q3SHADER_FIND_MATCH);
      end;
   end;
end;

END.
