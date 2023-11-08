Operator Overloads

Started On:    21.05.2010.
Last Update:   22.05.2010.

	To reduce the amount of redundant code, code for operator overloads
	was placed here in the form of include files. The code is covered
	under the same license as is vmVector.pas, and that is:
	GNU General Public License v3. Read the vmVector.pas header comment for
	more information.

The form of an include file is
op[operation][n][ext].inc

[operation]
  add - addition
  sub - subtraction
  mul - multiplication
  div - division

[n]
  - Is the number of components for the vector.
  This can be 2, 3 or 4.

[ext]
   Extension for the operation.
   s     - scalar operation
   i     - integer specific operation (integer div)
   si    - would be the above two combined
