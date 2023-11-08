{
   oxuInputUpdater, updates input state in library mode
   Copyright (C) 2010. Dejan Boras

   Started On:    25.08.2010.
}

{$INCLUDE oxdefines.inc}
UNIT oxulibInputUpdater;

INTERFACE

   USES
      uStd, appuRun, appuKeys, uLog,
      {ox}
      uOX, oxuGlobalInstances;

IMPLEMENTATION

var
   appkExt: appPKeyGlobal;

procedure init();
begin
   appkExt := oxExternalGlobalInstances.FindInstancePtr('appTKeyGlobal');

   if(appkExt = nil) then
      log.w('Failed to obtain external appk');
end;

procedure updateInput();
begin
   if(appkExt <> nil) then begin
      appk.Modifiers := appkExt^.Modifiers;
      appk.Pressed := appkExt^.Pressed;
   end;
end;

VAR
   routine: appTRunRoutine;

INITIALIZATION
   appRun.AddRoutine(routine, 'ox.lib.update_input', @updateInput);

   ox.Init.iAdd('ox.lib.update_input', @init);

END.
