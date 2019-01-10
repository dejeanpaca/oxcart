{
   oxeduNilComponent, oxed nil component
   Copyright (C) 2019. Dejan Boras

   Started On:    10.01.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduNilComponent;

INTERFACE

   USES
      uStd,
      {ox}
      oxeduEditRenderers, oxeduComponent, oxeduComponentGlyphs;

TYPE
   { oxedTNilEditRenderer }

   oxedTNilEditRenderer = class(oxedTEditRenderer)
      constructor Create();
   end;

VAR
   oxedNilEditRenderer: oxedTNilEditRenderer;

IMPLEMENTATION

{ oxedTNilEditRenderer }

constructor oxedTNilEditRenderer.Create();
begin
   Name := 'Nil';

   oxedComponentGlyphs.Add(nil);
   Associate(nil);
end;

procedure init();
begin
   oxedNilEditRenderer := oxedTNilEditRenderer.Create();
end;

procedure deinit();
begin
   FreeObject(oxedNilEditRenderer);
end;

INITIALIZATION
   oxedEditRenderers.Init.Add('nil', @init, @deinit);

END.
