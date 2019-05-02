{
   oxuProjectionType, base projection type
   Copyright (c) 2011. Dejan Boras

   Started On:    09.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuProjectionType;

INTERFACE

   USES
      uStd, uColors, vmVector, uLog,
      {oX}
      oxuAspect, oxuTypes;

TYPE
   {projection properties}
   oxPProjectionSettings = ^oxTProjectionSettings;
   oxTProjectionSettings = record
      isOrtho: boolean; {is the projection orthographic?}
      fovY,
      zNear,
      zFar,
      l,
      r,
      b,
      t: double;
   end;

   oxPProjection = ^oxTProjection;

   { oxTProjection }

   oxTProjection = record
      Enabled: boolean;
      Name: string;

      Position,
      {offset the position}
      Offset: oxTPoint;
      Dimensions: oxTDimensions;

      {is the projection relative}
      Relative,
      {always scissor when clearing}
      ScissorOnClear: boolean;

      {set position and dimensions}
      Positionf: oxTPointf;
      Dimensionsf: oxTDimensionsf;

      ClearBits: TBitSet;
      ClearColor: TColor4f;

      p: oxTProjectionSettings;
      a: oxTAspect;
      ProjectionMatrix: TMatrix4f;
   end;

CONST
   oxDefaultProjection: oxTProjectionSettings = (
      isOrtho:    false;
      fovY:       45;
      zNear:      0.5;
      zFar:       1000.0;
      l:          -50;
      r:          50;
      b:          -50;
      t:          50
   );

IMPLEMENTATION

END.
