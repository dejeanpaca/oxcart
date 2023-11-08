{
   zorder test
   Copyright (C) 2012. Dejan Boras

   Tests the functionality of the uiuZOrder unit.
}

{$INCLUDE oxdefines.inc}
PROGRAM zorder;

   USES oxuTypes, uiuZOrder;

CONST
   stra: string = 'a';
   strb: string = 'b';
   strc: string = 'c';

VAR
   z: uiTZOrder;

procedure writeZOrder();
var
   i: longint;

begin
   for i := 0 to (z.n-1) do begin
      write(z.entries[i].z);
      if(z.entries[i].p <> nil) then
         write('(', pstring(z.entries[i].p)^, ')');
      if(i < z.n-1) then write(',');
   end;
   writeln();
end;

BEGIN
   uizInit(z);

   uizAdd(z, @strb); //0
   uizAdd(z, nil, 0); //1
   uizAdd(z, nil, 1); //2
   writeZOrder();
   uizAdd(z, nil, 0); //3
   writeZOrder();
   uizAdd(z, nil, 15); //8
   writeZOrder();
   uizAdd(z, @stra, 9); //4
   uizAdd(z, @strb, 9); //5
   uizAdd(z, @strc, 9); //6
   writeZOrder();
   uizAdd(z, nil, 12); //7
   writeZOrder();

   uizMoveToTop(z, @stra);
   uizMoveToTop(z, 0);
   writeZOrder();

END.
