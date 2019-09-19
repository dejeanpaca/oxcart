{
   appuControllerXInput, xinput controller handling
   Copyright (C) 2019. Dejan Boras

   Started On:    19.09.2019.
}

{$INCLUDE oxdefines.inc}
UNIT appuControllerXInput;

INTERFACE

   USES
      uStd, uLog,
      appuController,
      DX12.xinput;

TYPE

   { appTXInputControllerHandler }

   appTXInputControllerHandler = class(appTControllerHandler)
      procedure Initialize(); override;
      procedure Reset(); override;
      procedure Run(); override;

      private
         procedure Add(const fn: string);
   end;

   { appTXInputControllerDevice }

   appTXInputControllerDevice = class(appTControllerDevice)
      FileName: string;

      procedure Run(); override;
      procedure DeInitialize(); override;
   end;

IMPLEMENTATION

{ appTXInputControllerDevice }

procedure appTXInputControllerDevice.Run();
begin
end;

procedure appTXInputControllerDevice.DeInitialize();
begin
   inherited;
end;

{ appTXInputControllerHandler }

procedure appTXInputControllerHandler.Initialize();
begin
   Reset();
end;

procedure appTXInputControllerHandler.Reset();
begin
   inherited;
end;

procedure appTXInputControllerHandler.Run();
begin
   inherited Run();
end;

procedure appTXInputControllerHandler.Add(const fn: string);
var
   device: appTXInputControllerDevice;

begin
   device := appTXInputControllerDevice.Create();

   // device.Initialize(fn);

   appControllers.Add(device);
end;

INITIALIZATION
   appControllerHandler := appTXInputControllerHandler.Create();

END.
