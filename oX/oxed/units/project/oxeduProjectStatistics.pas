{
   oxeduProjectStatistics, project statistics
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduProjectStatistics;

INTERFACE

   USES
      uStd,
      {oxed}
      oxeduProjectManagement;

TYPE
   oxedPFileTypeStatistics = ^oxedTFileTypeStatistics;

   oxedTFileTypeStatistics = record
      Extension: string;
      {file count for this extension}
      Count,
      {total size of files for this extension}
      TotalSize: loopint;
   end;

   oxedTFileTypeStatisticsList = specialize TSimpleList<oxedTFileTypeStatistics>;

   { oxedTFileTypeStatisticsListHelper }

   oxedTFileTypeStatisticsListHelper = record helper for oxedTFileTypeStatisticsList
      {add new file type by extension}
      procedure Add(const ext: string);
      {find file type by extension}
      function FindByExtension(const ext: string): loopint;
   end;

   { oxedTProjectStatistics }

   oxedTProjectStatistics = record
      {total files in project}
      FileCount,
      {total size of files in project}
      TotalSize: loopint;
      {statistics per file type (by extension)}
      FileTypes: oxedTFileTypeStatisticsList;

      procedure Reset();
   end;

VAR
   oxedProjectStatistics: oxedTProjectStatistics;

IMPLEMENTATION

{ oxedTFileTypeStatisticsListHelper }

procedure oxedTFileTypeStatisticsListHelper.Add(const ext: string);
var
   f: oxedTFileTypeStatistics;

begin
   ZeroPtr(@f, SizeOf(f));

   f.Extension := ext;
   f.Count := 1;

   inherited Add(f);
end;

function oxedTFileTypeStatisticsListHelper.FindByExtension(const ext: string): loopint;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].Extension = ext) then begin
         exit(i);
      end;
   end;

   Result := -1;
end;

{ oxedTProjectStatistics }

procedure oxedTProjectStatistics.Reset();
begin
   FileCount := 0;
   TotalSize := 0;

   FileTypes.Dispose();
end;

procedure reset();
begin
   oxedProjectStatistics.Reset();
end;

INITIALIZATION
   oxedProjectManagement.OnOpen.Add(@reset);
   oxedProjectManagement.OnClosed.Add(@reset);

   oxedProjectStatistics.FileTypes.Initialize(oxedProjectStatistics.FileTypes, 128);

END.
