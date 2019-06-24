{procedure TDVar.Set(const s: stringtypeofsomesort);}
begin
   if(variable <> nil) then begin
      case DataType of
         dtcSHORTSTRING:   shortstring(variable^) := shortstring(s);
         dtcANSISTRING:    ansistring(variable^) := ansistring(s);
         dtcWIDESTRING:    widestring(variable^) := widestring(s);
         dtcUTF8STRING:    UTF8String(variable^) := UTF8String(s);
      end;

      {$INCLUDE dvarnotify.inc}
   end;
end;

