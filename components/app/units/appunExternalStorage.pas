{
   appunExternalStorage.pas, external storage configuration
   Copyright (C) 2011. Dejan Boras

   Started On:    24.12.2011.
}

{$MODE OBJFPC}{$H+}
UNIT appunExternalStorage;

INTERFACE

   USES uPropertySection;

CONST
   appcExternalStorageAvailable: boolean  = false;
   appcExternalStorageWritable: boolean   = false;
   appcExternalStorageRemovable: boolean  = false;
   appcExternalStoragePath: string        = '';

VAR
   appExternalStoragePropertySection: TPropertySection;

IMPLEMENTATION

END.
