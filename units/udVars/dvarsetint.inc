//procedure TDVar.Set(i: qword);
begin
   if(variable <> nil) then begin
      case DataType of
         dtcINT8:    shortint(variable^) := i;
         dtcINT16:   smallint(variable^) := i;
         dtcINT32:   longint(variable^) := i;
         dtcINT64:   int64(variable^) := i;
         dtcUINT8:   byte(variable^) := i;
         dtcUINT16:  word(variable^) := i;
         dtcUINT32:  dword(variable^) := i;
         dtcUINT64:  qword(variable^) := i;
         dtcSINGLE:  single(variable^) := i;
         dtcDOUBLE:  double(variable^) := i;
      end;

      Notify(DVAR_NOTIFICATION_MODIFIED);
   end;
end;
