PROGRAM Test;

   USES uBitSet;

CONST
   cElements = 8192;

var
   bs: TBitSet;

BEGIN
   bs := bsMake(cElements);
   writeln('Elements: ', cElements);
   writeln('Size: ', bs.Size);

   bsClearAll(bs);

   bs.Bits[0] := $FFFFFFFF;
   bsSet(bs, 2044);
   writeln(bsOn(bs, 0) <> 0, '.', bsOn(bs, 1) <> 0, '.',
        bsOn(bs, 2) <> 0, '.', bsOn(bs, 3) <> 0, '.',
        bsOn(bs, 4) <> 0, '.', bsOn(bs, 2044) <> 0, '.');

END.
