{
   oxuglShader, gl shader support
   Copyright (C) 2017. Dejan Boras

   Started On:    17.09.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuglMaterial;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      {ox}
      uOX, oxuMaterial, oxuRunRoutines,
      {gl}
      oxuglRenderer;

TYPE
   oxglMaterial = class(oxTMaterial)
   end;
   
IMPLEMENTATION

function componentReturn(): TObject;
begin
   result := oxglMaterial.Create();
end;

procedure init();
begin
   oxglRenderer.components.RegisterComponent('material', @componentReturn);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.PreInit.Add(initRoutines, 'ox.gl.material', @init);

END.
