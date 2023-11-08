{
   oxuConsolePlatform, console platform base functionality
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuConsolePlatform;

INTERFACE

   USES
      Video, Keyboard, Mouse,
      {oX}
      oxuPlatform;

TYPE
   { oxTConsolePlatform }

   oxTConsolePlatform = class(oxTPlatform)
      constructor Create(); override;

      procedure ProcessEvents(); override;
   end;

IMPLEMENTATION

{ oxTConsolePlatform }

constructor oxTConsolePlatform.Create();
begin
   Name := 'console';
end;

procedure oxTConsolePlatform.ProcessEvents();
begin
end;

END.
