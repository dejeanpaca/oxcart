{
   oxAndroidLibExports.inc, android library exports
   Copyright (c) 2011. Dejan Boras

   Started On:    09.02.2011.
}

   jniOnLoad name 'JNI_OnLoad',

   jniAndroidInit name 'Java_dbx_oX_Native_oxNative_Init',
   jniAndroidPreInit name 'Java_dbx_oX_Native_oxNative_PreInit',
   jniAndroidSurfaceChange name 'Java_dbx_oX_Native_oxNative_SurfaceChange',
   jniAndroidRunCycle name 'Java_dbx_oX_Native_oxNative_RunCycle',
   jniAndroidDestroy name 'Java_dbx_oX_Native_oxNative_Destroy',
   jniAndroidTouch name 'Java_dbx_oX_Native_oxNative_Touch',
   jniAndroidKey name 'Java_dbx_oX_Native_oxNative_Key',
   jniAndroidQuit name 'Java_dbx_oX_Native_oxNative_Quit',
   jniAndroidTerminate name 'Java_dbx_oX_Native_oxNative_Terminate',

   jniAndroidSetStringProperty name 'Java_dbx_oX_Native_oxNative_SetStringProperty',
   jniAndroidSetIntProperty name 'Java_dbx_oX_Native_oxNative_SetIntProperty',
   jniAndroidSetBooleanProperty name 'Java_dbx_oX_Native_oxNative_SetBooleanProperty',

   oxnInitialize name 'Java_dbx_oX_Native_oxn_Initialize'
