{
   OXED, oX Editor
   Copyright (C) 2016. Dejan Boras

   @define OXED
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

   appInfo.SetName('OXED');
   appInfo.SetVersion(0, 2);

   oxRun.Go();
END.
