{
   oxeduiBuildOutput, build output
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduiBuildOutput;

INTERFACE

   USES
      sysutils,
      uBuildExec,
      oxeduSettings, oxeduConsole;

IMPLEMENTATION

procedure onOutputLine();
begin
   if(oxedSettings.ShowBuildOutput) then begin
      if (Pos('Error:',  BuildExec.Output.LastLine) > 0) or (Pos('Fatal:',  BuildExec.Output.LastLine) > 0) then
         oxedConsole.e(BuildExec.Output.LastLine)
      else
         oxedConsole.v(BuildExec.Output.LastLine);
   end;
end;

INITIALIZATION
   BuildExec.Output.OnLine.Add(@onOutputLine);

END.
