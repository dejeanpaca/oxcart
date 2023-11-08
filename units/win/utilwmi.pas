(**********************************************************************************
 Copyright (c) 2016 Jurassic Pork - Molly

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
***********************************************************************************)
unit Utilwmi;
 
// 0.1  Jurassic Pork Juillet 2015
// 0.2  Molly  Janvier 2016 : improvement : fpc 3.0 compatibility + usage of  TFPObjectList
 
// Changes 2016-jan-02 (Mol)
// - updated/corrected comments
// - Introduction of variable nrValue.
// - Generic solution for variable nr, using nrValue (inc. pointer assignment)
 
// 0.3  Molly  November 2016 : improvement : support for variant arrays
// Changes 2016-nov-11 (Mol)
// - Add support for variant arrays 

// 0.4 (19.09.2019.)
// - Modified for the purposes of the oX engine
// - Code style changes
// - Removed old wmi code because we use fpc 3+
// - Remove dialog code as we never use that
 
{$MODE OBJFPC}{$H+}{$HINTS ON}
  
INTERFACE
 
   USES
      Classes, contnrs;

Function GetWMIInfo(
   const WMIClass: String;
   const WMIPropertyNames  : Array of String;
   const Condition         : String = ''
): TFPObjectList;
 
IMPLEMENTATION
 
   USES
     Variants,
     ActiveX,
     ComObj,
     SysUtils;
 
function VarArrayToStr(Value: Variant): String;
var
  i : Integer;

begin
   Result := '[';

   for i := VarArrayLowBound(Value, 1) to VarArrayHighBound(Value, 1) do begin
      if Result <> '[' then
         Result := Result + ',';

      if not VarIsNull(Value[i]) then begin
         if VarIsArray(Value[i]) then
            Result := Result + VarArrayToStr(Value[i])
         else
            Result := Result + VartoStr(Value[i])
      end else
         Result := Result + '<null>';
   end;

   Result := Result + ']';
end;

function  GetWMIInfo(const WMIClass: string; const WMIPropertyNames: Array of String; const Condition: string = ''): TFPObjectList;
const
   wbemFlagForwardOnly = $00000020;

var
   FSWbemLocator : Variant;
   objWMIService : Variant;
   colWMI        : Variant;
   oEnumWMI      : IEnumvariant;
   nrValue       : LongWord;
   objWMI        : OLEVariant;                  // FPC 3.0 requires WMIobj to be an olevariant, not a variant
   nr            : LongWord absolute nrValue;   // FPC 3.0 requires IEnumvariant.next to supply a longword variable for # returned values3
   WMIproperties : String;
   WMIProp       : TStringList;
   Request       : String;
   PropertyName  : String;
   PropertyStrVal: String;
   i             : integer;

begin
   // Prepare the search query
   WMIProperties := '';

   for i := low(WMIPropertyNames) to High(WMIPropertyNames) do
      WMIProperties := WMIProperties + WMIPropertyNames[i] + ',';

   Delete(WMIProperties, length(WMIProperties), 1);

   // Let FPObjectList take care of freeing the objects
   Result := TFPObjectList.Create(True);
   try
      FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
      objWMIService := FSWbemLocator.ConnectServer('localhost', 'root\CIMV2', '', '');

      if Condition = '' then
         Request := Format('SELECT %s FROM %s'   , [WMIProperties, WMIClass])
      else
         Request := Format('SELECT %s FROM %s %s', [WMIProperties, WMIClass, Condition]);

      // Start Request
      colWMI := objWMIService.ExecQuery(WideString(Request), 'WQL', wbemFlagForwardOnly);

      // Enum for requested results
      oEnumWMI := IUnknown(colWMI._NewEnum) as IEnumVariant;

      // Enumerate results from query, one by one
      while oEnumWMI.Next(1, objWMI, nr) = 0 do begin
         // Store all property name/value pairs for this enum to TStringList.
         WMIprop := TStringList.Create;

         for i := low(WMIPropertyNames) to High(WMIPropertyNames) do begin
           PropertyName := WMIPropertyNames[i];

            If not VarIsNull(objWMI.Properties_.Item(WideString(PropertyName)).value) then begin
               if VarIsArray(objWMI.Properties_.Item(WideString(PropertyName)).value) then
                  PropertyStrVal := VarArrayToStr(objWMI.Properties_.Item(WideString(PropertyName)).value)
               else
                  PropertyStrVal := VartoStr(objWMI.Properties_.Item(WideString(PropertyName)).value)
            end else
               PropertyStrVal := '<null>';

            WMIProp.Add(PropertyName + '=' + PropertyStrVal);
         end;

         // Add properties from this enum to FPObjectList as TStringList
         Result.Add(WMIProp);
      end;
   except
      // Replace Raise with more appropiate exception if wanted.
      on e: Exception do Raise;
   end;
end;
 
end.
