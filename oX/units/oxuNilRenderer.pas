{
   oxuNilRenderer, oX nil renderer
   Copyright (C) 2017. Dejan Boras

   Started On:    13.11.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuNilRenderer;

INTERFACE

   USES
      uStd,
      {ox}
      uOX, oxuPlatform, oxuWindowTypes, oxuRenderer, oxuRenderers, oxuRunRoutines;

TYPE
   oxrTNilWindow = class(oxTWindow)
   end;

   { oxTNilRenderer }

   oxTNilRenderer = class(oxTRenderer)
      constructor Create; override;
   end;

IMPLEMENTATION

{ oxTNilRenderer }

constructor oxTNilRenderer.Create;
begin
   inherited;

   Name := 'nil';
   WindowInstance := oxrTNilWindow;
   PlatformInstance := oxTPlatform;
end;

procedure init();
begin
   oxNilRenderer := oxTNilRenderer.Create();

   oxRenderers.Register(oxNilRenderer);
   oxRenderer := oxNilRenderer;
end;

procedure deinit();
begin
   FreeObject(oxNilRenderer);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.PreInit.Add(initRoutines, 'ox.gl.renderer', @init, @deinit);

END.
