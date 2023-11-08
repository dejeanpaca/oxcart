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
      oxuPlatform, oxuWindowTypes, oxuRenderer, oxuRenderers;

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
   Name := 'nil';
   WindowInstance := oxrTNilWindow;
   PlatformInstance := oxTPlatform;
   Init.Init('renderer.nil');
end;


INITIALIZATION
   oxNilRenderer := oxTNilRenderer.Create();
   oxNilRenderer.Init.Init('renderer.nil');

   oxRenderers.Register(oxNilRenderer);

   oxRenderer := oxNilRenderer;

FINALIZATION
   FreeObject(oxNilRenderer);

END.
