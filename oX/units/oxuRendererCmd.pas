{
   oxuRendererCmd
   Copyright (c) 2019. Dejan Boras

   Started On:    15.10.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuRendererCmd;

INTERFACE

   USES
      uStd, uLog, ParamUtils, oxuWindowTypes;

IMPLEMENTATION

VAR
   paramHandler: TParameterHandler;

function processParam(const {%H-}paramKey: StdString; var {%H-}params: array of StdString; n: longint): boolean;
begin
   Result := true;

   if(n = 0) then
      oxrDefaultWindowSettings.Software := true;
end;

INITIALIZATION
   parameters.AddHandler(paramHandler, 'renderer.software', '-renderer.software', @processParam, 0);

END.
