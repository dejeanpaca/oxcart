{$MODE OBJFPC}{$H+}{$I-}
PROGRAM q3ParserTest;

{
   Started on:    10.09.2007.

   Tests the functionality of q3uParser and q3uShaders.
}

   USES uLog, uAppInfo, uStd,
      StringUtils, uTiming, q3uParser{$IFNDEF NO_SHADERS}, q3uShaders{$ENDIF};

CONST
   LogName: string = 'test';

   {$IFNDEF NO_SHADERS}{$INCLUDE ../shaderdefinitions.inc}{$ENDIF}

VAR
   data: q3pTStructure = (
      FileName: '';
      nLines: 0;
      Lines: nil
   );
   timer: TTimerData;
   FileName: string;
   stage: longint = 0;

procedure newShaderCallback(var s: string);
begin
   stage := 0;
   writeln('Shader: ', s);
end;

procedure newStageCallback();
begin
   writeln('   Stage: ', stage);
   inc(stage);
end;

procedure newFieldCallback(var f: q3TShaderField; var def: q3TShaderDefinition);
begin
   if(@def <> nil) then begin
      if(def.sSub <> nil) then
         writeln('      field: ', def.sName^, ' - ', def.sSub^)
      else
         writeln('      field: ', def.sName^);
   end;
end;

procedure customFieldCallback(var f: q3TShaderField; var def: q3TShaderDefinition; var line: q3pTLine);
begin
   writeln('      custom: ', def.sName^);
end;

VAR
   shadercallbacks: q3TShaderCallbacks =
   (newShader: @newShaderCallback;
    newStage: @newStageCallback;
    newField: @newFieldCallback;
    customField: @customFieldCallback;
    endShader: nil;
    );

BEGIN
   appcName := 'q3ptest';
   writeln('SuckASS (TM)(R)(C) q3Parser Test');

   log.InitStd(LogName, '', logcREWRITE);
   log.i('q3Parser Test');

   {$IFNDEF NO_SHADERS}
   q3ShaderLog := true;
   {$ENDIF}

   if(UpCase(paramstr(1)) = '-?') then begin
      writeln('Usage:');
      writeln('q3ParserTest [filename]');
      writeln();
      halt();
   end else begin
      FileName := paramstr(1);
      if(FileName = '') then begin
         FileName := 'test.shader';
         writeln('No file specified. Will use default: test.shader');
      end;
   end;

   {$PUSH}{$HINTS OFF}timStart(timer);{$POP} //Timer IS initialized

   q3pLoadFile(FileName, data);
   if(q3pError <> 0) then writeln('Failed loading file.');
   
   timUpdate(timer);

   log.i('Time parsing file: '+sf(timer.Elapsed)+' ms');

   q3pWriteFile('q3p.'+FileName, data);
   if(q3pError <> 0) then writeln('Failed writing file.');

   {try to parse the data as shader}
   {$IFNDEF NO_SHADERS}
   q3SelectShaderDefinitions(q3ShaderDefinitions);
   q3ParseShaderData(data, shadercallbacks);
   {$ENDIF}

   {dispose}
   q3pDisposeStructure(data);
END.
