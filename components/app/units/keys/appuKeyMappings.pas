{
   appuKeyMappings, keys
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuKeyMappings;

INTERFACE

   USES
      uStd, uLog,
      appuEvents, appuKeys, appuActionEvents;

TYPE
   appPKeyMapping = ^appTKeyMapping;

   { appTKeyMapping }

   appTKeyMapping = record
      Name: string;
      Description: string;

      DefaultKey,
      Key: appTKey;

      Action: TEventID;
      Callback: TProcedure;

      procedure CallEvent();
      procedure Call();

      {set key from string}
      procedure FromString(const s: string);
      {get key as string representation}
      function ToString(): string;
   end;

   appTKeyMappingList = specialize TSimpleList<appTKeyMapping>;

   appPKeyMappingGroup = ^appTKeyMappingGroup;

   { appTKeyMappingGroup }

   appTKeyMappingGroup = record
      Name: string;
      Description: string;

      Keys: appTKeyMappingList;

      function AddKey(const kName, kDescription: string; const k: appTKey): appPKeyMapping;
      function AddKey(const kName, kDescription: string; keyCode: longint; state: TBitSet): appPKeyMapping;
      function Find(keyCode: longint; state: TBitSet): appPKeyMapping;
      function Find(action: longint): appPKeyMapping;

      procedure Validate();
   end;

   appTKeyMappingGroups = specialize TSimpleList<appPkeyMappingGroup>;

   { appTKeyMappings }

   appTKeyMappings = class
      Groups: appTKeyMappingGroups;

      constructor Create;

      function Find(keyCode: longint; state: TBitSet): appPKeyMapping;
      function Find(const k: appTKey): appPKeyMapping;
      function Find(action: TEventID): appPKeyMapping;

      procedure AddGroup(const gName, gDescription: string; out group: appTKeyMappingGroup);
      function FindGroup(const gName: string): appPKeyMappingGroup;

      function Add(const gName: string; const kName, kDescription: string; const k: appTKey): appPKeyMapping;
      function Add(const gName: string; const kName, kDescription: string; keyCode: longint; state: TBitSet): appPKeyMapping;

      function Call(const k: appTKey): appPKeyMapping;
      function Call(keyCode: longint; state: TBitSet): appPKeyMapping;

      procedure Validate();
   end;

VAR
   {global key mappings}
   appKeyMappings: appTKeyMappings;

IMPLEMENTATION

{ appTKeyMapping }

procedure appTKeyMapping.CallEvent();
begin
   if Action <> 0 then
      appActionEvents.Queue(Action);
end;

procedure appTKeyMapping.Call();
begin
   if Callback <> nil then
      Callback();

   CallEvent();
end;

procedure appTKeyMapping.FromString(const s: string);
begin
   Key.FromString(s)
end;

function appTKeyMapping.ToString(): string;
begin
   Result := Key.ToString();
end;

{ appTKeyMappingGroup }

function appTKeyMappingGroup.AddKey(const kName, kDescription: string; const k: appTKey): appPKeyMapping;
var
   mapping: appTKeyMapping;
   existing: appPKeyMapping;

begin
   ZeroOut(mapping, SizeOf(mapping));

   mapping.Name := kName;
   mapping.Description := kDescription;
   mapping.DefaultKey := k;
   mapping.Key := mapping.DefaultKey;

   existing := Find(k.Code, k.State);
   if existing <> nil then begin
      if existing^.Name <> kName then
         log.w('Existing mapping (' + existing^.Name  + ') exists in group ' + Name + ', but tried to add ' +
            kName + ' (' + k.ToString() + ')');

      exit(existing);
   end;

   Keys.Add(mapping);

   Result := @Keys.List[Keys.n - 1];
end;

function appTKeyMappingGroup.AddKey(const kName, kDescription: string; keyCode: longint; state: TBitSet): appPKeyMapping;
var
   k: appTKey;

begin
   ZeroOut(k, SizeOf(k));

   k.Code := keyCode;
   k.State := state;

   Result := AddKey(kName, kDescription, k);
end;

function appTKeyMappingGroup.Find(keyCode: longint; state: TBitSet): appPKeyMapping;
var
   i: loopint;
   k: appTKey;

begin
   k.Assign(keyCode, state);

   if Keys.n > 0 then
      for i := 0 to Keys.n - 1 do begin
         if Keys.List[i].Key.Equal(k) then
            exit(@Keys.List[i]);
      end;

   Result := nil;
end;

function appTKeyMappingGroup.Find(action: longint): appPKeyMapping;
var
   i: loopint;

begin
   if Keys.n > 0 then
      for i := 0 to Keys.n - 1 do begin
         if Keys.List[i].Action = action then
            exit(@Keys.List[i]);
      end;

   Result := nil;
end;

procedure appTKeyMappingGroup.Validate();
var
   i: loopint;

begin
   for i := 0 to Keys.n - 1 do begin
      if(Keys.List[i].Action = 0) and (Keys.List[i].Callback = nil) then begin
         log.w('Key mapping: ' + Name + ' ' + Keys.List[i].Name + ' (' +  Keys.List[i].Key.ToString() +
            ') has no action or callback associated');
      end;
   end;
end;

{ appTKeyMappings }

constructor appTKeyMappings.Create;
begin
   appTKeyMappingGroups.Initialize(Groups);
end;

function appTKeyMappings.Find(keyCode: longint; state: TBitSet): appPKeyMapping;
var
   i: loopint;

begin
   if Groups.n > 0 then
      for i := 0 to Groups.n - 1 do begin
         Result := Groups.List[i]^.Find(keyCode, state);

         if Result <> nil then
            exit;
      end;

   Result := nil;
end;

function appTKeyMappings.Find(const k: appTKey): appPKeyMapping;
begin
   Result := Find(k.Code, k.State);
end;

function appTKeyMappings.Find(action: TEventID): appPKeyMapping;
var
   i: loopint;

begin
   if Groups.n > 0 then
      for i := 0 to Groups.n - 1 do begin
         Result := Groups.List[i]^.Find(action);

         if Result <> nil then
            exit;
      end;

   Result := nil;
end;

procedure appTKeyMappings.AddGroup(const gName, gDescription: string; out group: appTKeyMappingGroup);
begin
   ZeroOut(group, SizeOf(group));

   group.Name := gName;
   group.Description := gDescription;
   group.Keys.Initialize(group.Keys);

   Groups.Add(@group);
end;

function appTKeyMappings.FindGroup(const gName: string): appPKeyMappingGroup;
var
   i: loopint;

begin
   for i := 0 to Groups.n - 1 do begin
      if Groups.List[i]^.Name = gName then
         exit(Groups.List[i]);
   end;

   Result := nil;
end;

function appTKeyMappings.Add(const gName: string; const kName, kDescription: string; const k: appTKey): appPKeyMapping;
var
   g: appPKeyMappingGroup;

begin
   Result := nil;
   g := FindGroup(gName);

   if g <> nil then
      Result := g^.AddKey(kName, kDescription, k);
end;

function appTKeyMappings.Add(const gName: string; const kName,  kDescription: string; keyCode: longint; state: TBitSet): appPKeyMapping;
var
   k: appTKey;

begin
   k.Assign(keyCode, state);

   Result := Add(gName, kName, kDescription, k);
end;

function appTKeyMappings.Call(const k: appTKey): appPKeyMapping;
begin
   Result := Call(k.Code, k.State);
end;

function appTKeyMappings.Call(keyCode: longint; state: TBitSet): appPKeyMapping;
begin
   Result := Find(keyCode, state);

   if Result <> nil then
      Result^.Call();
end;

procedure appTKeyMappings.Validate();
var
   i: loopint;

begin
   for i := 0 to Groups.n - 1 do begin
      Groups.List[i]^.Validate();
   end;
end;

INITIALIZATION
   appKeyMappings := appTKeyMappings.Create();

FINALIZATION
   FreeObject(appKeyMappings);

END.
