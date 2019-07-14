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
      IsOrtographic: boolean; {is the projection orthographic?}
      FovY,
      ZNear,
      ZFar,
      l,
      r,
      b,
      t: double;
   end;

   oxPProjection = ^oxTProjection;

   { oxTProjection }

   oxTProjection = record
      Name: string;

      {is the projection ortographic}
      IsOrtographic,
      {is the projection enabled}
      Enabled,
      {update from source (window) when source is resized}
      UpdateFromSource: boolean;

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
   oxDefaultPerspective: oxTProjectionSettings = (
      IsOrtographic: false;
      FovY:       60;
      ZNear:      0.5;
      ZFar:       1000.0;
      l:          -50;
      r:          50;
      b:          -50;
      t:          50
   );

   oxDefaultOrthographic: oxTProjectionSettings = (
      IsOrtographic: true;
      FovY:       60;
      ZNear:      -1.0;
      ZFar:       1.0;
      l:          -50;
      r:          50;
      b:          -50;
      t:          50
   );

IMPLEMENTATION

END.
