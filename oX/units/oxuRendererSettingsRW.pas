{
   oxuWindowTypes, oX window data types
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRendererSettingsRW;

INTERFACE

   USES
      uStd, udvars,
      {ox}
      uOX, oxuTimer, oxuRendererSettings;

VAR
   oxRenderSettings: oxTRenderSettings;

IMPLEMENTATION

VAR
   dvTargetFramerate: TDVar;

procedure framerateNotify(var context: TDVarNotificationContext);
begin
   if(context.What = DVAR_NOTIFICATION_READ) then
      oxRenderingTimer.Initialize(oxRenderingTimer, oxRenderSettings.TargetFramerate);
end;

INITIALIZATION
   ox.dvar.Add('render', oxRenderSettings.dvg);
   oxRenderSettings.TargetFramerate := 60;
   oxRenderSettings.dvg.Add(dvTargetFramerate, 'framerate', dtcLOOPINT, @oxRenderSettings.TargetFramerate, [dvarNOTIFY_READ]);
   dvTargetFramerate.pNotify := @framerateNotify;


END.
