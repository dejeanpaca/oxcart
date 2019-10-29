{
   oxeduProjectPlatforms, handles platforms per project
   Copyright (C) 2019. Dejan Boras

   Started On:    29.10.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectPlatforms;

INTERFACE

   USES
      uStd,
      {oxed}
      oxeduPlatform, oxeduProjectManagement;

IMPLEMENTATION

procedure reset();
var
   i: loopint;

begin
   for i := 0 to oxedPlatforms.List.n - 1 do begin;
      oxedPlatforms.List.List[i].ProjectReset();
   end;
end;

INITIALIZATION
   oxedProjectManagement.OnNew.Add(@reset);
   oxedProjectManagement.OnClosed.Add(@reset);

END.
