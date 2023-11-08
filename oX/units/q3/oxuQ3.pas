{
   oxuQ3, quake3 information and data
   Copyright (C) 2010. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuQ3;

INTERFACE

   USES vmVector;

CONST
   q3cUNIT                    =  1; {unit size}

   {player view and dimension}
   q3cMINS_Y                  = -24 * q3cUNIT;
   q3cMAXS_Y                  =  32 * q3cUNIT;
   q3cMAXS_Y_CROUCHED         =  16 * q3cUNIT;
   q3cDEFAULT_VIEWHEIGHT      =  26 * q3cUNIT;
   q3cCROUCH_VIEWHEIGHT       =  12 * q3cUNIT;
   q3cDEAD_VIEWHEIGHT         = -16 * q3cUNIT;

   {player model bounding boxes}
   q3cPlayerBBox: TBoundingBox = (
      (-15 * q3cUNIT, q3cMINS_Y, -15 * q3cUNIT),
      ( 15 * q3cUNIT, q3cMAXS_Y,  15 * q3cUNIT)
   );
   q3cPlayerCrouchBBox: TBoundingBox = (
      (-15 * q3cUNIT, q3cMINS_Y,          -15 * q3cUNIT),
      ( 15 * q3cUNIT, q3cMAXS_Y_CROUCHED,  15 * q3cUNIT)
   );

IMPLEMENTATION

END.
