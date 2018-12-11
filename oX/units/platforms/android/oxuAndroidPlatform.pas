{
   oxuAndroidPlatform, android platform
   Copyright (c) 2011. Dejan Boras

   Started On:    11.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAndroidPlatform;

INTERFACE

   USES
      oxuTypes, oxuPlatform, oxuWindowTypes;


IMPLEMENTATION

TYPE
   { oxTAndroidPlatform }

   TAndroidPlatform = class(oxTPlatform)
      constructor Create; override;

      function MakeWindow(wnd: oxTWindow): boolean; override;
   end;

{ oxTAndroidPlatform }

constructor TAndroidPlatform.Create;
begin
   Name := 'android';
end;

function TAndroidPlatform.MakeWindow(wnd: oxTWindow): boolean;
begin
   result := true;
end;

procedure setPlatform();
begin
   oxPlatform := TAndroidPlatform.Create();
end;

INITIALIZATION

   oxonSetPlatform := @setPlatform;
END.
