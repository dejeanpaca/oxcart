{
   appuControllerTouchVirtual, virtual touchscreen controller
   Copyright (C) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuControllerVirtualTouch;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      {app}
      appuController, appuControllers;

TYPE
   { appTVTController }

   appTVTController = class(appTControllerDevice)
      constructor Create(); override;

      procedure Update(); override;
      procedure DeInitialize(); override;
   end;

   { appTVTControllerHandler }

   appTVTControllerHandler = object(appTControllerHandler)
      procedure Scan(); virtual;
      procedure Rescan(); virtual;

      function GetName(): StdString; virtual;
   end;

VAR
   appVTControllerHandler: appTVTControllerHandler;

IMPLEMENTATION


{ appTVTController }

constructor appTVTController.Create();
begin
   inherited Create();

   Handler := @appVTControllerHandler;
end;

procedure appTVTController.Update();
begin
end;

procedure appTVTController.DeInitialize();
begin
   inherited;
end;

{ appTVTControllerHandler }

function appTVTControllerHandler.GetName(): StdString;
begin
   Result := 'VT';
end;

INITIALIZATION
   appVTControllerHandler.Create();
   appControllers.AddHandler(appVTControllerHandler);

END.
