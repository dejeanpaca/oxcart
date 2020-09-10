{
   oxuViewportType, provides viewport types
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuViewportType;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuTypes, oxuAspect;

TYPE
    oxPViewport = ^oxTViewport;

    oxTOnViewportChangeCallback = procedure(viewport: oxPViewport);

    {routine called when a viewport changes}
    oxTOnViewportChangeCallbacks = specialize TSimpleList<oxTOnViewportChangeCallback>;

    { oxTViewport }

    oxTViewport = record
       Name: StdString;

       {is the viewport enabled}
       Enabled,
       {the viewport has changed (size and/or position)}
       Changed: boolean;

       Position,
       {offset the position}
       Offset: oxTPoint;
       Dimensions: oxTDimensions;

       {always scissor when clearing}
       ScissorOnClear: boolean;

       ClearBits: TBitSet;
       ClearColor: TColor4f;

       a: oxTAspect;

      {called when viewport changes}
      OnChange: oxTOnViewportChangeCallbacks;
    end;

    oxTRelativeViewport = record
       Position: oxTPointf;
       Dimensions: oxTDimensionsf;
    end;

IMPLEMENTATION

END.
