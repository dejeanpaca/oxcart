{
   OXED, oX Editor

   @define OXED
   @define OX_PROJECT_DEFINES
   @define OX_LIBRARY_SUPPORT

   Started On:    22.03.2015.
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
