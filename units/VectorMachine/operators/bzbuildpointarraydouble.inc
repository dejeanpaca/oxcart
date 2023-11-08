var
   i: longint;
   factor: single;

begin
   factor := 1.0 / n;
   if(n > 0) then begin
      for i := 0 to (n - 1) do
         points[i] := vmbzInterpolate(i * factor, bz);
   end;
end;
