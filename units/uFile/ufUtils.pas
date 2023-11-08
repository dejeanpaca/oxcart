{
   ufUtils, TFile helpers and utilities
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ufUtils;

INTERFACE

   USES
      sysutils, uStd,
      uFileUtils, uFile, uFiles;

CONST
     fCOMPARE_AND_REPLACE_NO_SOURCE = -1;
     fCOMPARE_AND_REPLACE_NO_CHANGE = 0;
     fCOMPARE_AND_REPLACE_UPDATE = 1;
     fCOMPARE_AND_REPLACE_CREATE = 2;

TYPE
   { fTUtils }

   fTUtils = record
      ReplaceResult: loopint;

      {Compare two files.
       Returns 0 if completely matching. Otherwise position of first mismatching byte.
       Returns negative number on error (error code)}
      function Compare(var f1, f2: TFile): fileint;
      {Compares two files. It'll replace the target with the source one if they mismatch.
      This will remove the source file.
      This is helpful if you wish to avoid unnecessary target file changes.}
      function CompareAndReplace(const source, target: StdString): boolean;
   end;

VAR
   fUtils: fTUtils;

IMPLEMENTATION


{ fTUtils }

function fTUtils.Compare(var f1, f2: TFile): fileint;
var
   maxRead,
   readCount1,
   readCount2,
   mismatchPosition: fileint;

   buf1,
   buf2: array[0..16383] of byte;

begin
   f1.SeekStart();
   f2.SeekStart();

   maxRead := 16384;
   mismatchPosition := 0;

   if(f1.bSize <> 0) and (f1.bSize < maxRead) then
      maxRead := f1.bSize;

   maxRead := 2048;

   repeat
      readCount1 := f1.Read(buf1, maxRead);
      if(f1.Error <> 0) then
         break;

      readCount2 := f2.Read(buf2, maxRead);
      if(f2.Error <> 0) then
         break;

      if(readCount1 <> readCount2) then begin
         mismatchPosition := f1.fPosition + (readCount2 - readCount1);
         break;
      end;

      mismatchPosition := abs(CompareMemRange(@buf1[0], @buf2[0], readCount1));
      if(mismatchPosition <> 0) then begin
         mismatchPosition := f1.fPosition - readCount1 + mismatchPosition;
         break;
      end;
   until f1.EOF();

   if(f1.Error <> 0) or (f2.Error <> 0) then
      exit(-f1.Error);

   Result := mismatchPosition;
end;

function fTUtils.CompareAndReplace(const source, target: StdString): boolean;
var
   f1, f2: TFile;
   mismatch: fileint;

   buf1,
   buf2: array[0..16383] of byte;

begin
   Result := false;
   ReplaceResult := fCOMPARE_AND_REPLACE_NO_CHANGE;

   {we cannot find the source file}
   if(FileUtils.Exists(source) < 0) then begin
      ReplaceResult := fCOMPARE_AND_REPLACE_NO_SOURCE;
      exit(false);
   end;

   {update target file if it exists}
   if(FileUtils.Exists(target) >= 0) then begin
      fFile.Init(f1);
      fFile.Init(f2);

      f1.Open(source);
      f2.Open(target);

      {speed things up}
      f1.ExternalBuffer(@buf1[0], Length(buf1));
      f2.ExternalBuffer(@buf2[0], Length(buf2));

      mismatch := Compare(f1, f2);

      f1.Close();
      f2.Close();

      {no change, we do nothing}
      if(mismatch = 0) then begin
         FileUtils.Erase(source);
         ReplaceResult := fCOMPARE_AND_REPLACE_NO_CHANGE;
      end else begin
         {replace target file with source file}
         FileUtils.Erase(target);
         RenameFile(source, target);
         ReplaceResult := fCOMPARE_AND_REPLACE_UPDATE;

         Result := true;
      end;
   end else begin
      {no target file, create from source file}
      RenameFile(source, target);
      ReplaceResult := fCOMPARE_AND_REPLACE_CREATE;

      Result := true;
   end;
end;

END.
