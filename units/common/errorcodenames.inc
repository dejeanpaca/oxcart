{
   runtime error codes

   Copyright (C) 2008. Dejan Boras
}

{general error codes}
   eNONE                      = 00000;
   eERR                       = 00001;
   eNO_MEMORY                 = 00002;
   eUNABLE                    = 00003;
   eEXTERNAL                  = 00004;
   eUNEXPECTED                = 00005;
   eFAIL                      = 00006;
   eIO                        = 00007;
   eWRITE                     = 00008;
   eREAD                      = 00009;
   eHARDWARE_FAILURE          = 00010;
   eMEMORY                    = 00011;
   eCANT_FREE                 = 00012;
   eNIL                       = 00013;
   eNOT_NIL                   = 00014;
   eINVALID_ARG               = 00015;
   eINVALID_ENV               = 00016;
   eINVALID                   = 00017;
   eCORRUPTED                 = 00018;
   eUNSUPPORTED               = 00019;
   eNOT_INITIALIZED           = 00020;
   eINITIALIZED               = 00021;
   eINITIALIZATION_FAIL       = 00022;
   eDEINITIALIZATION_FAIL     = 00023;
   eEMPTY                     = 00024;
   eFULL                      = 00025;
   eNOT_OPEN                  = 00026;
   eOPEN_FAIL                 = 00027;
   eNOT_CLOSED                = 00028;
   eCLOSE_FAIL                = 00029;
   eNOT_FOUND                 = 00030;

{general error code names}
   esNONE                     = 'eNONE';
   esERR                      = 'eERR';
   esNO_MEMORY                = 'eNO_MEMORY';
   esUNABLE                   = 'eUNABLE';
   esEXTERNAL                 = 'eEXTERNAL';
   esUNEXPECTED               = 'eUNEXPECTED';
   esFAIL                     = 'eFAIL';
   esIO                       = 'eIO';
   esWRITE                    = 'eWRITE';
   esREAD                     = 'eREAD';
   esHARDWARE_FAILURE         = 'eHARDWARE_FAILURE';
   esMEMORY                   = 'eMEMORY';
   esCANT_FREE                = 'eCANT_FREE';
   esNIL                      = 'eNIL';
   esNOT_NIL                  = 'eNOT_NIL';
   esINVALID_ARG              = 'eINVALID_ARG';
   esINVALID_ENV              = 'eINVALID_ENV';
   esINVALID                  = 'eINVALID';
   esCORRUPTED                = 'eCORRUPTED';
   esUNSUPPORTED              = 'eUNSUPPORTED';
   esNOT_INITIALIZED          = 'eNOT_INITIALIZED';
   esINITIALIZED              = 'eINITIALIZED';
   esINITIALIZATION_FAIL      = 'eINITIALIZATION_FAIL';
   esDEINITIALIZATION_FAIL    = 'eDEINITIALIZATION_FAIL';
   esEMPTY                    = 'eEMPTY';
   esFULL                     = 'eFULL';
   esNOT_OPEN                 = 'eNOT_OPEN';
   esOPEN_FAIL                = 'eOPEN_FAIL';
   esNOT_CLOSED               = 'eNOT_CLOSED';
   esCLOSE_FAIL               = 'eCLOSE_FAIL';
   esNOT_FOUND                = 'eNOT_FOUND';

{run-time error codes}
   reFILE_NOT_FOUND           = 00002;
   rePATH_NOT_FOUND           = 00003;
   reTOO_MANY_OPEN_FILES      = 00004;
   reFILE_ACCESS_DENIED       = 00005;
   reINVALID_FILE_HANDLE      = 00006;
   reINVALID_DRIVE            = 00015;
   reCANNOT_REMOVE_DIR        = 00016;
   reDISK_READ                = 00100;
   reDISK_WRITE               = 00101;
   reFILE_NOT_ASSIGNED        = 00102;
   reFILE_NOT_OPEN            = 00103;
   reDISK_WRITE_PROTECTED     = 00150;
   reDRIVE_NOT_READY          = 00152;
   reCRC                      = 00154;
   reDISK_SEEK                = 00156;
   reRANGE_CHECK              = 00201;
   reSTACK_OVERFLOW           = 00202;
   reHEAP_OVERFLOW            = 00203;

   resFILE_NOT_FOUND          = 'reFILE_NOT_FOUND';
   resPATH_NOT_FOUND          = 'rePATH_NOT_FOUND';
   resTOO_MANY_OPEN_FILES     = 'reTOO_MANY_OPEN_FILES';
   resFILE_ACCESS_DENIED      = 'reFILE_ACCESS_DENIED';
   resINVALID_FILE_HANDLE     = 'reINVALID_FILE_HANDLE';
   resINVALID_DRIVE           = 'reINVALID_DRIVE';
   resCANNOT_REMOVE_DIR       = 'reCANNOT_REMOVE_DIR';
   resDISK_READ               = 'reDISK_READ';
   resDISK_WRITE              = 'reDISK_WRITE';
   resFILE_NOT_ASSIGNED       = 'reFILE_NOT_ASSIGNED';
   resFILE_NOT_OPEN           = 'reFILE_NOT_OPEN';
   resDISK_WRITE_PROTECTED    = 'reDISK_WRITE_PROTECTED';
   resDRIVE_NOT_READY         = 'reDRIVE_NOT_READY';
   resCRC                     = 'reCRC';
   resDISK_SEEK               = 'reDISK_SEEK';
   resRANGE_CHECK             = 'reRANGE_CHECK';
   resSTACK_OVERFLOW          = 'reSTACK_OVERFLOW';
   resHEAP_OVERFLOW           = 'reHEAP_OVERFLOW';
