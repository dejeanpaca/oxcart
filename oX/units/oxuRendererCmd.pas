{
   oxuRendererCmd
   Copyright (c) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuRendererCmd;

INTERFACE

   USES
      uStd, uLog, ParamUtils, oxuRendererSettings;

IMPLEMENTATION

VAR
   paramHandler: TParameterHandler;

function processParam(const {%H-}paramKey: StdString; var {%H-}params: array of StdString; n: longint): boolean;
begin
   Result := true;

   if(n = 0) then
      oxrTargetSettings.Software := true;
end;

INITIALIZATION
   parameters.AddHandler(paramHandler, 'renderer.software', '-renderer.software', @processParam, 0);

END.
