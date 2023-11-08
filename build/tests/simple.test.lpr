PROGRAM simple_test;

   USES uTest;

TYPE

   { TRandomTest }

   TRandomTest = class(TUnitTest)
      procedure Run(); override;
   end;

procedure simple();
begin
   UnitTests.Assert(true = false);
end;

procedure simple_next();
begin
   UnitTests.Assert(true = true);
end;

procedure TRandomTest.Run();
begin
   Assert(random(2) = 0);
end;

BEGIN
   randomize();
   UnitTests.Initialize('build.tests.simple');

   UnitTests.Add('simple 1', 'Simple test, intended to always fail', @simple);
   UnitTests.Add('simple 2', 'simple test, intended to always pass', @simple_next);
   UnitTests.Add('random', 'test which should randomly fail 50% of the time', TUnitTest(TRandomTest.Create()));

   UnitTests.Run();
END.
