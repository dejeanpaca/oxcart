{
   oxuInput, oX unified input
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuInput;

INTERFACE

   USES
      uStd,
      appuKeys, appuMouse,
      appuController,
      {oX}
      oxuKeyboardControl;

TYPE
   oxTInputDeviceType = (
      OX_INPUT_DEVICE_KEYBOARD,
      OX_INPUT_DEVICE_POINTER,
      OX_INPUT_DEVICE_CONTROLLER
   );

   oxTInputActionMapping = record
      DeviceType: oxTInputDeviceType;
   end;

   oxTInputAction = record
      {action Id}
      ActionId,
      {how many inputs are mapped to this action}
      MappingCount: loopint;

      {all mappings related to this action}
      Mappings = array[0..3] of oxTInputActionMapping;
   end;

   oxTInputActionsList = specialize TSimpleList<oxTInputAction>;

   oxTInputActions = record
     List: oxTInputActionsList;
   end;

IMPLEMENTATION

END.
