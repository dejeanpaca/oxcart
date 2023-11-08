{
   oxuglParams, gl renderer command line parameters
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglParams;

INTERFACE

   USES
      uStd, uLog, ParamUtils,
      oxuOGL;

IMPLEMENTATION

VAR
   paramHandler: TParameterHandler;

function processParam(const {%H-}paramKey: StdString; var params: array of StdString; n: longint): boolean;
var
   v: oglTVersion;

begin
   Result := false;
   v := oglDefaultVersion;

   if(n = 1) then begin
      ogl.GetVersion(params[0], v.major, v.minor, v.revision, v.profile);

      if(v.Major <> 0) then begin;
         oglDefaultVersion := v;

         log.v('gl version set to: ' + oglDefaultVersion.GetString());
         exit(true);
      end else
         log.e('Invalid gl version specified: ' + params[0]);
   end else
      log.e('Did not specify ' + paramHandler.ParamKey + ' parameter value');
end;

INITIALIZATION
   parameters.AddHandler(paramHandler, 'gl.version', '-gl.version', @processParam);

END.
