{procedure vmqFromMatrix(const m: TMatrix*; var qt: TQuaternion);}
var
   diagonal, scale: single;

begin
   {add diagonal values together}
   diagonal := m[0][0] + m[1][1] + m[2][2] +1{+ m3[3][3]};
   {the last element 3,3 should be 1, so we'll assume that}

   {there are two ways to calculate this
   1) if the diagonal is greater than 0 the quick calculation
   2) using the diagonal element with the greatest value}
   if(diagonal > 0.00000001) then begin {quick calculation}
      scale := sqrt(diagonal) * 2; {get the scale}

		{calculate the quaternion}
		{x}qt[0] := (m[2][1] - m[1][2]) / scale;
		{y}qt[1] := (m[0][2] - m[2][0]) / scale;
		{z}qt[2] := (m[1][0] - m[0][1]) / scale;
		{w}qt[3] := 0.25 * scale;
   end else begin { the harder way}
      if(m[0][0] > m[1][1]) and (m[0][0] > m[2][2]) then begin
			scale := sqrt(1.0 + m[0][0] - m[1][1] - m[2][2]) * 2.0; {get the scale}

			{calculate the quaternion}
			{x}qt[0] := 0.25 * scale;
         {y}qt[1] := (m[1][0] + m[0][1]) / scale;
			{z}qt[2] := (m[0][2] + m[2][0]) / scale;
			{w}qt[3] := (m[2][1] + m[1][2]) / scale;
      end else if(m[1][1] > m[2][2]) then begin
         scale := sqrt(1.0 + m[1][1] - m[0][0] - m[2][2]) * 2.0; {get the scale}

			{calculate the quaternion}
			{x}qt[0] := (m[1][0] + m[0][1]) / scale;
			{y}qt[1] := 0.25 * scale;
			{z}qt[2] := (m[2][1] + m[1][2]) / scale;
			{w}qt[3] := (m[0, 2] - m[2][0]) / scale;
      end else begin
         scale := sqrt(1.0 + m[2][2] - m[0][0] - m[1][1]) * 2.0; {get the scale}

			{calculate the quaternion}
			{x}qt[0] := (m[0][2] + m[2][0]) / scale;
			{y}qt[1] := (m[2][1] + m[1][2]) / scale;
			{z}qt[2] := 0.25 * scale;
			{w}qt[3] := (m[1][0] - m[0][1]) / scale;
		end;
   end;
end;
