{
   transform

   Started On:   12.08.2019.
}

{$INCLUDE oxdefines.inc}
PROGRAM transform;

   USES
      vmVector,
      oxuTransform;

VAR
   t: oxTTransform;

BEGIN
   t := oxTTransform.Create();

   { all methods should return the same result }

   { BASIC }

   t.Rotate(99, 66, 33);
   t.GetEuler();

   writeln(t.vRotation.ToString(2));

   { AXIS ROTATION }

   t.Identity();

   t.GetRotateMatrix(66, 0, 1, 0, t.Matrix);
   t.RotationMatrix := t.Matrix;

   t.GetRotateMatrix(33, 0, 0, 1, t.Matrix);
   t.RotationMatrix := t.RotationMatrix * t.Matrix;

   t.GetRotateMatrix(99, 1, 0, 0, t.Matrix);
   t.RotationMatrix := t.RotationMatrix * t.Matrix;

   t.GetEuler();

   writeln(t.vRotation.ToString(2));

   { SHORT AXIS METHODS }

   t.Identity();

   t.GetRotateMatrixY(66, t.Matrix);
   t.RotationMatrix := t.Matrix;

   t.GetRotateMatrixZ(33, t.Matrix);
   t.RotationMatrix := t.RotationMatrix * t.Matrix;

   t.GetRotateMatrixX(99, t.Matrix);
   t.RotationMatrix := t.RotationMatrix * t.Matrix;

   t.GetEuler();

   writeln(t.vRotation.ToString(2));
END.
