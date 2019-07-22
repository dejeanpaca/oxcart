//procedure TDVar.Assign(i: double);
begin
   if(variable <> nil) then begin
      case DataType of
         dtcINT8:    shortint(variable^) := round(i);
         dtcINT16:   smallint(variable^) := round(i);
         dtcINT32:   longint(variable^) := round(i);
         dtcINT64:   int64(variable^) := round(i);
         dtcUINT8:   byte(variable^) := round(i);
         dtcUINT16:  word(variable^) := round(i);
         dtcUINT32:  dword(variable^) := round(i);
         dtcUINT64:  qword(variable^) := round(i);
         dtcSINGLE:  single(variable^) := i;
         dtcDOUBLE:  double(variable^) := i;
      end;

      Notify(DVAR_NOTIFICATION_MODIFIED);
   end;
end;
