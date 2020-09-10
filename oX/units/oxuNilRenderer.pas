{
   oxuNilRenderer, oX nil renderer
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
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
   Id := 'nil';
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

INITIALIZATION
   ox.PreInit.Add('gl.renderer', @init, @deinit);

END.
