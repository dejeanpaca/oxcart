{
   ustrBlob, string blob maker
   Copyright (C) 2020. Dejan Boras

   Packing multiple strings as one memory blob
}

{$INCLUDE oxheader.inc}
UNIT ustrBlob;

INTERFACE

   USES
      uStd;

TYPE

   { TShortStringBlob }

   TShortStringBlob = record
      Total,
      Offset: loopint;
      Blob: PByte;

      class procedure Initialize(out b: TShortStringBlob); static;
      procedure Analyze(const p: ShortString);
      procedure Allocate();
      procedure Insert(const p: ShortString);
      function GetRequiredSpace(const p: ShortString): loopint;

      procedure Dispose();
   end;

IMPLEMENTATION

{ TShortStringBlob }

class procedure TShortStringBlob.Initialize(out b: TShortStringBlob);
begin
   ZeroOut(b, SizeOf(b));
end;

procedure TShortStringBlob.Analyze(const p: ShortString);
begin
   Inc(Total, GetRequiredSpace(p));
end;

procedure TShortStringBlob.Allocate();
begin
   XGetMem(Blob, Total);
end;

procedure TShortStringBlob.Insert(const p: ShortString);
begin
   if(Blob <> nil) then begin
      PShortString(Blob + Offset)^ := p;
      inc(Offset, GetRequiredSpace(p));
   end;
end;

function TShortStringBlob.GetRequiredSpace(const p: ShortString): loopint;
begin
   Result := Length(p) + 1;
end;

procedure TShortStringBlob.Dispose();
begin
   Total := 0;
   XFreeMem(Blob);
end;

END.
