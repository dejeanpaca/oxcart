{
   As basic as it gets. Includes minimal functionality needed to run a oX based program.
   Copyright (C) 2013. Dejan Boras
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
