{$INCLUDE oxheader.inc}
PROGRAM buildypak;

   USES sysutils, process;

VAR
   p: TProcess;
   target: string = '';

BEGIN
   target := ParamStr(1);
   if(target = '') then
      target := 'default';

   chdir('data');
   if(IOResult = 0) then begin
      writeln('Building for target: ', target);
      p := TProcess.Create(nil);

      p.Executable := 'ypak';

      if(target <> '') and (target <> 'default') then begin
         p.Parameters.Add('-target');
         p.Parameters.Add(target);
      end;

      try
         p.Execute();

         repeat
         until not p.Running;
      except
         writeln('Failed executing ypak tool');
      end;

      p.Free();
   end else
      writeln('No data found');
END.
