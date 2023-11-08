{
   oxuViewportType, provides viewport types
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuViewportType;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuTypes, oxuAspect;

TYPE

    oxPViewport = ^oxTViewport;

    { oxTViewport }

    oxTViewport = record
       Name: StdString;

       {is the viewport enabled}
       Enabled,
       {update from source (window) when source is resized}
       UpdateFromSource: boolean;

       Position,
       {offset the position}
       Offset: oxTPoint;
       Dimensions: oxTDimensions;

       {is the viewport relative}
       Relative,
       {always scissor when clearing}
       ScissorOnClear: boolean;

       {set position and dimensions}
       Positionf: oxTPointf;
       Dimensionsf: oxTDimensionsf;

       ClearBits: TBitSet;
       ClearColor: TColor4f;

       a: oxTAspect;
    end;

IMPLEMENTATION

END.
