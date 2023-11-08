   previousSeparator,
   i,
   code,
   currentCount: loopint;
   current: string;

begin
   if(st <> '') then begin
      i := 1;
      previousSeparator := 0;

      currentCount := 0;

      repeat
         if(st[i] = separator) then begin
            current := copy(st, previousSeparator + 1, i - 1 - previousSeparator);

            val(current, value, code);
            if(code <> 0) then
               exit(false);

            f[currentCount] := value;

            previousSeparator := i;
            inc(currentCount);
         end;

         inc(i);
      until (i > Length(st)) or (currentCount >= count);

      current := copy(st, previousSeparator + 1, Length(st) - (previousSeparator + 1));

      val(current, value, code);
      if(code <> 0) then
         exit(false);

      f[currentCount] := value;

      exit(currentCount = count - 1);
   end;

   Result := false;
end;
