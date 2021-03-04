{
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
PROGRAM test;

   USES uLog, uStd, udvars, dvaruFile, ParamUtils, dvaruConParamHandler;

VAR
   orcinusx: record
      settings: record
         mouse: record
            sensitivity: record
               x: single;
            end;
            deviceName: shortstring;
         end;
      end;
   end;

VAR
   dvgORCINUSX:      TDVarGroup = (Name: 'orcinusx';     vs: nil; ve: nil; sub: (s: nil; e: nil); Next: nil);
   dvgSETTINGS:      TDVarGroup = (Name: 'settings';     vs: nil; ve: nil; sub: (s: nil; e: nil); Next: nil);
   dvgMOUSE:         TDVarGroup = (Name: 'mouse';        vs: nil; ve: nil; sub: (s: nil; e: nil); Next: nil);
   dvgSENSITIVITY:   TDVarGroup = (Name: 'sensitivity';  vs: nil; ve: nil; sub: (s: nil; e: nil); Next: nil);

   qdvX: TDVarQuick = (Name: 'x'; DataType: dtcSINGLE; variable: @orcinusx.settings.mouse.sensitivity.x);
   qdX: TDVar;
   qdvDevice: TDVarQuick = (Name: 'devicename'; DataType: dtcSHORTSTRING; variable: @orcinusx.settings.mouse.deviceName);
   qdDevice: TDVar;

VAR
  pv: PDVar;
  pg: PDVarGroup;

BEGIN
   orcinusx.settings.mouse.deviceName := 'mouse0';
   logInitStd('test.log', 'DVar Test', logcREWRITE);

   addDVarGroup(dvgORCINUSX);
   addSubDVarGroup(dvgSETTINGS, dvgORCINUSX);
   addSubDVarGroup(dvgMOUSE, dvgSETTINGS);
   addSubDVarGroup(dvgSENSITIVITY, dvgMOUSE);

   addDVarToGroup(qdvX, qdX, dvgSENSITIVITY);
   addDVarToGroup(qdvDevice, qdDevice, dvgMOUSE);

   if(ProcessParameters()) then begin

      pg := getDVarGroup('orcinusx.settings.mouse');

      if(pg <> nil) then begin
         pv := getDVar(pg^, 'sensitivity.x');
         if(pv <> nil) then begin
            writeln('before: ', dvarGetSingle(pv^):0:2);
            dvarSet(pv^, 1.0);

            writeln('after: ', dvarGetSingle(pv^):0:2);
         end else
            writeln('Variable could not be found.');
      end;

      dvarfSave('file.dvar');
   end;

   dvarWriteTextFile('test.dvar.txt');
   readln;
   dvarReadTextFile('test.dvar.txt');
END.
