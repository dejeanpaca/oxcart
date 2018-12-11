//this shader will generate some warnings
whattashader
{
   {
   }
   {
      lulz ftw
   }
}

//this is an example shader with a main stage but no stages
textures/uzul3/uzul_teleport
{
   cullface false
   color3ub 255 0 0
   nopicmip

   waveGen saw 5 5
   waveGen sine 10 10
   waveGen zero
   // the following should be ignored by q3Shader as it's definition in
   // shaderdefs.inc is invalid.
   waveGen null

   customfield bla bla bla bla;
   waveGen saw 5 5
}
