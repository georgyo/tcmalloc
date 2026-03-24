{
  global:
    /* C allocator symbols */
    malloc;
    free;
    free_sized;
    free_aligned_sized;
    calloc;
    realloc;
    reallocarray;
    cfree;
    memalign;
    aligned_alloc;
    valloc;
    pvalloc;
    posix_memalign;
    sdallocx;
    malloc_stats;
    malloc_trim;
    mallopt;
    mallinfo;
    mallinfo2;
    malloc_info;
    malloc_size;
    malloc_usable_size;
    alloc_at_least;
    aligned_alloc_at_least;

    /* glibc override symbols */
    __libc_malloc;
    __libc_free;
    __libc_realloc;
    __libc_calloc;
    __libc_cfree;
    __libc_memalign;
    __libc_valloc;
    __libc_pvalloc;
    __posix_memalign;

    /* glibc malloc hooks */
    __malloc_hook;
    __realloc_hook;
    __free_hook;
    __memalign_hook;

    /* C++ operator new variants */
    _Znwm;
    _Znwm12__hot_cold_t;
    _ZnwmRKSt9nothrow_t;
    _ZnwmRKSt9nothrow_t12__hot_cold_t;
    _ZnwmSt11align_val_t;
    _ZnwmSt11align_val_t12__hot_cold_t;
    _ZnwmSt11align_val_tRKSt9nothrow_t;
    _ZnwmSt11align_val_tRKSt9nothrow_t12__hot_cold_t;

    /* C++ operator new[] variants */
    _Znam;
    _Znam12__hot_cold_t;
    _ZnamRKSt9nothrow_t;
    _ZnamRKSt9nothrow_t12__hot_cold_t;
    _ZnamSt11align_val_t;
    _ZnamSt11align_val_t12__hot_cold_t;
    _ZnamSt11align_val_tRKSt9nothrow_t;
    _ZnamSt11align_val_tRKSt9nothrow_t12__hot_cold_t;

    /* C++ operator delete variants */
    _ZdlPv;
    _ZdlPvRKSt9nothrow_t;
    _ZdlPvm;
    _ZdlPvSt11align_val_t;
    _ZdlPvSt11align_val_tRKSt9nothrow_t;
    _ZdlPvmSt11align_val_t;

    /* C++ operator delete[] variants */
    _ZdaPv;
    _ZdaPvRKSt9nothrow_t;
    _ZdaPvm;
    _ZdaPvSt11align_val_t;
    _ZdaPvSt11align_val_tRKSt9nothrow_t;
    _ZdaPvmSt11align_val_t;

    /* TCMallocInternal* functions */
    TCMallocInternal*;

  local:
    *;
};
