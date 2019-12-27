{
   oxeduiBuildOutput, build output
   Copyright (C) 2019. Dejan Boras

   Started On:    30.08.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduiBuildOutput;

INTERFACE

   USES
      sysutils,
      uBuild,
      oxeduSettings, oxeduMessages;

IMPLEMENTATION

procedure onOutputLine();
begin
   if(oxedSettings.ShowBuildOutput) then begin

      if (Pos('Error:',  build.Output.LastLine) > 0) or (Pos('Fatal:',  build.Output.LastLine) > 0) then
         oxedMessages.e(build.Output.LastLine)
      else
         oxedMessages.v(build.Output.LastLine);
   end;
end;

INITIALIZATION
   build.Output.OnLine.Add(@onOutputLine);

END.
