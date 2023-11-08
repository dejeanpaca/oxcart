{
   oxeduStatisticsScanner, project statistics scanner
   Copyright (C) 2019. Dejan Boras

   Started On:    29.09.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduStatisticsScanner;

INTERFACE

   USES
      uStd, uFileUtils,
      oxeduProject, oxeduProjectScanner, oxeduProjectStatistics;

IMPLEMENTATION

procedure onFile(var f: oxedTScannerFile);
var
   i: loopint;
   fi: TFileDescriptor;

   statistics: oxedPFileTypeStatistics;

begin
   inc(oxedProjectStatistics.FileCount);

   i := oxedProjectStatistics.FileTypes.FindByExtension(f.Extension);
   FileUtils.GetFileInfo(f.FileName, fi);

   inc(oxedProjectStatistics.TotalSize, fi.Size);

   if(i > -1) then begin
      inc(oxedProjectStatistics.FileTypes.List[i].Count);
      statistics := @oxedProjectStatistics.FileTypes.List[i];
   end else begin
      oxedProjectStatistics.FileTypes.Add(f.Extension);
      statistics := oxedProjectStatistics.FileTypes.GetLast();
   end;


   if(statistics <> nil) then begin
      inc(statistics^.TotalSize, fi.Size);
      inc(statistics^.Count);
   end;
end;

procedure onStart();
begin
   oxedProjectStatistics.Reset();
end;

INITIALIZATION
   oxedProjectScanner.OnStart.Add(@onStart);
   oxedProjectScanner.OnFile.Add(@onFile);

END.
