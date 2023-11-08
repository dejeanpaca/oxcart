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

IMPLEMENTATION

VAR
   dvTargetFramerate,
   dvSyncMethod: TDVar;

procedure framerateNotify(var context: TDVarNotificationContext);
begin
   if(context.What = DVAR_NOTIFICATION_READ) or (context.What = DVAR_NOTIFICATION_MODIFIED) then
      oxRenderingTimer.Initialize(oxRenderingTimer, oxRenderSettings.TargetFramerate);
end;

INITIALIZATION
   oxRenderSettings.dvg.Add(dvTargetFramerate, 'framerate', dtcLOOPINT, @oxRenderSettings.TargetFramerate, [dvarNOTIFY_READ]);
   oxRenderSettings.dvg.Add(dvSyncMethod, 'sync', dtcENUM, @oxRenderSettings.Sync);
   dvTargetFramerate.pNotify := @framerateNotify;


END.
