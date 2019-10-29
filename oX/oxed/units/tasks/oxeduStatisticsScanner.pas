{
   oxeduStatisticsScanner, project statistics scanner
   Copyright (C) 2019. Dejan Boras

   Started On:    29.09.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduStatisticsScanner;

INTERFACE

   USES
      uStd,
      oxeduProject, oxeduProjectScanner, oxeduProjectStatistics;

IMPLEMENTATION

procedure onFile(var f: oxedTScannerFile);
begin
   inc(oxedProjectStatistics.FileCount);
end;

procedure onStart();
begin
   oxedProjectStatistics.Reset();
end;

INITIALIZATION
   oxedProjectScanner.OnStart.Add(@onStart);
   oxedProjectScanner.OnFile.Add(@onFile);

END.
