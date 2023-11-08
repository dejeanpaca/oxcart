{
   oxuSceneFile, scene file support
   Copyright (C) 2018. Dejan Boras

   Started On:    04.03.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuSceneFile;

INTERFACE

   USES
      uStd, uFile, uFileHandlers,
      {oX}
      uOX, oxuRunRoutines, oxuFile, oxuScene;

TYPE
   { oxTSceneFileOptions }

   oxTSceneFileOptions = record
      Scene: oxTScene;
   end;

   { oxTSceneFile }

   oxTSceneFile = class(oxTFileRW)
      class procedure Init(out options: oxTSceneFileOptions); static;

      function Read(const fn: string): oxTScene;
      function Read(var f: TFile; const fn: string = '.scene'): oxTScene;

      function Write(const fn: string; scene: oxTScene): loopint;

      function OnWrite(var data: oxTFileRWData): loopint; override;
   end;

VAR
   oxfScene: oxTSceneFile;

IMPLEMENTATION

VAR
   readExt,
   writeExt: fhTExtension;
   readHandler,
   writeHandler: fhTHandler;

{ oxTSceneFile }

class procedure oxTSceneFile.Init(out options: oxTSceneFileOptions);
begin
   ZeroOut(options, SizeOf(options));
end;

function oxTSceneFile.Read(const fn: string): oxTScene;
var
   options: oxTSceneFileOptions;

begin
   Init(options);

   inherited Read(fn, @options);

   Result := options.Scene;
end;

function oxTSceneFile.Read(var f: TFile; const fn: string): oxTScene;
var
   options: oxTSceneFileOptions;

begin
   Init(options);

   inherited Read(f, fn, @options);

   Result := options.Scene;
end;

function oxTSceneFile.Write(const fn: string; scene: oxTScene): loopint;
var
   options: oxTSceneFileOptions;

begin
   options.Scene := scene;

   Result := inherited Write(fn, @options);
end;

function oxTSceneFile.OnWrite(var data: oxTFileRWData): loopint;
begin
   Result := inherited OnWrite(data);
end;

procedure readHandle({%H-}data: pointer);
begin
   {TODO: Implement reading scene file}
end;

procedure writeHandle({%H-}data: pointer);
begin
   {TODO: Implement writing scene file}
end;


procedure init();
begin
   oxfScene := oxTSceneFile.Create();

   oxfScene.Readers.RegisterHandler(readHandler, 'scene', @readHandle);
   oxfScene.Readers.RegisterExt(readExt, '.scene', @readHandler);

   oxfScene.Writers.RegisterHandler(writeHandler, 'scene', @writeHandle);
   oxfScene.Writers.RegisterExt(writeExt, '.scene', @writeHandler);
end;

procedure deinit();
begin
   FreeObject(oxfScene);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'scene_file', @init, @deinit);

END.
