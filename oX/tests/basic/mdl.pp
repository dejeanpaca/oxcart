{
   Copyright (C) 2012. Dejan Boras
}

{$INCLUDE oxdefines.inc}
PROGRAM mdl;

USES
   {$INCLUDE oxappuses.inc},
   uStd, uLog, ParamUtils,
   {model types}
   oxum3DS, oxumBlend,
   {ox}
   oxuWindowTypes, oxuWindows, oxuModelFile,
   oxuModel;

VAR
   modelFN: string = 'lambda.3ds';
   model: oxTModel;

procedure Render({%H-}wnd: oxTWindow);
begin
end;

procedure initialize();
begin
   oxfModel.LogExtended := true;

   log.v('Loading: ' + modelFN);
   model := oxfModel.Load(modelFN);
end;

procedure run();
begin
end;

procedure deinitialize();
begin
   FreeObject(model);
   oxWindows.OnRender.Add(@render);
end;

procedure init();
begin
   ox.OnInitialize.Add(@initialize);
   ox.OnDeinitialize.Add(@deinitialize);
   ox.OnRun.Add(@run);


   modelFN := ParamStr(1);
end;

BEGIN
   appInfo.setName('model');
   ox.AppProcs.iAdd('mdl', @init);

   if(ParamCount > 0) then
      modelFN := parameters.GetParameter(1);

   oxRun.Go();
END.
