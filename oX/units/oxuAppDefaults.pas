{
   oxuAppDefaults, makes the engine behave like an app
   Copyright (c) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAppDefaults;

INTERFACE

   USES
      oxuWindows;

IMPLEMENTATION

INITIALIZATION
   {apps should not interfere with idle/power settings}
   oxWindows.AllowScreenIdle := true;

END.
