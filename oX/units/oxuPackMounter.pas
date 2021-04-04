{
   oxuPackMounter
   Copyright (c) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuPackMounter;

INTERFACE

USES
   ypkuFS
   {$IFDEF ANDROID}
   , oxuAndroidAssets
   {$ENDIF};

IMPLEMENTATION

INITIALIZATION

END.
