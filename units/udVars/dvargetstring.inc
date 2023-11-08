//function TDVar.GetShortString(): shortstring;
begin
   if(variable <> nil) then
      case DataType of
         dtcSHORTSTRING:   result := {%H-}stringcast(shortstring(variable^));
         dtcANSISTRING:    result := {%H-}stringcast(ansistring(variable^));
         dtcWIDESTRING:    result {%H-}:= {%H-}stringcast(widestring(variable^));
         else
            result := '';
      end
   else
      result := '';
end;
