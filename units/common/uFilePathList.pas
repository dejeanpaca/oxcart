{
   uFilePathList
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uFilePathList;

{$INCLUDE oxutf8.inc}
{$INCLUDE oxtypesdefines.inc}

INTERFACE

   USES
      uStd, StringUtils;

TYPE
   TFilePathStringList = TSimpleStringList;

   { TFilePathStringListHelper }

   TFilePathStringListHelper = record helper(TSimpleStringListHelper) for TFilePathStringList
      function FindPath(const path: StdString): loopint;
      function RemovePath(const path: StdString): loopint;
      function AddUniquePath(const path: StdString): boolean;
   end;

IMPLEMENTATION

{ TFilePathStringListHelper }

function TFilePathStringListHelper.FindPath(const path: StdString): loopint;
var
   i: loopint;
   {$IFDEF WINDOWS}
   lpath: StdString;
   {$ENDIF}

begin
   {$IFDEF WINDOWS}
   lpath := LowerCase(path);
   {$ENDIF}

   for i := 0 to n - 1 do begin
      {$IFDEF WINDOWS}
      if(LowerCase(List[i]) = lpath) then
         exit(i);
      {$ELSE}
      if(List[i] = path) then
         exit(i);
      {$ENDIF}
   end;

   Result := -1;
end;

function TFilePathStringListHelper.RemovePath(const path: StdString): loopint;
var
   index: loopint;

begin
   index := FindPath(path);

   if(index > -1) then
      Remove(index);

   Result := index;
end;

function TFilePathStringListHelper.AddUniquePath(const path: StdString): boolean;
begin
   if(FindPath(path) = -1) then begin
      Add(path);
      Result := true;
   end else
      Result := false;
end;

END.
