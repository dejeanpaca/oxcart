{
   oxeduProjectStatistics, project statistics
   Copyright (C) 2019. Dejan Boras

   Started On:    29.10.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectStatistics;

INTERFACE

   USES
      uStd,
      {oxed}
      oxeduProjectManagement;

TYPE
   oxedTFileTypeStatistics = record
      Extension: string;
      FileCount: loopint;
   end;

   oxedTFileTypeStatisticsList = specialize TSimpleList<oxedTFileTypeStatistics>;

   { oxedTProjectStatistics }

   oxedTProjectStatistics = record
      FileCount,
      TotalSize: loopint;
      FileTypes: oxedTFileTypeStatisticsList;

      procedure Reset();
   end;

VAR
   oxedProjectStatistics: oxedTProjectStatistics;

IMPLEMENTATION

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

END.
