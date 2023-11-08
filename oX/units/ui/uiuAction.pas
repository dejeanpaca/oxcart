{
   uiuAction
   Copyright (C) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuAction;

INTERFACE

   USES
      uStd,
      {app}
      appuKeys, appuEvents, appuActionEvents,
      {ox}
      oxuGlyph;

TYPE
   uiTAction = record
      {name for this action}
      Name,
      {group this action belongs to}
      Group,
      {hint }
      Hint: StdString;
      {action ID, used to call an action event to run this action}
      Action: TEventID;
      {name of the glyph used for this action}
      Glyph: oxTGlyphName;
      {key mapping used for the action}
      KeyMapping: record
         Group: string;
         KeyCode: longint;
         State: TBitSet;
      end;
   end;

IMPLEMENTATIOn

END.
