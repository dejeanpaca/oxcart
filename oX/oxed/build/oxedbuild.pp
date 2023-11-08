{
   OXED build, oX project builder
   Copyright (C) 2020. Dejan Boras

   @define OXED
   @defined OXED_BUILD
   @define NO_UI
   @define OX_PROJECT_DEFINES
   @define OX_LIBRARY_SUPPORT
}

{$INCLUDE oxdefines.inc}
PROGRAM oxed;

   USES
      {$INCLUDE oxappuses.inc},
      {oxed}
      uOXED, oxeduInitialize;

BEGIN
   {$IF DECLARED(UseHeapTrace)}
   uOXED.oxed.UseHeapTrace := true;
   {$ENDIF}
   {$IF DECLARED(cmem)}
   uOXED.oxed.UseCMEM := true;
   {$ENDIF}

   appInfo.SetName('OXED Build');
   appInfo.SetVersion(0, 5);

   oxRun.Go();
END.
