{
   Command Console
   Copyright (C) 2012. Dejan Boras
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

