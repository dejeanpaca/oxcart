//function TDVar.GetLongint(): longint;
begin
   if(variable <> nil) then
      case DataType of
         dtcINT8:       result := shortint(variable^);
         dtcINT16:      result := smallint(variable^);
         dtcINT32:      result := longint(variable^);
         dtcINT64:      result := int64(variable^);
         dtcUINT8:      result := byte(variable^);
         dtcUINT16:     result := word(variable^);
         dtcUINT32:     result := dword(variable^);
         dtcUINT64:     result := qword(variable^);
         dtcSINGLE:     result := round(single(variable^));
         dtcDOUBLE:     result := round(double(variable^));
         dtcEXTENDED:   result := round(extended(variable^));
         else
            result := 0;
      end
   else
      result := 0;
end;
