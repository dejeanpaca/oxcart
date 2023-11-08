{
   appuControllerDirectInput, DirectInput controller handling
   Copyright (C) 2019. Dejan Boras

   Started On:    19.09.2019.
}

{$INCLUDE oxdefines.inc}
UNIT appuControllerDirectInput;

INTERFACE

   USES
      uStd, uLog,
      appuController;

TYPE

   { appTDirectInputControllerHandler }

   appTDirectInputControllerHandler = class(appTControllerHandler)
      procedure Initialize(); override;
      procedure Reset(); override;
      procedure Run(); override;

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
   appControllers.AddHandler(appTDirectInputControllerHandler.Create());

END.
