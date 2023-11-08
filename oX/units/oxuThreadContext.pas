{
   oxuThreadContext, thread context
   Copyright (C) 2018. Dejan Boras

   Started On:    31.03.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuThreadContext;

INTERFACE

   USES
      {oX}
      oxuMaterial;

TYPE
   oxTThreadContext = class
      Material: oxTMaterial;
   end;

THREADVAR
   oxThreadContext: oxTThreadContext;

IMPLEMENTATION

INITIALIZATION
   oxThreadContext := oxTThreadContext.Create();

END.

