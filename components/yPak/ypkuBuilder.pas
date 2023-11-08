{
   yPakU, yPak tool base unit
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ypkuBuilder;

INTERFACE

   USES
      uStd, uFile,
      {ypk}
      yPakU, uyPakFile;


TYPE
   ypkTBuilderFile = record
      source,
      destination: StdString;
   end;

   ypkTBuilderFiles = specialize TSimpleList<ypkTBuilderFile>;

   { ypkTBuilder }

   ypkTBuilder = record
      fn: string;

      Files: ypkTBuilderFiles;

      procedure Reset();
      procedure Build();
      procedure AddFile(const source, destination: StdString);
   end;

IMPLEMENTATION

{ ypkTBuilder }

procedure ypkTBuilder.Reset();
begin
   Files.Dispose();
end;

procedure ypkTBuilder.Build();
begin
   {TODO: Implement actual building}
end;

procedure ypkTBuilder.AddFile(const source, destination: StdString);
var
   f: ypkTBuilderFile;

begin
   f.source := source;
   f.destination := destination;

   Files.Add(f);
end;

INITIALIZATION
END.
