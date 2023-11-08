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
      uOXED, oxeduAssets, oxeduVCS;

TYPE

   { oxedTGit }

   oxedTGit = class(oxedTVCS)
      procedure Start(); override;
   end;

VAR
   oxedGit: oxedTGit;

IMPLEMENTATION

procedure initialize();
begin
   oxedGit := oxedTGit.Create();
   oxedVCS.SetVCS(oxedGit);
end;

procedure deinitialize();
begin
   FreeObject(oxedGit);
end;

{ oxedTGit }

procedure oxedTGit.Start();
begin
   oxedAssets.AddFileIgnore('.gitignore');
   oxedAssets.AddFileIgnore('.gitmodule');
   oxedAssets.AddDirectoryIgnore('.git');
end;

INITIALIZATION
   oxed.Init.Add('git', @initialize, @deinitialize);

END.
