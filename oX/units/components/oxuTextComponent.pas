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
      oxuFont, oxuSerialization, oxuMaterial;

TYPE

   { oxTTextComponent }

   oxTTextComponent = class(oxTRenderComponent)
      public
      Font: oxTFont;
      Text: StdString;
      Material: oxTMaterial;

      {cached text}
      Cache: oxTFont2DCache;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure Render(); override;

      procedure SetText(const newText: StdString);
      procedure SetFont(const newFont: oxTFont);

      procedure RebuildCache();

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

   Font := oxFont.GetDefault();
   Material := oxMaterial.Default;
end;

destructor oxTTextComponent.Destroy();
begin
   inherited Destroy;
   Cache.Destroy();
end;

procedure oxTTextComponent.Render();
begin
   if(Font <> nil) and (Material <> nil) then begin
      Material.Apply();
      Font.RenderCache(Cache);
   end;
end;

procedure oxTTextComponent.SetText(const newText: StdString);
begin
   Text := newText;
   RebuildCache();
end;

procedure oxTTextComponent.SetFont(const newFont: oxTFont);
begin
   Font := newFont;
   RebuildCache();
end;

procedure oxTTextComponent.RebuildCache();
begin
   if(Font <> nil) then begin
      Font.Allocate(Text, Cache);
      Font.Cache(Text, Cache);
      Font.CenterUnit(Cache);
   end;
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
