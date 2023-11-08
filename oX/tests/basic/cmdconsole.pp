{
   Command Console

   Started On:    30.07.2012.
}

{$INCLUDE oxdefines.inc}
PROGRAM CommandConsole;

   USES
      {$INCLUDE oxappuses.inc},
      {app}
      uApp, appuKeys,
      {oX}
      oxuWindow, oxuWindows,
      uTestTools,
      oxuConsole, oxuconDVar;

procedure Initialize();
begin
   oxConsole.Activate();
end;

BEGIN
   appInfo.name   := 'Command Console';
   appInfo.name   := 'cmdconsole';

   ox.OnInitialize.Add(@Initialize);
   oxRun.Go();
END.

