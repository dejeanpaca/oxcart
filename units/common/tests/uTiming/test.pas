PROGRAM test;

USES SysUtils, Math, uTiming;

CONST
   wait: longword = 2000;

VAR
   s, e: longword;

BEGIN
   s := timCur();
   sleep(2000);
   e := timCur();
   writeln(wait, ' ~ ', e-s);
END.
