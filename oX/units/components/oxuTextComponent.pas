{
   oxuTextComponent, text rendering component
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuTextComponent;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      oxuComponent, oxuComponentDescriptors, oxuRenderComponent, oxuEntity,
      oxuFont, oxuSerialization;

TYPE

   { oxTTextComponent }

   oxTTextComponent = class(oxTRenderComponent)
      public
      Text: StdString;
      {buffered text}
      Buffer: oxTFontBuffer;

      constructor Create(); override;

      procedure Render(); override;

      procedure SetText(const newText: StdString);

      procedure GetBoundingBox(out bbox: TBoundingBox); override;
      function GetDescriptor(): oxPComponentDescriptor; override;

      class function GetEntity(const useText: StdString; out component: oxTTextComponent): oxTEntity; static;
   end;

IMPLEMENTATION

VAR
   serializer: oxTSerialization;
   descriptor: oxTComponentDescriptor;

{ oxTTextComponent }

constructor oxTTextComponent.Create();
begin
   inherited Create;
end;

procedure oxTTextComponent.Render();
begin
   {TODO: Implement rendering}
end;

procedure oxTTextComponent.SetText(const newText: StdString);
begin
   Text := newText;

   {TODO: Rebuild text buffer}
end;

procedure oxTTextComponent.GetBoundingBox(out bbox: TBoundingBox);
begin
   {TODO: Implement bounding box calculation}
end;

function oxTTextComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @descriptor;
end;

class function oxTTextComponent.GetEntity(const useText: StdString; out component: oxTTextComponent): oxTEntity;
begin
   component := oxTTextComponent.Create();
   Result := oxEntity.New('Text', component);
   component.SetText(useText);
end;

function instance(): TObject;
begin
   Result := oxTTextComponent.Create();
end;

INITIALIZATION
   serializer := oxTSerialization.Create(oxTTextComponent, @instance);

   descriptor.Create('text', oxTTextComponent);
   descriptor.Name := 'Text';

FINALIZATION
   FreeObject(serializer);

END.
