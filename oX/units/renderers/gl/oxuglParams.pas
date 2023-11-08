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
   major,
   minor,
   revision: longword;
   profile: oglTProfile;

begin
   Result := false;

   if(n = 1) then begin
      ogl.GetVersion(params[0], major, minor, revision, profile);

      if(major <> 0) then begin;
         oglDefaultVersion.Major := major;
         oglDefaultVersion.Minor := minor;
         oglDefaultVersion.Profile := profile;

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
