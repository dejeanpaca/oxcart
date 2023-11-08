{
   oxeduiBuildOutput, build output
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduiBuildOutput;

INTERFACE

   USES
      sysutils, uStd, uLog,
      {build}
      uBuildExec,
      {ox}
      oxeduBuildLog, oxeduSettings, oxeduConsole;

TYPE
   oxedPBuildLogVerbositySetting = ^oxedTBuildLogVerbositySetting;

   oxedTBuildLogVerbositySetting = record
      MessageNo: loopint;
      Priority: loopint;
      Show: boolean;
   end;

   { oxedTBuildLogVerbositySettings }

   oxedTBuildLogVerbositySettings = record
      n: loopint;
      List: array[0..63] of oxedTBuildLogVerbositySetting;
      DefaultSetting: oxedTBuildLogVerbositySetting;

      function Find(messageNo: loopint): oxedPBuildLogVerbositySetting;
      function Add(messageNo: loopint; level: loopint = logcINFO): oxedPBuildLogVerbositySetting;

      procedure Initialize();
   end;

VAR
   oxedBuildLogVerbositySettings: oxedTBuildLogVerbositySettings;

IMPLEMENTATION

procedure onOutputLine();
var
   s, content: StdString;
   priority: loopint;
   p,
   secondP,
   code,
   messageNo: loopint;
   setting: oxedPBuildLogVerbositySetting;

procedure getMessageNo();
begin
   messageNo := 0;

   p := pos('(', content);
   secondP := pos(')', content);

   if (p <> 0) and (secondP <> 0) then begin
      s := copy(content, p + 1, secondP - p - 1);

      Val(s, messageNo, code);
   end;
end;

begin
   if(oxedSettings.ShowBuildOutput) then begin
      content := BuildExec.Output.LastLine;

      priority := logcINFO;

      p := Pos('Hint: ', content);

      if(p = 0) then begin
         p := Pos('Warning: ', content);

         if(p = 0) then begin
            p := Pos('Error: ', content);

            if(p = 0) then begin
               p := Pos('Fatal: ', content);

               if(p > 0) then
                  priority := logcFATAL;
            end else
               priority := logcERROR;
         end else
            priority := logcWARNING;
      end;

      if(p > 0) then
         content := Copy(content, p, Length(content) - p);

      getMessageNo();

      if(messageNo <> 0) then begin
         setting := oxedBuildLogVerbositySettings.Find(messageNo);

         if(setting = @oxedBuildLogVerbositySettings.DefaultSetting) then
            oxedBuildLog.s(priority, BuildExec.Output.LastLine)
         else if(setting^.Show) then
            oxedBuildLog.s(setting^.Priority, BuildExec.Output.LastLine);
      end else begin
         oxedBuildLog.s(priority, BuildExec.Output.LastLine);
      end;
   end;
end;

{ oxedTBuildLogVerbositySettings }

function oxedTBuildLogVerbositySettings.Find(messageNo: loopint): oxedPBuildLogVerbositySetting;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].MessageNo = messageNo) then
         exit(@List[i]);
   end;

   Result := @DefaultSetting;
end;

function oxedTBuildLogVerbositySettings.Add(messageNo: loopint; level: loopint): oxedPBuildLogVerbositySetting;
begin
   List[n] := DefaultSetting;
   List[n].MessageNo := messageNo;
   List[n].Priority := level;

   Result := @List[n];

   inc(n);
end;

procedure oxedTBuildLogVerbositySettings.Initialize();
begin
   DefaultSetting.Priority := logcINFO;
   DefaultSetting.Show := true;

   n := 0;

   Add(3104, logcVERBOSE);
end;

INITIALIZATION
   oxedBuildLogVerbositySettings.Initialize();

   BuildExec.Output.OnLine.Add(@onOutputLine);

END.
