{procedure vmqFromMatrixAlt(const m: TMatrix*; var qt: TQuaternion);}
begin
   qt[3] := sqrt(vmMax(0, 1 + m[0][0] + m[1][1] + m[2][2])) / 2;
   qt[0] := sqrt(vmMax(0, 1 + m[0][0] - m[1][1] - m[2][2])) / 2;
   qt[1] := sqrt(vmMax(0, 1 - m[0][0] + m[1][1] - m[2][2])) / 2;
   qt[2] := sqrt(vmMax(0, 1 - m[0][0] - m[1][1] + m[2][2])) / 2;

   qt[0] := vmCopySign(qt[0], m[2][1] - m[1][2]);
   qt[1] := vmCopySign(qt[1], m[0][2] - m[2][0]);
   qt[2] := vmCopySign(qt[2], m[1][0] - m[0][1]);
end;
