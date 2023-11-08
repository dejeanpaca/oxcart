cd ~/programming/fpcandroidsrc/
make clean crossinstall CPU_TARGET=arm OS_TARGET=linux CROSSBINDIR=/home/dejan/programming/fpcandroid/bin OPT="-dFPC_ARMEL -O- -gl" CROSSOPT="-dANDROID -CpARMv5 -gl -CfSOFT -O-" INSTALL_PREFIX=/home/dejan/programming/fpcandroid

cd ~/programming/fpcandroid/lib/fpc/2.6.0/
mv ppcrossarm ~/programming/fpcandroid/bin/

cd units/arm-linux/

mkdir ~/programming/fpcandroid/units
mv rtl ~/programming/fpcandroid/units/
mv hash ~/programming/fpcandroid/units/
mv paszlib ~/programming/fpcandroid/units/

# copy config file
cp -n ~/programming/dbxpas/android/tools/crosscompiler/config/fpc-linux.cfg ~/programming/fpcandroid/bin/fpc.cfg

# cleanup
rm -rf ~/programming/fpcandroid/lib/
