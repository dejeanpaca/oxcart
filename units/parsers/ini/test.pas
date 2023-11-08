{
   Started on:   10.09.2007.

   A test for the iniParser unit
}

{$APPTYPE CONSOLE}{$MODE OBJFPC}{$H+}{$I-}
PROGRAM test;

   USES uStd, uLog, uTiming, StringUtils, iniParser;

CONST
   LogName: string = 'test.log';

VAR
   data: iniTStructure;
   timer: dTTimer;
   FileName: string;
   s: iniPSection;
   l: iniPLine;

BEGIN
   writeln('SuckASS (TM)(R)(C) iniParser Test');

   logInitStd(LogName, '', logcREWRITE);
   log.i('iniParser Test');

   if(UpCase(paramstr(1)) = '-?') then begin
      writeln('Usage:');
      writeln('iniParserTest [filename]');
      writeln();
      halt();
   end else begin
      FileName := paramstr(1);
      if(FileName = '') then begin
         FileName := 'sample.ini';
         writeln('No file specified. Will use default: sample.ini');
      end;
   end;

   timStart(timer);

   iniLoadFile(FileName, data);
   if(iniError <> 0) then 
      writeln('Failed loading file.');

   timUpdate(timer);
   log.i('Time parsing file: ' + sf(timer.Elapsed) + ' ms');
   writeln('Time parsing file: ', timer.Elapsed, ' ms');

   writeln();
   s := iniFindSection('information', data);
   if(s <> nil) then begin
      writeln('Found information section.');
      l := iniFindLine('author', s^);
      if(l <> nil) then
         writeln('Author: ', l^.Items[1].data^);
   end;

   iniWriteFile('inip.' + FileName, data);
   if(iniError <> 0) then
      writeln('Failed writing file.');

   iniDisposeStructure(data);
END.
