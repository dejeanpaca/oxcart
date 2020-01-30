{
   appuKeyMappings, keys
   Copyright (C) 2017. Dejan Boras

   Started On:    07.01.2017.
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

      procedure AddGroup(const gName, gDescription: string; out group: appTKeyMappingGroup);
      function Find(keyCode: longint; state: TBitSet): appPKeyMapping;
      function Find(const k: appTKey): appPKeyMapping;
      function Find(action: TEventID): appPKeyMapping;

      function Call(const k: appTKey): appPKeyMapping;
      function Call(keyCode: longint; state: TBitSet): appPKeyMapping;

      procedure Validate();
   end;

VAR
   {global key mappings}
   appKeyMappings: appTKeyMappings;

IMPLEMENTATION

{ appTKeyMapping }

procedure appTKeyMapping.CallEvent;
begin
   if(Action <> 0) then
      appActionEvents.Queue(Action);
end;

procedure appTKeyMapping.Call();
begin
   if(Callback <> nil) then
      Callback();

   CallEvent();
end;

procedure appTKeyMapping.FromString(const s: string);
begin
   Key.FromString(s)
end;

function appTKeyMapping.ToString(): string;
begin
   result := Key.ToString();
end;

{ appTKeyMappingGroup }

function appTKeyMappingGroup.AddKey(const kName, kDescription: string; const k: appTKey): appPKeyMapping;
var
   mapping: appTKeyMapping;
   existingMapping: appPKeyMapping;

begin
   ZeroOut(mapping, SizeOf(mapping));

   mapping.Name := kName;
   mapping.Description := kDescription;
   mapping.DefaultKey := k;
   mapping.Key := mapping.DefaultKey;

   existingMapping := Find(k.Code, k.State);
   if(existingMapping <> nil) then begin
      if(existingMapping^.Name <> kName) then
         log.w('Existing mapping (' + existingMapping^.Name  + ') exists in group ' + Name + ', but tried to add ' + kName + ' (' + k.ToString() + ')');

      exit(existingMapping);
   end;

   Keys.Add(mapping);

   result := @Keys.List[Keys.n - 1];
end;

function appTKeyMappingGroup.AddKey(const kName, kDescription: string; keyCode: longint; state: TBitSet): appPKeyMapping;
var
   k: appTKey;

begin
   ZeroOut(k, SizeOf(k));

   k.Code := keyCode;
   k.State := state;

   result := AddKey(kName, kDescription, k);
end;

function appTKeyMappingGroup.Find(keyCode: longint; state: TBitSet): appPKeyMapping;
var
   i: loopint;
   k: appTKey;

begin
   k.Assign(keyCode, state);

   if(Keys.n> 0) then
      for i := 0 to (Keys.n - 1) do begin
         if(Keys.List[i].Key.Equal(k)) then
            exit(@Keys.List[i]);
      end;

   result := nil;
end;

function appTKeyMappingGroup.Find(action: longint): appPKeyMapping;
var
   i: loopint;

begin
   if(Keys.n> 0) then
      for i := 0 to (Keys.n - 1) do begin
         if(Keys.List[i].Action = action) then
            exit(@Keys.List[i]);
      end;

   result := nil;
end;

procedure appTKeyMappingGroup.Validate();
var
   i: loopint;

begin
   for i := 0 to Keys.n - 1 do begin
      if(Keys.List[i].Action = 0) and (Keys.List[i].Callback = nil) then begin
         log.w('Key mapping: ' + Name + ' ' + Keys.List[i].Name + ' (' +  Keys.List[i].Key.ToString() + ') has no action or callback associated');
      end;
   end;
end;

{ appTKeyMappings }

constructor appTKeyMappings.Create;
begin
   appTKeyMappingGroups.Initialize(Groups);
end;

procedure appTKeyMappings.AddGroup(const gName, gDescription: string; out group: appTKeyMappingGroup);
begin
   ZeroOut(group, SizeOf(group));

   group.Name := gName;
   group.Description := gDescription;
   group.Keys.Initialize(group.Keys);

   Groups.Add(@group);
end;

function appTKeyMappings.Find(keyCode: longint; state: TBitSet): appPKeyMapping;
var
   i: loopint;

begin
   if(Groups.n > 0) then
      for i := 0 to (Groups.n - 1) do begin
         result := Groups.List[i]^.Find(keyCode, state);

         if(result <> nil) then
            exit;
      end;

   result := nil;
end;

function appTKeyMappings.Find(const k: appTKey): appPKeyMapping;
begin
   Result := Find(k.Code, k.State);
end;

function appTKeyMappings.Find(action: TEventID): appPKeyMapping;
var
   i: loopint;

begin
   if(Groups.n > 0) then
      for i := 0 to (Groups.n - 1) do begin
         result := Groups.List[i]^.Find(action);

         if(result <> nil) then
            exit;
      end;

   result := nil;
end;

function appTKeyMappings.Call(const k: appTKey): appPKeyMapping;
begin
   result := Call(k.Code, k.State);
end;

function appTKeyMappings.Call(keyCode: longint; state: TBitSet): appPKeyMapping;
begin
   Result := Find(keyCode, state);

   if(Result <> nil) then
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
