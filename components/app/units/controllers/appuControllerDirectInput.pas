{
   appuControllerDirectInput, DirectInput controller handling
   Copyright (C) 2019. Dejan Boras

   Started On:    19.09.2019.
}

{$INCLUDE oxheader.inc}
UNIT appuControllerDirectInput;

INTERFACE

   USES
      uStd, uLog,
      appuController;

TYPE

   { appTDirectInputControllerHandler }

   appTDirectInputControllerHandler = object(appTControllerHandler)
      procedure Initialize(); virtual;
      procedure Reset(); virtual;
      procedure Run(); virtual;

      private
         procedure Add(const {%H-}fn: string);
   end;

   { appTDirectInputControllerDevice }

   appTDirectInputControllerDevice = class(appTControllerDevice)
      FileName: string;

      procedure Run(); override;
      procedure DeInitialize(); override;
   end;

IMPLEMENTATION

VAR
   appDirectInputControllerHandler: appTDirectInputControllerHandler;

{ appTDirectInputControllerDevice }

procedure appTDirectInputControllerDevice.Run();
begin
end;

procedure appTDirectInputControllerDevice.DeInitialize();
begin
   inherited;
end;

{ appTDirectInputControllerHandler }

procedure appTDirectInputControllerHandler.Initialize();
begin
   Reset();
end;

procedure appTDirectInputControllerHandler.Reset();
begin
   inherited;
end;

procedure appTDirectInputControllerHandler.Run();
begin
   inherited Run();
end;

procedure appTDirectInputControllerHandler.Add(const fn: string);
var
   device: appTDirectInputControllerDevice;

begin
   device := appTDirectInputControllerDevice.Create();

   // device.Initialize(fn);

   appControllers.Add(device);
end;

INITIALIZATION
   appDirectInputControllerHandler.Create();
   appControllers.AddHandler(appDirectInputControllerHandler);

END.
