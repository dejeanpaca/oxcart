{
   oxeduStatisticsScanner, project statistics scanner
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduStatisticsScanner;

INTERFACE

   USES
      uStd, uFileUtils,
      {oxed}
      uOXED,
      oxeduProject, oxeduProjectScanner, oxeduProjectWalker, oxeduProjectStatistics;

IMPLEMENTATION

procedure onFile(var f: oxedTProjectWalkerFile);
var
   i: loopint;

   statistics: oxedPFileTypeStatistics;

begin
   inc(oxedProjectStatistics.FileCount);

   i := oxedProjectStatistics.FileTypes.FindByExtension(f.Extension);

   inc(oxedProjectStatistics.TotalSize, f.fd.Size);

   if(i > -1) then begin
      inc(oxedProjectStatistics.FileTypes.List[i].Count);
      statistics := @oxedProjectStatistics.FileTypes.List[i];
   end else begin
      oxedProjectStatistics.FileTypes.Add(f.Extension);
      statistics := oxedProjectStatistics.FileTypes.GetLast();
   end;

   if(statistics <> nil) then begin
      inc(statistics^.TotalSize, f.fd.Size);
      inc(statistics^.Count);
   end;
end;

procedure onStart();
begin
   oxedProjectStatistics.Reset();
end;

procedure initialize();
begin
   oxedProjectScanner.OnStart.Add(@onStart);
   oxedProjectScanner.OnFile.Add(@onFile);
end;

INITIALIZATION
   oxed.Init.Add('statistics_scanner', @initialize);

END.
