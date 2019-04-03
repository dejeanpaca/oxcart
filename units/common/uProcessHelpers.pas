{
   uTest
   Copyright (C) 2019. Dejan Boras

   Started On:    02.04.2019.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uProcessHelpers;

INTERFACE

   USES
      process, pipes,
      uStd;

TYPE
   { TProcessUtils }

   TProcessUtils = record
      {get a input pipe stream as a string}
      class function GetString(stream: TInputPipeStream; stripEndLine: boolean = true): string; static;
   end;

   { TProcessHelper }

   TProcessHelper = class helper for TProcess
      function GetOutputString(stripEndLine: boolean = true): string;
   end;



IMPLEMENTATION

{ TProcessHelper }

function TProcessHelper.GetOutputString(stripEndLine: boolean): string;
begin
   Result := TProcessUtils.GetString(Output, stripEndLine);
end;

class function TProcessUtils.GetString(stream: TInputPipeStream; stripEndLine: boolean): string;
var
   length: loopint;

begin
   Result := '';

   if(stream.NumBytesAvailable > 0) then begin
      length := stream.NumBytesAvailable;
      SetLength(Result, length);

      stream.ReadBuffer(Result[1], length);

      if(stripEndLine) then begin
         {check if we need to strip any characters off the end}
         if(Result[length] = #13) then
            length := length - 1
         else if(Result[length] = #10) then begin
            if(length > 1) then begin
               if(Result[length - 1] = #13) then
                  length := length - 2
               else
                  length := length - 1;
            end else
               length := length - 1;
         end;

         {correct to new length}
         if(length <> stream.NumBytesAvailable) then
            SetLength(Result, length);
      end;

      exit;
   end;
end;

END.
