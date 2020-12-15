{
   oxeduGit, git support for OXED
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduGit;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED, oxeduAssets;

TYPE
   oxedTGit = record
 end;

IMPLEMENTATION

procedure initialize();
begin
   oxedAssets.AddFileIgnore('.gitignore');
   oxedAssets.AddFileIgnore('.gitmodule');
   oxedAssets.AddDirectoryIgnore('.git');
end;

INITIALIZATION
   oxed.Init.Add('git', @initialize);


END.
