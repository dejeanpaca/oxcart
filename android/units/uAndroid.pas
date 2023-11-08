{
   uAndroid
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uAndroid;

INTERFACE

   USES
      ctypes, jni;

CONST
   __ANDROID_API_FUTURE__ = 10000;

   (** Names the Gingerbread API level (9), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_G__ = 9;
   (* Names the Ice-Cream Sandwich API level (14), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_I__ = 14;
   (* Names the Jellybean API level (16), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_J__ = 16;
   (* Names the Jellybean MR1 API level (17), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_J_MR1__ = 17;
   (* Names the Jellybean MR2 API level (18), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_J_MR2__ = 18;
   (* Names the KitKat API level (19), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_K__ = 19;
   (* Names the Lollipop API level (21), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_L__ = 21;
   (* Names the Lollipop MR1 API level (22), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_L_MR1__ = 22;
   (* Names the Marshmallow API level (23), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_M__ = 23;
   (* Names the Nougat API level (24), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_N__ = 24;
   (* Names the Nougat MR1 API level (25), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_N_MR1__ = 25;
   (* Names the Oreo API level (26), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_O__ = 26;
   (* Names the Oreo MR1 API level (27), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_O_MR1__ = 27;
   (* Names the Pie API level (28), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_P__ = 28;
   (*
    * Names the "Q" API level (29), for comparison against `__ANDROID_API__`.
    * This release was called Android 10 publicly, not to be (but sure to be)
    * confused with API level 10.
    *)
   __ANDROID_API_Q__ = 29;
   (* Names the "R" API level (30), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_R__ = 30;
   (* Names the "S" API level (31), for comparison against `__ANDROID_API__`. *)
   __ANDROID_API_S__ = 31;

VAR
   android_api_level: longint;
   mainThreadEnv:  PJNIEnv;

IMPLEMENTATION

INITIALIZATION
   android_api_level := SystemApiLevel();

END.
