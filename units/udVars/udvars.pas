{
   udvars, manages dvar
   Copyright (c) 2011. Dejan Boras

   Started On:    28.05.2011.
}

{$IFDEF NODVAR}
   {$FATAL udvars should not be used when NODVAR is defined.}
{$ENDIF}

{$MODE OBJFPC}{$H+}{$MODESWITCH advancedrecords}
UNIT udvars;

INTERFACE

   USES uStd, StringUtils;

CONST
   { section separator }
   DVAR_SECTION_SEPARATOR           = '.';
   
   { notification routine specifiers }
   DVAR_NOTIFICATION_MODIFIED		   = $0001;
   DVAR_NOTIFICATION_UPDATE			= $0002;

TYPE
   { dvar properties }
   TDVarProperty = (
      dvarDO_NOT_SAVE, {do not save dvar to file}
      dvarINVISIBLE, {not visible by the user in console/ui}
      dvarREADONLY, {cannot be modified by user}
      dvarREADONLY_PROTECTED_MODE {cannot be modified by user in dvar protected mode}
   );

   TDVarProperties = set of TDVarProperty;


   PDVar       = ^TDVar;
   PDVarGroup  = ^TDVarGroup;

   {a type of routine which is notified when something is done on a dvar}
   TDVarNotifyRoutine = procedure(p: PDVar; what: longword);

   {a dvar}

   { TDVar }

   TDVar = record
      Name: string;
      DataType: longint; {data type of the variable}
      Variable: pointer; {pointer to the variable}
      pDefault: pointer; {default variable value}
      pNotify: TDVarNotifyRoutine; {a notification routine for the variable}
      Properties: TDVarProperties; {dvar properties}
      Next: PDVar; {next variable in group}

      { SET DVARS }
      { booleans }
      procedure Assign(b: boolean);

      { signed integers }
      procedure Assign(i: shortint);
      procedure Assign(i: smallint);
      procedure Assign(i: longint);
      procedure Assign(i: int64);
      { unsigned integers }
      procedure Assign(i: byte);
      procedure Assign(i: word);
      procedure Assign(i: dword);
      procedure Assign(i: qword);

      { floats }
      procedure Assign(i: single);
      procedure Assign(i: double);

      { strings }
      procedure Assign(const s: shortstring);
      procedure Assign(const s: ansistring);
      procedure Assign(const s: widestring);

      {will try to convert a string to a suitable data type for }
      function AssignFromString(const s: string): boolean;

      { GET VARIABLES }

      { signed integers }
      function GetShortInt(): shortint;
      function GetSmallInt(): smallint;
      function GetLongint(): longint;
      function GetInt64(): int64;

      { signed integers }
      function GetByte(): byte;
      function GetWord(): word;
      function GetDWord(): dword;
      function GetQWord(): qword;

      { floats }
      function GetSingle(): single;
      function GetDouble(): single;

      { strings }
      function GetShortString(): shortstring;
      function GetAnsiString(): ansistring;
      function GetWideString(): widestring;

      function GetString(): string;

      {gets the variable in a string representation}
      function GetAsString(): string;

      {initialize dvar}
      procedure Init(dt: longint; v: pointer; const newName: string = '');
   end;

   {a quick dvar representation}

   { TDVarQuick }

   TDVarQuick = record
      Name: string;
      DataType: longint;
      Variable: pointer;

      procedure Init(out dv: TDVar; v: pointer);
   end;

   {a linked list of dvariable groups}
   TDVarGroups = record
      s, 
      e: PDVarGroup;

      {adds the specified group to the list of groups}
      procedure Add(g: PDVarGroup);
   end;

   {a dvariable group}

   { TDVarGroup }

   TDVarGroup = record
      Name: string;

      vs,
      ve: PDVar;

      {subgroups}
      sub: TDVarGroups;

      Next: PDVarGroup;

      {adds a group as a subgroup to the specified parent group}
      procedure Add(var g: TDVarGroup);
      procedure Add(const newName: string; out g: TDVarGroup);
      {adds the specified dvar to dvar group}
      procedure Add(var a: TDVar);
      {quickly initialize and add a dvar}
      procedure Add(out a: TDVar; const newName: string; dt: longint; v: pointer);
      {adds the specified quick dvar to a group, using r as the actual dvar (assigned from a)}
      procedure Add(var a: TDVarQuick; var r: TDVar);

      {find a dvar in a this group}
      function Get(const findName: string): PDVar;
      {find a subgroup in this group}
      function GetGroup(const findName: string): PDVarGroup;

      function GetGroupCount(): longint;
      function GetGroupCountRecursive(): longint;
      function GetVariableCount(): longint;
      function GetVariableCountRecursive(): longint;
   end;

   { TDVarGlobal }

   TDVarGlobal = record
      {used to initialize a dvar or group}
      default: TDVar;
      defaultGroup: TDVarGroup;

      {list of global dvars (this is the root)}
      dvars: TDVarGroup;
      {a template for a root group}
      RootGroup: TDvarGroup;

      { initialize various variables }
      procedure Init(out a: TDVar);
      procedure Init(out g: TDVarGroup);
      procedure Init(out dv: TDVar; const n: string; dt: longint; v: pointer);

      {find a dvar}
      function Get(const name: string): PDVar;
      {find a dvar group}
      function GetGroup(const name: string): PDVarGroup;

      {add a group}
      procedure Add(var g: TDVarGroup);
      {initialize and add a group}
      procedure Add(const newName: string; out g: TDVarGroup);

      {get dvar count in the root group}
      function GetVariableCount(): loopint;
      {get dvar count recursively}
      function GetVariableCountRecursive(): loopint;
      {get group count in the root group}
      function GetGroupCount(): loopint;
      {get group count recursively}
      function GetGroupCountRecursive(): loopint;
   end;

VAR
   dvar: TDVarGlobal;

operator := (a: TDVarQuick): TDVar;

IMPLEMENTATION

{ TDVarQuick }

procedure TDVarQuick.Init(out dv: TDVar; v: pointer);
begin
   dv := Self;
   dv.Variable := v;
end;

{ TDVarGroup }

procedure TDVarGroup.Add(var g: TDVarGroup);
begin
   sub.Add(@g);
end;

procedure TDVarGroup.Add(const newName: string; out g: TDVarGroup);
begin
   g := dvar.defaultGroup;
   g.Name := newName;
   Add(g);
end;

procedure TDVarGlobal.Init(out a: TDVar);
begin
   a := dvar.default;
end;

procedure TDVarGlobal.Init(out g: TDVarGroup);
begin
   g := dvar.defaultGroup;
end;

procedure TDVarGlobal.Init(out dv: TDVar; const n: string; dt: longint; v: pointer);
begin
   dvar.Init(dv);
   dv.Name := n;
   dv.DataType := dt;
   dv.Variable := v;
end;


function TDVarGlobal.Get(const name: string): PDVar;
begin
   result := dvars.Get(name);
end;

function TDVarGroup.Get(const findName: string): PDVar;
var
   leftOver,
   section: string;
   subGroup: PDVarGroup;
   cur: PDVar;

begin
   leftOver := findName;
   section := CopyToDel(leftOver, DVAR_SECTION_SEPARATOR);

   StripWhitespace(leftOver);
   StripWhitespace(section);

   if(section = Name) then begin
      if(leftOver <> '') then
         exit(Get(leftOver))
      else
         exit(nil);
   end;

   if(leftOver <> '') then begin
      subGroup := GetGroup(section);

      if(subGroup <> nil) then
         exit(subGroup^.Get(leftOver));
   end else begin
      cur := vs;
      if(cur <> nil) then repeat
         if(cur^.Name = section) then
            exit(cur);

         cur := cur^.Next;
      until (cur = nil);
   end;

   result := nil;
end;

function TDVarGlobal.GetGroup(const name: string): PDVarGroup;
begin
   result := dvars.GetGroup(name);
end;

function TDVarGroup.GetGroup(const findName: string): PDVarGroup;
var
   leftOver,
   section: string;
   cur: PDVarGroup;

begin
   {if there is no section separator, it means we have no additional subgroup levels}
   if(pos(DVAR_SECTION_SEPARATOR, findName) = 0) then begin
      leftOver := '';
      section := findName;
   {with a section separator, we'll have to go through subgroups}
   end else begin
      leftOver := findName;
      section := CopyToDel(leftOver, DVAR_SECTION_SEPARATOR);

      StripWhitespace(leftOver);
      StripWhitespace(section);
   end;

   {if there is leftOver, search through subgroup levels}
   if(leftOver <> '') then begin
      cur := GetGroup(section);

      if(cur <> nil) then
         exit(cur^.GetGroup(leftOver));
   {otherwise search if any of the subgroups match}
   end else begin
      cur := sub.s;
      if(cur <> nil) then repeat
         if(cur^.Name = section) then
            exit(cur);

         cur := cur^.Next;
      until (cur = nil);
   end;

   result := nil;
end;

procedure TDVarGroup.Add(var a: TDVar);
begin
   Assert(Get(a.Name) = nil, 'dvar ' + a.Name + ' already exists in group ' + Name);

   a.Next := nil;

   if(vs = nil) then
      vs := @a
   else
      ve^.Next := @a;

   ve := @a;
end;

procedure TDVarGroup.Add(out a: TDVar; const newName: string; dt: longint; v: pointer);
begin
   a.Init(dt, v, newName);
   Add(a);
end;

procedure TDVarGroup.Add(var a: TDVarQuick; var r: TDVar);
begin
   r := a;

   Add(r);
end;

procedure TDVarGroups.Add(g: PDVarGroup);
begin
   g^.Next := nil;

   if(s = nil) then
      s := g
   else
      e^.Next := g;

   e := g;
end;

procedure TDVarGlobal.Add(var g: TDVarGroup);
begin
   dvars.sub.Add(@g);
end;

procedure TDVarGlobal.Add(const newName: string; out g: TDVarGroup);
begin
   dvar.Init(g);
   g.Name := newName;
   dvars.Add(g);
end;

function TDVarGlobal.GetVariableCount(): loopint;
begin
   Result := dvars.GetVariableCount();
end;

function TDVarGlobal.GetVariableCountRecursive(): loopint;
begin
   Result := dvars.GetVariableCountRecursive();
end;

function TDVarGlobal.GetGroupCount(): loopint;
begin
   Result := dvar.GetGroupCount();
end;

function TDVarGlobal.GetGroupCountRecursive(): loopint;
begin
   Result := dvar.GetGroupCountRecursive();
end;

function TDVarGroup.GetGroupCount(): longint;
var
   cur: PDVarGroup;
   n: longint = 0;

begin
   cur := sub.s;
   if(cur <> nil) then repeat
      inc(n);
      cur := cur^.Next;
   until (cur = nil);

   result := n;
end;

function TDVarGroup.GetGroupCountRecursive(): longint;
var
   cur: PDVarGroup;

begin
   Result := GetGroupCount();

   cur := sub.s;
   if(cur <> nil) then repeat
      Inc(Result, cur^.GetGroupCountRecursive());

      cur := cur^.Next;
   until (cur = nil);
end;

function TDVarGroup.GetVariableCount(): longint;
var
   cur: PDVar;
   n: longint = 0;

begin
   cur := vs;
   if(cur <> nil) then repeat
      inc(n);

      cur := cur^.Next;
   until (cur = nil);

   result := n;
end;

function TDVarGroup.GetVariableCountRecursive(): longint;
var
   cur: PDVarGroup;

begin
   Result := GetVariableCount();

   cur := sub.s;
   if(cur <> nil) then repeat
      Inc(Result, cur^.GetVariableCountRecursive());

      cur := cur^.Next;
   until (cur = nil);
end;

operator := (a: TDVarQuick): TDVar;
begin
   dvar.Init(result);

   result.Name       := a.Name;
   result.DataType   := a.DataType;
   result.variable   := a.variable;
end;

{ SET VARIABLE }

{ booleans }
procedure TDVar.Assign(b: boolean);
begin
   if(DataType = dtcBOOL) and (variable <> nil) then begin
      boolean(variable^) := b;

      {$INCLUDE dvarnotify.inc}
   end;
end;

{ signed integers }

procedure TDVar.Assign(i: shortint);
begin
   Assign(int64(i));
end;

procedure TDVar.Assign(i: smallint);
begin
   Assign(int64(i));
end;

procedure TDVar.Assign(i: longint);
begin
   Assign(int64(i));
end;

procedure TDVar.Assign(i: int64);
{$INCLUDE dvarsetint.inc}

{ unsigned integers }

procedure TDVar.Assign(i: byte);
begin
   Assign(int64(i));
end;

procedure TDVar.Assign(i: word);
begin
   Assign(int64(i));
end;

procedure TDVar.Assign(i: dword);
begin
   Assign(int64(i));
end;

procedure TDVar.Assign(i: qword);
{$INCLUDE dvarsetint.inc}

{ float }
procedure TDVar.Assign(i: single);
{$INCLUDE dvarsetfloat.inc}

procedure TDVar.Assign(i: double);
{$INCLUDE dvarsetfloat.inc}

{ strings }

procedure TDVar.Assign(const s: shortstring);
{$INCLUDE dvarsetstring.inc}

procedure TDVar.Assign(const s: ansistring);
{$INCLUDE dvarsetstring.inc}

procedure TDVar.Assign(const s: widestring);
{$INCLUDE dvarsetstring.inc}

{ GET VARIABLES }

{ signed integers }

function TDVar.GetShortInt(): shortint;
{$INCLUDE dvargetint.inc}

function TDVar.GetSmallInt(): smallint;
{$INCLUDE dvargetint.inc}

function TDVar.GetLongint(): longint;
{$INCLUDE dvargetint.inc}

function TDVar.GetInt64(): int64;
{$INCLUDE dvargetint.inc}

{ unsigned integers }

function TDVar.GetByte(): byte;
{$INCLUDE dvargetint.inc}

function TDVar.GetWord(): word;
{$INCLUDE dvargetint.inc}

function TDVar.GetDWord(): dword;
{$INCLUDE dvargetint.inc}

function TDVar.GetQWord(): qword;
{$INCLUDE dvargetint.inc}

{ floats }

function TDVar.GetSingle(): single;
{$INCLUDE dvargetfloat.inc}

function TDVar.GetDouble(): single;
{$INCLUDE dvargetfloat.inc}

{ strings }

function TDVar.GetShortString(): shortstring;
{$INCLUDE dvargetstring.inc}

function TDVar.GetAnsiString(): ansistring;
{$INCLUDE dvargetstring.inc}

function TDVar.GetWideString(): widestring;
{$INCLUDE dvargetstring.inc}

function TDVar.GetString(): string;
{$INCLUDE dvargetstring.inc}

{will try to convert a string to a suitable data type for }
function TDVar.AssignFromString(const s: string): boolean;
var
   ls: string = '';
   code: longint;
   signed: int64;
   unsigned: uint64;
   floatSingle: single;
   floatDouble: double;
   floatExtended: extended;

begin
   case DataType of
      dtcBOOL: begin
         ls := lowercase(s);
         if(ls = '0') or (ls = 'false') then begin
            Assign(false);
            exit(true);
         end else if(ls = '1') or (ls = 'true') then begin
            Assign(true);
            exit(true);
         end;
      end;
      dtcINT8,dtcINT16,dtcINT32,dtcINT64: begin
         val(s, signed, code);
         if(code = 0) then begin
            Assign(signed);
            exit(true);
         end;
      end;
      dtcUINT8, dtcUINT16, dtcUINT32, dtcUINT64: begin
         val(s, unsigned, code);
         if(code = 0) then begin
            Assign(unsigned);
            exit(true);
         end;
      end;
      dtcSINGLE: begin
         val(s, floatSingle, code);
         if(code = 0) then begin
            Assign(floatSingle);
            exit(true);
         end;
      end;
      dtcDOUBLE: begin
         val(s, floatDouble, code);
         if(code = 0) then begin
            Assign(floatDouble);
            exit(true);
         end;
      end;
      dtcEXTENDED: begin
         val(s, floatExtended, code);
         if(code = 0) then begin
            Assign(floatExtended);
            exit(true);
         end;
      end;
      dtcSHORTSTRING, dtcANSISTRING, dtcWIDESTRING: begin
         Assign(s);
         exit(true);
      end;
      else
         result := false;
   end;

   result := false;
end;

function TDVar.GetAsString(): string;
begin
   if(variable <> nil) then begin
      case DataType of
         dtcBOOL: result         := sf(boolean(variable^));

         dtcINT8: result         := sf(shortint(variable^));
         dtcINT16: result        := sf(smallint(variable^));
         dtcINT32: result        := sf(longint(variable^));
         dtcINT64: result        := sf(int64(variable^));

         dtcUINT8: result        := sf(byte(variable^));
         dtcUINT16: result       := sf(word(variable^));
         dtcUINT32: result       := sf(dword(variable^));
         dtcUINT64: result       := sf(qword(variable^));

         dtcSINGLE: result       := sf(single(variable^));
         dtcDOUBLE: result       := sf(double(variable^));

         dtcSHORTSTRING: result  := shortstring(variable^);
         dtcANSISTRING: result   := ansistring(variable^);
         dtcWIDESTRING: result   := {%H-}widestring(variable^);
         else
            result := '';
      end;
   end else
      result := '';
end;

procedure TDVar.Init(dt: longint; v: pointer; const newName: string = '');
begin
   Self.DataType := dt;
   Self.Variable := v;
   if(newName <> '') then
      Self.Name := newName;
end;

INITIALIZATION
   {create default dvar}
   dvar.default.name := '';
   dvar.default.DataType := -1;

   {create default group}
   ZeroOut(dvar.defaultGroup, SizeOf(dvar.defaultGroup));

   {prepare root group}
   dvar.RootGroup := dvar.defaultGroup;
   dvar.RootGroup.Name := '.';
   dvar.dvars := dvar.RootGroup;

END.

