{
   xkeysyms.inc, Keysym remap codes
   Copyright (C) 2009. Dejan Boras

   GENERAL INFORMATION

   This is not a valid pascal include file. It is a list of keysyms with their
   values and respective dApp keycode remap. The keysyms were obtained from 
   X11 keysymdef.h file and other associated files(found in /usr/include/X11/
   on Fedora 11).

   This list is to be processed via the xkeycoderemap program found in Tools/ of
   dApp project. Any additional remaps can be added according to the following
   syntax.

   SYNTAX:

      XK_KeySym                              = ($HEXVAL, kcKEYCODE);

   XK_KeySym is the keysym name followed by an equal = sign. This is usually
   ignored by the program and is only for your reference(as comparing the values
   is harder than names). Inside brackets, separated by a comma, is the keysym
   value(HEXVAL, usually a hexadecimal value) and the dApp keycode(kcKEYCODE)
   with which the keysym will be remapped. Following is a semicolon.

   Regular comments are allowed, but should be on a single line.

   Entries where the keycode is omitted will be ignored.

   OUTPUT:
      Only keysyms in the range $FF08 to $FFFF () and $FE00 to $FEFF
   (ISO LATIN 1) are taken into consideration by xkeycoderemap. This is due to
   many reasons.

   Tge xkeycoderemap program will create a xkeyremapcodes.inc file which will
   contain arrays with remap keycodes.

   The resulting file should be put into the dApp/Units/ directory. The file is
   included by uiiLinuxCommon. The file must be always present as you cannot
   expect a person to create the file every time they wan't to compile dApp.
}

CONST
   XK_BackSpace                           = ($ff08, kcBACKSPACE);  {Back space, back char}
   XK_Tab                                 = ($ff09, kcTAB);
   XK_Linefeed                            = ($ff0a,);  {Linefeed, LF}
   XK_Clear                               = ($ff0b,);
   XK_Return                              = ($ff0d, kcRETURN);  {Return, enter}
   XK_Pause                               = ($ff13, kcPAUSEBREAK);  {Pause, hold}
   XK_Scroll_Lock                         = ($ff14, kcSCROLLLOCK);
   XK_Sys_Req                             = ($ff15, kcSYSREQ);
   XK_Escape                              = ($ff1b, kcESC);
   XK_Delete                              = ($ffff, kcDELETE);  {Delete, rubout}

{cursor control & motion}

   XK_Home                                = ($ff50, kcHOME);
   XK_Left                                = ($ff51, kcLEFT);  { Move left, left arrow }
   XK_Up                                  = ($ff52, kcUP);  { Move up, up arrow }
   XK_Right                               = ($ff53, kcRIGHT);  { Move right, right arrow }
   XK_Down                                = ($ff54, kcDOWN);  { Move down, down arrow }
   XK_Prior                               = ($ff55, kcPGUP);  { Prior, previous }
   XK_Page_Up                             = ($ff55, kcPGUP);
   XK_Next                                = ($ff56, kcPGDN);  { Next }
   XK_Page_Down                           = ($ff56, kcPGDN);
   XK_End                                 = ($ff57, kcEND);  { EOL }
   XK_Begin                               = ($ff58,);  { BOL }


{misc functions}

   XK_Select                              = ($ff60,);  { Select, mark }
   XK_Print                               = ($ff61,);
   XK_Execute                             = ($ff62,);  { Execute, run, do }
   XK_Insert                              = ($ff63, kcINSERT);  { Insert, insert here }
   XK_Undo                                = ($ff65,);
   XK_Redo                                = ($ff66,);  { Redo, again }
   XK_Menu                                = ($ff67,);
   XK_Find                                = ($ff68,);  { Find, search }
   XK_Cancel                              = ($ff69,);  { Cancel, stop, abort, exit }
   XK_Help                                = ($ff6a,);  { Help }
   XK_Break                               = ($ff6b,);
   XK_Mode_switch                         = ($ff7e,);  { Character set switch }
   XK_script_switch                       = ($ff7e,);  { Alias for mode_switch }
   XK_Num_Lock                            = ($ff7f, kcNUMLOCK);

   XK_KP_Space                            = ($ff80, );  { Space }
   XK_KP_Tab                              = ($ff89, kcTAB);
   XK_KP_Enter                            = ($ff8d, kcRETURN);  { Enter }
   XK_KP_F1                               = ($ff91, kcF1);  { PF1, KP_A, ... }
   XK_KP_F2                               = ($ff92, kcF2);
   XK_KP_F3                               = ($ff93, kcF3);
   XK_KP_F4                               = ($ff94, kcF4);
   XK_KP_Home                             = ($ff95, kcHOME);
   XK_KP_Left                             = ($ff96, kcLEFT);
   XK_KP_Up                               = ($ff97, kcUP);
   XK_KP_Right                            = ($ff98, kcRIGHT);
   XK_KP_Down                             = ($ff99, kcDOWN);
   XK_KP_Prior                            = ($ff9a,);
   XK_KP_Page_Up                          = ($ff9a, kcPGUP);
   XK_KP_Next                             = ($ff9b, kcNEXT);
   XK_KP_Page_Down                        = ($ff9b, kcPGDN);
   XK_KP_End                              = ($ff9c, kcEND);
   XK_KP_Begin                            = ($ff9d,);
   XK_KP_Insert                           = ($ff9e, kcEND);
   XK_KP_Delete                           = ($ff9f, kcDEL);
   XK_KP_Equal                            = ($ffbd, kcEQUAL);  { Equals }
   XK_KP_Multiply                         = ($ffaa, kcNUMMUL);
   XK_KP_Add                              = ($ffab, kcNUMADD);
   XK_KP_Separator                        = ($ffac, kcNUMSEPARATOR);  { Separator, often comma }
   XK_KP_Subtract                         = ($ffad, kcNUMSUBTRACT);
   XK_KP_Decimal                          = ($ffae, kcNUMDECIMAL);
   XK_KP_Divide                           = ($ffaf, kcNUMDIVIDE);

   XK_KP_0                                = ($ffb0, kcNUM0);
   XK_KP_1                                = ($ffb1, kcNUM1);
   XK_KP_2                                = ($ffb2, kcNUM2);
   XK_KP_3                                = ($ffb3, kcNUM3);
   XK_KP_4                                = ($ffb4, kcNUM4);
   XK_KP_5                                = ($ffb5, kcNUM5);
   XK_KP_6                                = ($ffb6, kcNUM6);
   XK_KP_7                                = ($ffb7, kcNUM7);
   XK_KP_8                                = ($ffb8, kcNUM8);
   XK_KP_9                                = ($ffb9, kcNUM9);


{ Auxiliary functions }

   XK_F1                                  = ($ffbe, kcF1);
   XK_F2                                  = ($ffbf, kcF2);
   XK_F3                                  = ($ffc0, kcF3);
   XK_F4                                  = ($ffc1, kcF4);
   XK_F5                                  = ($ffc2, kcF5);
   XK_F6                                  = ($ffc3, kcF6);
   XK_F7                                  = ($ffc4, kcF7);
   XK_F8                                  = ($ffc5, kcF8);
   XK_F9                                  = ($ffc6, kcF9);
   XK_F10                                 = ($ffc7, kcF10);
   XK_F11                                 = ($ffc8, kcF11);
   XK_L1                                  = ($ffc8,);
   XK_F12                                 = ($ffc9, kcF12);
   XK_L2                                  = ($ffc9,);
   XK_F13                                 = ($ffca, kcF13);
   XK_L3                                  = ($ffca,);
   XK_F14                                 = ($ffcb, kcF14);
   XK_L4                                  = ($ffcb,);
   XK_F15                                 = ($ffcc, kcF15);
   XK_L5                                  = ($ffcc,);
   XK_F16                                 = ($ffcd, kcF16);
   XK_L6                                  = ($ffcd,);
   XK_F17                                 = ($ffce, kcF17);
   XK_L7                                  = ($ffce,);
   XK_F18                                 = ($ffcf, kcF18);
   XK_L8                                  = ($ffcf,);
   XK_F19                                 = ($ffd0, kcF19);
   XK_L9                                  = ($ffd0,);
   XK_F20                                 = ($ffd1, kcF20);
   XK_L10                                 = ($ffd1,);
   XK_F21                                 = ($ffd2, kcF21);
   XK_R1                                  = ($ffd2,);
   XK_F22                                 = ($ffd3, kcF22);
   XK_R2                                  = ($ffd3,);
   XK_F23                                 = ($ffd4, kcF23);
   XK_R3                                  = ($ffd4,);
   XK_F24                                 = ($ffd5, kcF24);
   XK_R4                                  = ($ffd5,);
   XK_F25                                 = ($ffd6,);
   XK_R5                                  = ($ffd6,);
   XK_F26                                 = ($ffd7,);
   XK_R6                                  = ($ffd7,);
   XK_F27                                 = ($ffd8,);
   XK_R7                                  = ($ffd8,);
   XK_F28                                 = ($ffd9,);
   XK_R8                                  = ($ffd9,);
   XK_F29                                 = ($ffda,);
   XK_R9                                  = ($ffda,);
   XK_F30                                 = ($ffdb,);
   XK_R10                                 = ($ffdb,);
   XK_F31                                 = ($ffdc,);
   XK_R11                                 = ($ffdc,);
   XK_F32                                 = ($ffdd,);
   XK_R12                                 = ($ffdd,);
   XK_F33                                 = ($ffde,);
   XK_R13                                 = ($ffde,);
   XK_F34                                 = ($ffdf,);
   XK_R14                                 = ($ffdf,);
   XK_F35                                 = ($ffe0,);
   XK_R15                                 = ($ffe0,);

{ Modifiers }

   XK_Shift_L                             = ($ffe1, kcLSHIFT); { Left shift }
   XK_Shift_R                             = ($ffe2, kcRSHIFT); { Right shift }
   XK_Control_L                           = ($ffe3, kcLCTRL); { Left control }
   XK_Control_R                           = ($ffe4, kcRCTRL); { Right control }
   XK_Caps_Lock                           = ($ffe5, kcCAPSLOCK); { Caps lock }
   XK_Shift_Lock                          = ($ffe6,); { Shift lock }

   XK_Meta_L                              = ($ffe7,); { Left meta }
   XK_Meta_R                              = ($ffe8,); { Right meta }
   XK_Alt_L                               = ($ffe9, kcLALT); { Left alt }
   XK_Alt_R                               = ($ffea, kcRALT); { Right alt }
   XK_Super_L                             = ($ffeb,); { Left super }
   XK_Super_R                             = ($ffec,); { Right super }
   XK_Hyper_L                             = ($ffed,); { Left hyper }
   XK_Hyper_R                             = ($ffee,); { Right hyper }

