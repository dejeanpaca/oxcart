{
   uPasSourceHelper
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uPasSourceHelper;

INTERFACE

   USES
      uStd;

TYPE
   { TPascalSourceBuilder }

   TPascalSourceBuilder = record
      Name,
      Header,
      sInterface,
      sImplementation,
      sUses,
      sExports,
      sInitialization,
      sMain: TAppendableString;

      procedure AddUses(var p: TAppendableString);

      function BuildUnit(): TAppendableString;
      function BuildProgram(): TAppendableString;
      function BuildLibrary(): TAppendableString;

      class procedure Initialize(out s: TPascalSourceBuilder); static;
   end;

IMPLEMENTATION

{ TPascalUnitBuilder }

procedure TPascalSourceBuilder.AddUses(var p: TAppendableString);
begin
   if(sUses <> '') then begin
      p.Add('USES');
      p.Add(sUses + ';');
      p.Add('');
   end;
end;

function TPascalSourceBuilder.BuildUnit(): TAppendableString;
begin
   Result := '';

   if(Header <> '') then
      Result.Add(Header);

   Result.Add('UNIT ' + Name + ';');
   Result.Add('');

   Result.Add('INTERFACE');

   AddUses(Result);

   if(sInterface <> '') then begin
      Result.Add('');
      Result.Add(sInterface);
   end;

   Result.Add('');

   Result.Add('IMPLEMENTATION');
   Result.Add('');

   if(sImplementation <> '') then begin
      Result.Add(sImplementation);
      Result.Add('');
   end;

   if(sInitialization <> '') then begin
      Result.Add('INITIALIZATION');
      Result.Add(sInitialization);
      Result.Add('');
   end;

   Result.Add('END.');
end;

function TPascalSourceBuilder.BuildProgram(): TAppendableString;
begin
   Result := '';

   if(Header <> '') then
      Result.Add(Header);

   Result.Add('PROGRAM ' + Name + ';');
   Result.Add('');

   if(sUses <> '') then
      AddUses(Result);

   Result.Add('BEGIN');

   if(sMain <> '') then begin
      Result.Add('');
      Result.Add(sMain);
   end;

   Result.Add('');
   Result.Add('END.');
end;

function TPascalSourceBuilder.BuildLibrary(): TAppendableString;
begin
   Result := '';

   if(Header<> '') then
      Result.Add(Header);

   Result.Add('LIBRARY ' + Name + ';');
   Result.Add('');

   if(sUses <> '') then
      AddUses(Result);

   if(sInterface <> '') then begin
      Result.Add('');
      Result.Add(sInterface);
   end;

   if(sExports <> '') then begin
      Result.Add('EXPORTS');
      Result.Add(sExports + ';');
      Result.Add('');
   end;

   if(sInitialization <> '') then begin
      Result.Add('INITIALIZATION');
      Result.Add(sInitialization);
      Result.Add('');
   end;

   Result.Add('END.');
end;

class procedure TPascalSourceBuilder.Initialize(out s: TPascalSourceBuilder);
begin
   ZeroOut(s, SizeOf(s));
end;

END.
