var
   i: loopint;

begin
   Result := '';

   for i := 0 to n - 1 do begin
      if(i < n - 1) then
         result := result + sf(f[i]) + separator
      else
         result := result + sf(f[i]);
   end;
end;

