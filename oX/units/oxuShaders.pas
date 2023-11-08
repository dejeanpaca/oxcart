{
   oxuShaders, oX shader management
   Copyright (C) 2009. - 2010. Dejan Boras

   Started On:    21.12.2009.

   Note: OX_EXTRA_SHADER_LOGGING can be used to make the unit output extra logging information.
}

{$INCLUDE oxdefines.inc}
UNIT oxuShaders;

INTERFACE

   USES
      {oX}
      oxuResourcePool;

TYPE

   { oxTShaderPool }

   oxTShaderPool = class(oxTResourcePool)
      constructor Create(); override;
   end;

VAR
   oxShaderPool: oxTShaderPool;

IMPLEMENTATION

{ oxTShaderPool }

constructor oxTShaderPool.Create();
begin
   inherited;

   Name := 'shader';
end;

END.
