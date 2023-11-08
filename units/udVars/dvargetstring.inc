//function TDVar.GetShortString(): string;
begin
   if(variable <> nil) then
      case DataType of
         dtcSHORTSTRING:   Result := {%H-}stringcast(shortstring(variable^));
         dtcANSISTRING:    Result := {%H-}stringcast(ansistring(variable^));
         dtcWIDESTRING:    Result {%H-}:= {%H-}stringcast(widestring(variable^));
         else
            Result := '';
      end
   else
      Result := '';
end;
