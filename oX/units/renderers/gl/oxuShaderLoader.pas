{
   oxuShaderLoader, shader loader renderer component
   Copyright (C) 2017. Dejan Boras

   Started On:    21.12.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuShaderLoader;

INTERFACE

   USES
      uOX, oxuRunRoutines, oxuFile,
      oxuShader, oxuRenderer, oxuRenderers;

TYPE

   { oxTShaderLoader }

   oxTShaderLoader = class
      function Load({%H-}shader: oxTShader; var {%H-}data: oxTFileRWData): boolean; virtual;
   end;

VAR
   oxShaderLoader: oxTShaderLoader;

IMPLEMENTATION

{ oxTShaderLoader }

function oxTShaderLoader.Load(shader: oxTShader; var data: oxTFileRWData): boolean;
begin
   Result := true;
end;

procedure onUse();
begin
   oxShaderLoader := oxTShaderLoader(oxRenderer.GetComponent('shader.loader'));
end;

procedure init();
begin
   oxRenderers.UseRoutines.Add(@onUse);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.PreInit.Add(initRoutines, 'ox.gl.shader_loader', @init);

END.
