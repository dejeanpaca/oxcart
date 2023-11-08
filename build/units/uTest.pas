{
   uTest
   Copyright (C) 2015. Dejan Boras

   Started On:    15.02.2015.
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT uTest;

INTERFACE

   USES uStd, uLog, uFileUtils, ParamUtils, StringUtils, uKeyValueFile;

CONST
   TEST_RESULTS_FILENAME = 'testresults.txt';

TYPE
   {Describes a unit test, usually used by a system that processes test results.
   Property meanings are equivalent to those in TUnitTest}

   { TUnitTestDescriptor }

   PUnitTestDescriptor = ^TUnitTestDescriptor;
   TUnitTestDescriptor = record
      {name of the test}
      Name,
      {description why a test failed, or any remarks}
      Description: string;
      {did the test pass}
      Success: boolean;

      function SuccessString(): string;
   end;

   TUnitTestDescriptors = specialize TPreallocatedArrayList<TUnitTestDescriptor>;

   {results of unit tests}

   { TUnitTestResults }
   PUnitTestResults = ^TUnitTestResults;

   TUnitTestResults = record
      {tests group name}
      Group: string;
      {have all tests passed}
      Success: boolean;

      List: TUnitTestDescriptors;

      procedure Allocate(count: longint);
      procedure Add(const testName: string; const description: string = '');

      procedure RemoveAll();
   end;

   { TUnitTest }

   TUnitTest = class
      public
         {any callback used if the test is of a simple nature}
         Callback: TProcedure;
         {should any further testing stop on failing this test}
         StopOnFail: boolean;

         Descriptor: TUnitTestDescriptor;

      {prepare/build the test}
      procedure Start(); virtual;
      {run the tests}
      procedure Run(); virtual;
      {perform test operations (test run or output)}
      procedure Perform();
      {stop/destroy the test}
      procedure Stop(); virtual;

      {simple assert, will fail the test if expression is untrue}
      function Assert(expression: boolean; const failureReason: string = ''): boolean;

      constructor Create();
   end;

   { TUnitTestResultsPool }
   PUnitTestResultsPool = ^TUnitTestResultsPool;

   TUnitTestResultsPool = record
      List: array of TUnitTestResultsPool;
      n: longint;

      Results: TUnitTestResults;

      ErrorDescription: string;
      Enabled: boolean;

      {add results into the pool}
      procedure SetResultsFrom(var r: TUnitTestResults);
      {add a new subgroup}
      function Add(const g: string): PUnitTestResultsPool;
      {add a new subgroup to the top-level}
      function AddTop(const g: string): PUnitTestResultsPool;
      {find a subgroup, can have multiple levels}
      function Find(const g: string): PUnitTestResultsPool;
      {find a subgroup, but only in the top level}
      function FindTop(const g: string): PUnitTestResultsPool;

      {get the total group count for this pool and its children}
      function GroupCount(): longint;
      {get the total test count for this pool and children}
      function TestCount(): longint;
      {get the total passed test count for this pool and children}
      function PassCount(): longint;
      {get the total failed test count for this pool and children}
      function FailCount(): longint;

      {writes out the results}
      procedure Write(recursive: boolean);

      {remove all test groups}
      procedure RemoveAll();
   end;

   { TUnitTests }

   TUnitTests = record
      {test group name}
      Group: string;
      {currently running test}
      Current: TUnitTest;

      {don't run any test, only write out the tests list}
      WriteList,
      {don't run any test for our own test suite}
      SelfTest,
      {do not rebuild tests, only run those that are already built}
      NoBuild,
      {run in information mode}
      InfoMode: boolean;

      ErrorDescription: string;

      {list of tests}
      Tests: record
         List: array of TUnitTest;
         n: longint;
      end;

      Pool: TUnitTestResultsPool;

      {initializes testing}
      procedure Initialize(const s: string);

      {add a test instance to the list}
      function Add(const testName: string; const description: string; test: TUnitTest): TUnitTest;
      function Add(const testName: string; test: TUnitTest): TUnitTest;
      {add a simple test to the list}
      function Add(const testName: string; const description: string; run: TProcedure): TUnitTest;
      function Add(const testName: string; run: TProcedure): TUnitTest;
      {run all tests}
      procedure Run();

      {current test asert}
      function Assert(expression: boolean; const failureReason: string = ''): boolean;

      {writes test results to a file}
      function WriteResults(): boolean;

      {load results from a file into a results object}
      function LoadResults(var results: TUnitTestResults): boolean;

      {destroy results}
      procedure Destroy();
   end;

VAR
   UnitTests: TUnitTests;

IMPLEMENTATION

{ TUnitTestDescriptor }

function TUnitTestDescriptor.SuccessString(): string;
begin
   if(Success) then
      Result := 'pass'
   else
      Result := 'fail';
end;

{ TUnitTestResultsPool }

procedure TUnitTestResultsPool.SetResultsFrom(var r: TUnitTestResults);
var
   group: PUnitTestResultsPool;
   i: longint;

begin
   group := Find(r.Group);

   if(group <> nil) then begin
      {set results}
      if(r.List.n > 0) then begin
         for i := 0 to (r.List.n - 1) do
            if(i < group^.Results.List.n) then
               group^.Results.List.List[i].Success := r.List.List[i].Success;
      end;
   end;
end;

function TUnitTestResultsPool.Add(const g: string): PUnitTestResultsPool;
var
   l: longint = 0;
   groups: TAnsiStringArray;
   current,
   next: PUnitTestResultsPool;

begin
   groups := strExplode(g, '.');

   if(length(groups) = 0) then
      exit(nil);

   next := @self;
   repeat
      current := next;

      next := current^.FindTop(groups[l]);
      if(next = nil) then
         next := current^.AddTop(groups[l]);

      inc(l);
   until (next = nil) or (l = length(groups));

   Result := next;
end;

function TUnitTestResultsPool.AddTop(const g: string): PUnitTestResultsPool;
begin
   Result := FindTop(g);
   if(Result = nil) then begin
      inc(n);
      SetLength(List, n);
      Result := @List[n - 1];

      ZeroOut(Result^, SizeOf(Result^));
      Result^.Results.List.Initialize(Result^.Results.List);

      Result^.Enabled := true;
      Result^.Results.Group := g;
   end;
end;

function TUnitTestResultsPool.Find(const g: string): PUnitTestResultsPool;
var
   l: longint = 0;
   groups: TAnsiStringArray;
   current, next: PUnitTestResultsPool;

begin
   groups := strExplode(g, '.');

   if(length(groups) = 0) then
      exit(nil);

   next := @self;
   repeat
      current := next;

      next := current^.FindTop(groups[l]);
      inc(l);
   until (next = nil) or (l = length(groups));

   Result := next;
end;

function TUnitTestResultsPool.FindTop(const g: string): PUnitTestResultsPool;
var
   i: longint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].Results.Group = g) then
         exit(@List[i]);
   end;

   Result := nil;
end;

function TUnitTestResultsPool.GroupCount(): longint;
var
   i: longint;

begin
   if(n = 0) and (Results.group <> '') then
      Result := 1
   else
      Result := 0;

   if(n > 0) then
      for i := 0 to (n - 1) do
         inc(Result, List[i].GroupCount());
end;

function TUnitTestResultsPool.TestCount(): longint;
var
   i: longint;

begin
   Result := Results.List.n;

   if(n > 0) then
      for i := 0 to (n - 1) do
         inc(Result, List[i].TestCount());
end;

function TUnitTestResultsPool.PassCount(): longint;
var
   i: longint;

begin
   Result := 0;

   if(Results.List.n > 0) then begin
      for i := 0 to (Results.List.n - 1) do
         if(Results.List.List[i].success) then
            inc(Result);
   end;

   if(n > 0) then
      for i := 0 to (n - 1) do
         inc(Result, list[i].PassCount());
end;

function TUnitTestResultsPool.FailCount(): longint;
var
   i: longint;

begin
   Result := 0;

   if(Results.List.n > 0) then begin
      for i := 0 to (Results.List.n - 1) do
         if(not Results.List.List[i].success) then
            inc(Result);
   end;

   if(n > 0) then
      for i := 0 to (n - 1) do
         inc(Result, List[i].FailCount());
end;

procedure writeGroup(const parent: string; const pool: TUnitTestResultsPool; recursive: boolean);
var
   i: longint;
   p: PUnitTestDescriptor;
   what: string;

begin
   if(pool.Results.List.n > 0) then begin
      log.i();

      what := 'group: ' + parent + pool.Results.group;

      if((pool.ErrorDescription = '') and (pool.PassCount() = pool.TestCount())) or (UnitTests.InfoMode) then
         log.k(what)
      else
         log.e(what);

      if(pool.ErrorDescription <> '') then begin
         log.e('   ' + pool.ErrorDescription);
      end else begin
         for i := 0 to (pool.Results.List.n - 1) do begin
            p := @pool.Results.List.List[i];

            if(not UnitTests.InfoMode) then begin
               what := p^.name + ': ' + p^.SuccessString();

               if(p^.Success) then
                  log.k(what)
               else
                  log.e(what);
            end else
               log.i(p^.name);

            if(p^.Description <> '') then
               log.v('   ' + p^.Description);
         end;
      end;
   end;

   if(recursive) and (pool.n > 0) then begin
      for i := 0 to (pool.n - 1) do begin
         if(pool.Results.Group <> '') then
            writeGroup(parent + pool.Results.Group + '.', pool.List[i], recursive)
         else
            writeGroup('', pool.List[i], recursive);
      end;
   end;
end;

procedure TUnitTestResultsPool.Write(recursive: boolean);
begin
   writeGroup('', self, recursive);
end;

procedure TUnitTestResultsPool.RemoveAll();
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      List[i].RemoveAll();
   end;

   SetLength(List, 0);
   n := 0;

   Results.RemoveAll();
end;

{ TUnitTestResults }

procedure TUnitTestResults.Allocate(count: longint);
begin
   List.Allocate(count);
end;

procedure TUnitTestResults.Add(const testName: string; const description: string = '');
var
   t: TUnitTestDescriptor;

begin
   t.Name := testName;
   t.Description := description;
   t.Success := false;

   List.Add(t);
end;

procedure TUnitTestResults.RemoveAll();
begin
   List.Dispose();
end;

{ TUnitTests }

procedure TUnitTests.Initialize(const s: string);
begin
   group := s;

   Pool.Results.List.Initialize(Pool.Results.List);

   if(parameters.FindFlagLowercase('-writelist')) then
      WriteList := true;

   if(parameters.FindFlagLowercase('-testinfo')) then
      InfoMode := true;
end;

function TUnitTests.Add(const testName: string; const description: string; test: TUnitTest): TUnitTest;
begin
   inc(tests.n);
   SetLength(Tests.List, Tests.n);

   if(test = nil) then
      test := TUnitTest.Create();

   test.Descriptor.name := testName;
   test.Descriptor.description := description;

   tests.List[Tests.n - 1] := test;

   Result := test;
end;

function TUnitTests.Add(const testName: string; test: TUnitTest): TUnitTest;
begin
   Result := Add(testName, '', test);
end;

function TUnitTests.Add(const testName: string; const description: string; run: TProcedure): TUnitTest;
begin
   Result := Add(testName, description, TUnitTest(nil));

   Result.Callback := run;
end;

function TUnitTests.Add(const testName: string; run: TProcedure): TUnitTest;
begin
   Result := Add(testName, '', run);
end;

procedure TUnitTests.Run();
var
   i: longint;

begin
   current := nil;
   ErrorDescription := '';

   if(InfoMode) then begin
      WriteResults();
      exit();
   end;

   if(Tests.n <= 0) then begin
      log.i('No tests to run.');
      exit();
   end;

   log.i('Running group: ' + group);

   for i := 0 to (tests.n - 1) do begin
      ErrorDescription := '';
      current := Tests.List[i];

      log.i('Running: ' + current.Descriptor.Name);

      Current.Start();
      if(ErrorDescription <> '') then
         log.e(ErrorDescription);

      current.Perform();
      if(ErrorDescription <> '') then
         log.e(ErrorDescription);

      current.Stop();
      if(ErrorDescription <> '') then
         log.e(ErrorDescription);

      if(current.Descriptor.Success) then
         log.k('Success: ' + current.Descriptor.Name)
      else
         log.e('Failed: ' + current.Descriptor.Name);
   end;

   ErrorDescription := '';
   if(not WriteResults()) then begin
      log.e(ErrorDescription);
      halt(1);
   end;

   current := nil;

   log.i('Done');
end;

function TUnitTests.Assert(expression: boolean; const failureReason: string): boolean;
begin
   if(current <> nil) then
      current.Assert(expression, failureReason);

   Result := expression;
end;

function TUnitTests.WriteResults(): boolean;
var
   i: longint;
   fn: string;

   f: TKeyValueFile;

begin
   Result := false;
   fn :=  TEST_RESULTS_FILENAME;

   KeyValueFiles.Init(f);

   f.Add('@count', sf(Tests.n));
   f.Add('@group', group);

   for i := 0 to (Tests.n - 1) do
      f.Add(tests.List[i].Descriptor.Name, Tests.List[i].Descriptor.SuccessString());

   f.Write(fn);
   if(f.ioE <> 0) then
      ErrorDescription := 'could not write to the test results file, error: ' + sf(f.ioE)
   else begin
      Result := true;
      log.i('Written results to: ' + fn);
   end;

   f.Dispose();
end;

function TUnitTests.LoadResults(var results: TUnitTestResults): boolean;
var
   key,
   value: string;

   {set to true when all metadata was loaded}
   ok: boolean;

   i,
   index,
   count,
   code: longint;
   f: TKeyValueFile;

begin
   Result := false;

   KeyValueFiles.Init(f);

   f.Load(TEST_RESULTS_FILENAME);
   if(f.ioE <> 0) then begin
      ErrorDescription := 'could not load test results file, error: ' + sf(f.ioE);
      exit();
   end;

   index := 0;
   ok := false;

   for i := 0 to (f.List.n - 1) do begin
      key := f.List.List[i].key;
      value := f.List.List[i].value;

      if(ok) then begin
         if(index < Results.List.n) then begin
            Results.List.List[index].Name := key;
            Results.List.List[index].Success := lowercase(value) = 'pass';
         end;

         inc(index);
      end else begin
         if(key = '@count') then begin
            {get test count}
            Val(value, count, code);

            if(code <> 0) then begin
               ErrorDescription := 'Results file has an invalid test count field';
               break;
            end;

            Results.Allocate(count);
         end else if(key = '@group') then
            {get test group}
            Results.Group := value;

         if(Results.List.n > 0) and (Results.Group <> '') then
            ok := true;
      end;
   end;

   f.Dispose();

   if(index <> Results.List.n) then
      ErrorDescription := 'Results file has mismatched test count (' + sf(index) + ') and test reports ' + sf(Results.List.n);

   if(ErrorDescription <> '') then
      Result := true;
end;

procedure TUnitTests.Destroy();
begin
   Pool.RemoveAll();

   SetLength(Tests.List, 0);
   Tests.n := 0;
end;

{ TUnitTest }

procedure TUnitTest.Start();
begin

end;

procedure TUnitTest.Run();
begin
end;

procedure TUnitTest.Perform();
begin
   descriptor.success := true;

   if(callback <> nil) then
      callback();

   Run();
end;

procedure TUnitTest.Stop();
begin

end;

function TUnitTest.Assert(expression: boolean; const failureReason: string): boolean;
begin
   {since success is assumed from the start, we only fail when the assert fails,
   so any subsequent assert will not pass the test}
   if(not expression) then begin
      if(failureReason <> '') then
         log.e(descriptor.Name + ' failed because: ' + failureReason);

      descriptor.Success := false;
   end;

   Result := expression;
end;

constructor TUnitTest.Create();
begin
   {we start with the assumption the test is successful, so it succeeds if it does nothing}
   descriptor.Success := true;
end;

INITIALIZATION
   UnitTests.SelfTest := false;

END.
