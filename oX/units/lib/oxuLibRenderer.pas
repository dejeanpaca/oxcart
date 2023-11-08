{
   oxuLibRenderer, oX lib renderer setup
   Copyright (C) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuLibRenderer;

INTERFACE

   USES
      uLog,
      {ox}
      oxuGlobalInstances,
      oxuWindowTypes, oxuWindows,
      oxuRenderer, oxuRenderers;

TYPE
   { oxTLibRenderer }

   oxTLibRenderer = record
      procedure Setup();
   end;

VAR
   oxLibRenderer: oxTLibRenderer;

IMPLEMENTATION

{ oxTLibRenderer }

procedure oxTLibRenderer.Setup();
var
   externalWindows: oxPWindows;

begin
   externalWindows := oxExternalGlobalInstances^.FindInstancePtr('oxTWindows');

   if(externalWindows = nil) then
      exit();

   {get the renderer from the first window}
   oxRenderers.vSelectedRenderer :=
      oxTRenderer(oxTWindow(externalWindows^.ExternalWindows.List[0].oxwParent).Renderer).Name;

   log.v('Lib using renderer: ' + oxRenderers.vSelectedRenderer);
   oxRenderers.SetRenderer();
end;

END.
