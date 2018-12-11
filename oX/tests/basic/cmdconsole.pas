{
   Command Console

   Started On:    30.07.2012.
}

{$INCLUDE oxdefines.inc}
PROGRAM CommandConsole;

   USES
      {app}
      uAppInfo, uApp, appuKeys,
      {oX}
      {$INCLUDE oxappuses.inc}, oxuWindow, oxuWindows,
      uTestTools,
      oxuConsole, oxuconDVar;

function Perform(a: oxTDoAction): boolean;
begin
   result := true;

   case a of
      oxDO_INITIALIZE:
         oxConsole.Activate();
   end;
end;

BEGIN
   appInfo.name   := 'Command Console';
   appInfo.name   := 'cmdconsole';

   ox.DoRoutines.Add(@Perform);
   oxRun.Go();
END.

