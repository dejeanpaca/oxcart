PROGRAM testinclude;

VAR
   {$INCLUDE test.inc}

BEGIN
   randomize();
   writeln(data[random(high(data))]);
END.
