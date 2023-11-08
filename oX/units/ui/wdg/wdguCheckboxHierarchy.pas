{
   wdguChecboxHierarchy, hierarchical list with checkboxes
   Copyright (C) 2017. Dejan Boras

   Started On:    19.12.2017.
}

{$INCLUDE oxdefines.inc}
UNIT wdguCheckboxHierarchy;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes, oxuTexture,
      {ui}
      uiuWidget, uiWidgets, uiuRegisteredWidgets,
      {wdg}
      wdguHierarchyList, wdguCheckbox, wdguBase;

TYPE
   { wdgTCheckboxHierarchy }

   wdgTCheckboxHierarchy = class(wdgTHierarchyList)
      Internal: uiTWidgetClass; static;

      constructor Create(); override;

      procedure Initialize(); override;

      {is the item checked}
      function IsChecked({%H-}ref: pointer): boolean; virtual;
      {is the item checked}
      procedure SetCheck({%H-}ref: pointer; {%H-}checked: boolean); virtual;

      {render item with a checkbox}
      procedure RenderItem(index: loopint; r: oxTRect); override;

      procedure Load(); override;
      procedure UpdateExpanderWidth();
   end;

   wdgTCheckboxHierarchyGlobal = class(specialize wdgTBase<wdgTCheckboxHierarchy>)
      Internal: uiTWidgetClass; static;
   end;

VAR
   wdgCheckboxHierarchy: wdgTCheckboxHierarchyGlobal;

IMPLEMENTATION

procedure InitWidget();
begin
   wdgCheckboxHierarchy.Internal.Done(wdgTCheckboxHierarchy);

   wdgCheckboxHierarchy := wdgTCheckboxHierarchyGlobal.Create(wdgCheckboxHierarchy.Internal);
end;

{ wdgTCheckboxHierarchy }

constructor wdgTCheckboxHierarchy.Create();
begin
   inherited Create;
end;

procedure wdgTCheckboxHierarchy.Initialize();
begin
   inherited Initialize();

   FontChanged;
end;

function wdgTCheckboxHierarchy.IsChecked(ref: pointer): boolean;
begin
   Result := false;
end;

procedure wdgTCheckboxHierarchy.SetCheck(ref: pointer; checked: boolean);
begin
end;

procedure wdgTCheckboxHierarchy.RenderItem(index: loopint; r: oxTRect);
var
   rect: oxTRect;

begin
   inherited RenderItem(index, r);

   rect := r;
   rect.x := rect.x + GetExpanderWidth() + GetHorizontalItemOffset(index);
   rect.w := r.h - 1;
   rect.h := r.h - 1;

   wdgTCheckbox.RenderCheckbox(self, IsChecked(Visible.List[index].Item), IsEnabled(index), false, rect);
end;

procedure wdgTCheckboxHierarchy.Load();
begin
   inherited;

   UpdateExpanderWidth();
end;

procedure wdgTCheckboxHierarchy.UpdateExpanderWidth();
begin
   ExpanderSeparationWidth := 4 + ItemHeight;
end;


INITIALIZATION
   wdgCheckboxHierarchy.Internal.Register('widget.checkboxhierarchy', @InitWidget);

END.
