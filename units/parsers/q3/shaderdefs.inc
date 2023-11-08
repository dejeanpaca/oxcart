{
   Copyright (C) 2009. Dejan Boras

   This file is an example shader definition file. It is used by q3ParserTest
   to parse the test.shader file. It also explains the shader definition syntax
   and files.

   Syntax of the file:
   #  fieldname1(sub1)     =  (dt1, dt2, dt3, dt4);
   #  fieldname1(sub2)     =  (dt1, dt2);
   #  fieldname1(...)      =  (dt1, dt2);
   #  fieldname3           =  (dt1, dt2, dt3);
   #  fieldname...         =  (dt1, dt2, dt3, dt4, dt5, ...);
   #  fieldnamec           =  (CUSTOM);

   - fieldname is the name of the field (definition name). It can be almost any
    string.
   - # are comments in the file, as the q3makeshaderdefs parser does not really
    fully support pascal comments. If the # symbol appears anywhere on the line
    the line will be ignored. The comment symbols placed above are so that the
    parser does not mistake those for actual type definitions, which are defined
    below.
   - The dtx entries on the right are data types. They are standard data type
    codes (defined in stdDataTypeCodes.pp, without the dtc prefix). The maximum
    number of data types is defined by the q3cMAX_FIELD_DEF_DATA_TYPES in
    q3Shader.pp (8 currently). Do not use the alternative names for data type
    codes (such as VOID for NIL), as these are unrecognized.
    - (subx) is the name of the sub field. As fields can have different parameters
    depending on the first parameter (sub field), the same field can be defined
    multiple times for each sub field. The subfield must be a keyword(a single
    word with no special symbols and no separation), and it's data type must be
    listed in the data types list on the right (SHORTSTRING).
    - Fields which have CUSTOM for data types are left to the user of
    q3Shaders to handle. This is usually used for fields which cannot be handled by
    q3Shaders.

   There cannot be two definitions with the same name, unless they have different
   sub fields, even though the definitions may have different data types used. This
   is a 'limitation' of the q3Shader parser, which will probably never be resolved.

   The q3makeshaderdefs tool will automatically assign each definition a unique ID
   number. Similar definitions (with the same field name, but different subfields)
   are assigned only one unique ID (uID).

   All the above should work reasonably well for Quake 3 shader files, and
   possibly for other games which use shader files similar to q3 but this has been
   untested.

   To generate an include file to use with your programs use the q3makeshaderdefs
   tool.

   Usually only the following data types are supported:
      UINTx, INTx, BOOL, SHORTSTRING
}

   cullface             =  (BOOL);
   color3ub             =  (UINT8, UINT8, UINT8);
   color4ub             =  (UINT8, UINT8, UINT8, UINT8);
   color3f              =  (SINGLE, SINGLE, SINGLE);
   waveGen(saw)         =  (SHORTSTRING, SINGLE, SINGLE);
   waveGen(sine)        =  (SHORTSTRING, SINGLE, SINGLE);
   waveGen(zero)        =  (SHORTSTRING);
#  The next definition is invalid because the sub field dt is not set as SHORTSTRING
   waveGen(nil)         =  (NIL);
   message              =  (SHORTSTRING);
   nopicmip             =  (SHORTSTRING);
   customfield          =  (CUSTOM);
