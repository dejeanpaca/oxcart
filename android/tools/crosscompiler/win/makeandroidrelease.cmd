@call setfpcpath.cmd
make clean crossinstall CPU_TARGET=arm OS_TARGET=linux CROSSBINDIR="C:\programming\fpcandroid\bin\i386-win32" OPT="-dFPC_ARMEL -O3" CROSSOPT="-dANDROID -CpARMv5 -CfSOFT -O3" INSTALL_PREFIX="c:\programming\fpcandroidr_"