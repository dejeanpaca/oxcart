//procedure TDVar.Set(const s: widestring);
begin
   if(variable <> nil) then begin
      case DataType of
         dtcSHORTSTRING:   shortstring(variable^) {%H-}:= s;
         dtcANSISTRING:    ansistring(variable^) := {%H-}s;
         dtcWIDESTRING:    widestring(variable^) := {%H-}s;
      end;

      {$INCLUDE dvarnotify.inc}
   end;
end;
