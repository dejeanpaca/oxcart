{
   oxuAspect, calculates aspect properties
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuAspect;

INTERFACE

   USES uStd;

TYPE
   { ASPECT }
   {aspect properties}
   oxTAspect = record
      Aspect,
      acQ,
      acX,
      acY,
      acNX,
      acNY: single;

      procedure Calculate(w, h: single);
   end;

procedure oxInitAspect(out a: oxTAspect);

IMPLEMENTATION

procedure oxInitAspect(out a: oxTAspect);
begin
   ZeroOut(a, SizeOf(a));
end;

procedure oxTAspect.Calculate(w, h: single);
begin
   Aspect := w / h;
   
   acX   := 1.0;
   acY   := 1.0;
   acNX  := 1.0;
   acNY  := 1.0;

   {vertical aspect correction}
   if(Aspect < 1.0) then begin
      acY   := h / w;
      acQ   := acY;
      acNY  := 1.0 / Aspect;
   {horizontal aspect correction}
   end else if(Aspect > 1.0) then begin
      acX   := w / h;
      acQ   := acX;
      acNX  := 1.0 / Aspect;
   end;
end;

END.
