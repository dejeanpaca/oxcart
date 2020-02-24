{
   oxuglTransform, OpenGL transform matrix
   Copyright (C) 2013. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglTransform;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      vmVector,
      {ox}
      uOX, oxuRunRoutines, oxuTransform, oxuglRenderer;

TYPE

   { oxglTTransform }

   oxglTTransform = class(oxTTransform)
      procedure Apply(); override;
   end;

VAR
   oxglTransform: oxglTTransform;

IMPLEMENTATION

{ oxglTTransformMatrixHelper }

procedure oxglTTransform.Apply();
var
   transposed: TMatrix4f;

begin
   transposed := Matrix.Transposed();

   glLoadMatrixf(@transposed[0, 0]);
end;

function componentReturn(): TObject;
begin
   result := oxglTTransform.Create();
end;

procedure init();
begin
   oxglRenderer.components.RegisterComponent('transform', @componentReturn);
end;

INITIALIZATION
   ox.PreInit.Add('ox.gl.transform', @init);

END.
