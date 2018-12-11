   previousSeparator,
   i,
   count,
   code: loopint;
   current: string;

begin
   f := nil;
   if(st <> '') then begin
      i := 1;
      previousSeparator := 0;
      count := 0;

      repeat
         if(st[i] = separator) then
            inc(count);

         inc(i);
      until i > Length(st);

      inc(count);

      SetLength(f, count);

      repeat
         count := 0;
         if(st[i] = separator) then begin
            current := copy(st, previousSeparator + 1, i - 1 - previousSeparator);

            val(current, value, code);
            if(code <> 0) then
               exit(false);

            f[count] := value;

            previousSeparator := i;
            inc(count);
         end;

         inc(i);
      until i > Length(st);

      current := copy(st, previousSeparator + 1, Length(st) - (previousSeparator + 1));

      val(current, value, code);
      if(code <> 0) then
         exit(false);

      f[count] := value;

      exit(true);
   end;

   Result := false;
end;

