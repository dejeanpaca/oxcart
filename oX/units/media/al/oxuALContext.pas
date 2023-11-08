{
   daluContext, OpenAL context management
   Copyright (C) 2009. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuALContext;

INTERFACE

   USES
      uLog,
      openal, oxuAL;

TYPE
   { oxalTContext }

   oxalTContext = class
      alContext: PALCcontext;

      Frequency,
      RefreshRate,
      MonoSourcesHint,
      StereoSourcesHint: int32;
      Synced: boolean;

      constructor Create();

      function Select(): boolean; virtual;
      class function SelectDefault(): boolean; static;

      {create a context}
      function Create(const dev: PALCdevice): boolean;
      {destroy a context}
      function Dispose(): boolean;

      destructor Destroy; override;

      {create the default context}
      class function CreateDefault(const dev: PALCdevice): boolean; static;
   end;

VAR
   {a default context}
   oxalContext: oxalTContext;
   oxalCurrentContext: oxalTContext;

IMPLEMENTATION

{create the default context}
class function oxalTContext.CreateDefault(const dev: PALCdevice): boolean;
begin
   {create context}
   Result := oxalContext.Create(dev);

   if(not Result) then
      log.e('Failed to create the default context.');

   oxal.cGetError();

   oxalContext.Select();
end;

{ oxalTContext }

constructor oxalTContext.Create;
begin
   inherited Create;

   Frequency := 44100;
   RefreshRate := -1;
   MonoSourcesHint := -1;
   StereoSourcesHint := -1;
end;

function oxalTContext.Select(): boolean;
begin
   oxalCurrentContext := Self;

   if(alContext <> nil) then
      Result := alcMakeContextCurrent(alContext)
   else
      Result := alcMakeContextCurrent(nil);

   oxal.cGetError();
end;

class function oxalTContext.SelectDefault: boolean;
begin
   oxalCurrentContext := Nil;

   Result := alcMakeContextCurrent(nil);
   oxal.cGetError();
end;

function oxalTContext.Create(const dev: PALCdevice): boolean;
begin
   Result := true;

   if(alContext = nil) then begin
      alContext := alcCreateContext(dev, nil);

      if(alContext <> nil) then begin
         Select();
      end else begin
         oxal.cGetError();
         Result := false;
      end
   end;
end;

function oxalTContext.Dispose(): boolean;
begin
   Result := true;

   if(alContext <> nil) then begin
      oxalTContext.SelectDefault();

      alcDestroyContext(alContext);
      alContext := nil;

      oxal.cGetError();
   end;
end;

destructor oxalTContext.Destroy;
begin
   inherited;

   Dispose();
end;

END.
