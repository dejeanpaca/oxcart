{
   oxuglRendererEGL, gl egl renderer
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglRendererEGL;

INTERFACE

   USES
      oxuglRendererPlatform, oxuglRenderer;

TYPE
   { oxglTEGL }

   oxglTEGL = object(oxglTPlatform)
      Major,
      Minor: longint;

      procedure OnInitialize(); virtual;
   end;

VAR
   oxglEGL: oxglTEGL;

IMPLEMENTATION

{ oxglTEGL }

procedure oxglTEGL.OnInitialize();
begin

end;

INITIALIZATION
   oxglEGL.Create();
   oxglTRenderer.glPlatform := @oxglEGL;

END.
