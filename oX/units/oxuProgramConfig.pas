{
   oxuProgramConfig, ox program config
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuProgramConfig;

INTERFACE

   USES
      uStd, oxuDvarFile,
      uOX;

VAR
   oxProgramDvarFile: oxTDvarFile;

IMPLEMENTATION

procedure init();
begin
   {save only if we have any settings}
   if(ox.ProgramDvar.vs <> nil) then
      oxProgramDvarFile.Load();
end;

procedure deinit();
begin
   {save only if we have any settings}
   if(ox.ProgramDvar.vs <> nil) then
      oxProgramDvarFile.Save();
end;

INITIALIZATION
   ox.Init.Add('program_config', @init, @deinit);

   oxProgramDvarFile.Create(ox.ProgramDvar);
   oxProgramDvarFile.FileName := 'program';

END.
