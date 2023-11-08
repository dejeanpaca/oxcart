{
   oxeduBuildPlatform, handling build specifics for various platforms
   Copyright (C) 2017. Dejan Boras

   Started On:    19.07.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPlatform;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED;

TYPE
   { oxedTPlatform }
   oxedTPlatform = class
      {platform name}
      Name,
      {platform id, should match the fpc compiler define for the platform (windows, linux, android, darwin)}
      Id: string;
      {does it support a 64-bit cpu}
      Supports32,
      Supports64: boolean;

      GlyphName: string;
      GlyphCode: longword;

      {compiler symbols to use when building}
      CompilerSymbols: TPreallocatedStringArrayList;

      constructor Create; virtual;
   end;

   oxedTPlatformsList = specialize TPreallocatedArrayList<oxedTPlatform>;

   { oxedTPlatforms }

   oxedTPlatforms = record
      List: oxedTPlatformsList;
      CurrentId: string;

      procedure Initialize();
      procedure DeInitialize();

      procedure Add(platform: oxedTPlatform);
      function FindById(const id: string): oxedTPlatform;
      procedure Dispose();
   end;

VAR
   oxedPlatforms: oxedTPlatforms;
   {current platform on which the editor is running}
   oxedPlatform: oxedTPlatform;

IMPLEMENTATION

{ oxedTPlatform }

constructor oxedTPlatform.Create;
begin
   Name := 'Unknown';
   id := 'unknown';
   Supports32 := true;
   Supports64 := true;
end;

{ oxedTPlatforms }

procedure oxedTPlatforms.Initialize;
begin
   CurrentId := 'none';

   {$IFDEF WINDOWS}
   CurrentId := 'windows';
   {$ENDIF}
   {$IFDEF LINUX}
   CurrentId := 'linux';
   {$ENDIF}
   {$IFDEF ANDROID}
   CurrentId := 'android';
   {$ENDIF}
   {$IFDEF DARWIN}
   CurrentId := 'darwin';
   {$ENDIF}

   oxedPlatform := FindById(CurrentId);
   if(oxedPlatform = nil) then
      oxedPlatform := oxedTPlatform.Create();
end;

procedure oxedTPlatforms.DeInitialize;
begin
   if(oxedPlatform <> nil) and (oxedPlatform.Id = 'unknown') then
      FreeObject(oxedPlatform);
end;

procedure oxedTPlatforms.Add(platform: oxedTPlatform);
begin
   List.Add(platform);
end;

function oxedTPlatforms.FindById(const id: string): oxedTPlatform;
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].id = id) then
         exit(List.List[i]);
   end;

   result := nil;
end;

procedure oxedTPlatforms.Dispose();
var
   i: loopint;

begin
   for i := 0 to (List.n - 1) do begin
      FreeObject(List.List[i]);
   end;

   List.Dispose();
end;

procedure deinit();
begin
   oxedPlatforms.Dispose();
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.dAdd(oxedInitRoutines, 'platforms', @deinit);

   oxedPlatforms.List.InitializeValues(oxedPlatforms.List);

END.
