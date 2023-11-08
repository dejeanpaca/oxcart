UNIT libc_helper;

INTERFACE

USES
   unixtype;

TYPE
   ppthread_t = ^pthread_t;
   ppthread_attr_t = ^pthread_attr_t;
   ppthread_mutex_t = ^pthread_mutex_t;
   ppthread_cond_t = ^pthread_cond_t;
   ppthread_mutexattr_t = ^pthread_mutexattr_t;
   ppthread_condattr_t = ^pthread_condattr_t;

   __start_routine_t = pointer;

CONST
   PTHREAD_CREATE_DETACHED = 1;

function pthread_create(__thread:ppthread_t; __attr:ppthread_attr_t;__start_routine: __start_routine_t;__arg:pointer):longint;cdecl;external 'libc.so';
function pthread_attr_init(__attr:ppthread_attr_t):longint;cdecl;external 'libc.so';
function pthread_attr_setdetachstate(__attr:ppthread_attr_t; __detachstate:longint):longint;cdecl;external 'libc.so';
function pthread_mutex_init(__mutex:ppthread_mutex_t; __mutex_attr:ppthread_mutexattr_t):longint;cdecl;external 'libc.so';
function pthread_mutex_destroy(__mutex:ppthread_mutex_t):longint;cdecl;external 'libc.so';
function pthread_mutex_lock(__mutex: ppthread_mutex_t):longint;cdecl;external 'libc.so';
function pthread_mutex_unlock(__mutex: ppthread_mutex_t):longint;cdecl;external 'libc.so';
function pthread_cond_init(__cond:ppthread_cond_t; __cond_attr:ppthread_condattr_t):longint;cdecl;external 'libc.so';
function pthread_cond_destroy(__cond:ppthread_cond_t):longint;cdecl;external 'libc.so';
function pthread_cond_signal(__cond:ppthread_cond_t):longint;cdecl;external 'libc.so';
function pthread_cond_broadcast(__cond:ppthread_cond_t):longint;cdecl;external 'libc.so';
function pthread_cond_wait(__cond:ppthread_cond_t; __mutex:ppthread_mutex_t):longint;cdecl;external 'libc.so';

IMPLEMENTATION

END.

