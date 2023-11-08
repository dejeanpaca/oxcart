{
   oxuglParams, gl renderer command line parameters
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglParams;

INTERFACE

   USES
      uStd, uLog, ParamUtils,
      oxuOGL;

IMPLEMENTATION

VAR
   paramHandler: TParameterHandler;

function processParam(const paramKey: StdString; var params: array of StdString; n: longint): boolean;
var
   v: oglTVersion;

begin
   Result := false;
   v := oglDefaultVersion;

   if(n = 1) then begin
      ogl.GetVersion(params[0], v.Major, v.Minor, v.Revision, v.Profile);

      if(v.Major <> 0) then begin;
         oglDefaultVersion := v;

         log.v('gl version set to: ' + oglDefaultVersion.GetString());
         exit(true);
      end else
         log.e('Invalid gl version specified: ' + params[0]);
   end else
      log.e('Did not specify ' + paramKey + ' parameter value');
end;

INITIALIZATION
   parameters.AddHandler(paramHandler, 'gl.version', '-gl.version', @processParam);

END.
