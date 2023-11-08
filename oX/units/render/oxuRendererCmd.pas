{
   oxuRendererCmd
   Copyright (c) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRendererCmd;

INTERFACE

   USES
      uStd, uLog, ParamUtils,
      {ox}
      oxuRendererSettings, oxuRenderer, oxuRenderers;

IMPLEMENTATION

VAR
   softwareParamHandler,
   rendererParamHandler: TParameterHandler;

function processParam(const {%H-}paramKey: StdString; var {%H-}params: array of StdString; n: longint): boolean;
var
   name: StdString;
   renderer: oxTRenderer;

begin
   Result := true;

   if(paramKey = softwareParamHandler.ParamKey) then begin
      if(n = 0) then
         oxrTargetSettings.Software := true;
   end else if(paramKey = rendererParamHandler.ParamKey) then begin
      Result := false;

      if(n = 1) then begin
         name := LowerCase(params[0]);
         renderer := oxRenderers.Find(name);

         if(renderer <> nil) then begin
            oxRenderers.OverrideRenderer := renderer;
            log.i('Specified renderer: ' + renderer.Name);

            exit(true);
         end else
            log.w('Could not find renderer: ' + params[0]);
      end else
         log.e('Did not specify ' + rendererParamHandler.ParamKey + ' parameter value');
   end;
end;

INITIALIZATION
   parameters.AddHandler(softwareParamHandler, 'renderer.software', '-renderer.software', @processParam, 0);
   parameters.AddHandler(rendererParamHandler, 'renderer', '-renderer', @processParam);

END.
