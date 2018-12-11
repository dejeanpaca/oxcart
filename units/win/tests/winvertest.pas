PROGRAM Test;

   USES windowsver;

BEGIN
   writeln(winGetVersionString);
   writeln(winGetShortVersionString);
   if(winCheckVersion(5, 1) = false) then writeln('You''re not using Windows XP(bad).')
   else writeln('You are using Windows XP(good).');
END.

