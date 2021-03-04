{$INCLUDE oxheader.inc}
PROGRAM test;

USES uPropertySection;

VAR
   testps: TPropertySection;

procedure setString(code: longint; const prop: string);
begin
   if(code = 1) then
      writeln('yay: ', prop);
end;

BEGIN
   testps := dummyPropertySection;
   testps.Name := 'test';
   testps.setString := @setString;

   registerPropertySection(testps);
   setStringProperty('test', 1, 'great success');
END.

