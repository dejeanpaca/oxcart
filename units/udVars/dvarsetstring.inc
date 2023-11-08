//procedure TDVar.Set(const s: widestring);
begin
   if(variable <> nil) then begin
      case DataType of
         dtcSHORTSTRING:   shortstring(variable^) := shortstring(s);
         dtcANSISTRING:    ansistring(variable^) := ansistring(s);
         dtcWIDESTRING:    widestring(variable^) := widestring(s);
      end;

      {$INCLUDE dvarnotify.inc}
   end;
end;
