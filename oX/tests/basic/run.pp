{
   As basic as it gets. Includes minimal functionality needed to run a oX based program.

   Started On:    26.08.2013.
}


{$INCLUDE oxdefines.inc}
PROGRAM run;

   USES
      {oX}
      {$INCLUDE oxappuses.inc};

BEGIN
   appInfo.SetName('Run Test');

   oxRun.Go();
END.
