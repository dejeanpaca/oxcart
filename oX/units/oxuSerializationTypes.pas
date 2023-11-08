{
   oxuTypes, common oX data types
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuSerializationTypes;

INTERFACE

   USES
      oxuTypes, oxuSerialization;

TYPE
   oxTSerializationTypes = record
     tPoint,
     tDimensions,
     tPointf,
     tDimensionsf: oxTSerializationDataType;
   end;

VAR
   oxSerializationTypes: oxTSerializationTypes;

IMPLEMENTATION

procedure init();
begin
   oxSerializationTypes.tPoint.InitRecord(SizeOf(oxTPoint));
   oxSerializationTypes.tPoint.Name := 'oxTPoint';

   oxSerializationTypes.tDimensions.InitRecord(SizeOf(oxTDimensions));
   oxSerializationTypes.tDimensions.Name := 'oxTDimensions';

   oxSerializationTypes.tPointf.InitRecord(SizeOf(oxTPointf));
   oxSerializationTypes.tPointf.Name := 'oxTPointf';

   oxSerializationTypes.tDimensionsf.InitRecord(SizeOf(oxTDimensionsf));
   oxSerializationTypes.tDimensionsf.Name := 'oxTDimensionsf';
end;

INITIALIZATION
   init();

END.
