//function TDVar.GetShortString(): shortstring;
begin
   if(variable <> nil) then
      case DataType of
         dtcSHORTSTRING:   result := {%H-}shortstring(variable^);
         dtcANSISTRING:    result := {%H-}ansistring(variable^);
         dtcWIDESTRING:    result {%H-}:= {%H-}widestring(variable^);
         else
            result := '';
      end
   else
      result := '';
end;
