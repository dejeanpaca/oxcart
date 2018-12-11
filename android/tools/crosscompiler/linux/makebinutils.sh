# This script references a specific version of binutils, so change any references to
# allow for using another version of binutils.

## we want to quit on any error
set -e

rm -rf ~/programming/binutils
mkdir ~/programming/fpcandroid/binutils

# download binutils and unpack

cd ~/programming/
mkdir binutils
cd binutils

wget http://ftp.gnu.org/gnu/binutils/binutils-2.23.1.tar.bz2
tar xjf ../binutils-2.23.1.tar.bz2

# build the binutils

cd ~/programming/binutils/binutils-2.23.1/

./configure --target=arm-linux --disable-werror
make

# move the binutils to the required location
cp gas/as-new ~/programming/fpcandroid/binutils/
cp ld/ld-new ~/programming/fpcandroid/binutils/
cp strip-new ~/programming/fpcandroid/binutils/strip
cp addr2line ~/programming/fpcandroid/binutils/

# move the hookscripts
cp ~/programming/dbxpas/android/tools/hookscripts/linux/* ~/programming/fpcandroid/bin
