/*
 * Author:  David Robert Nadeau
 * Site:    http://NadeauSoftware.com/
 * License: Creative Commons Attribution 3.0 Unported License
 *          http://creativecommons.org/licenses/by/3.0/deed.en_US
 */

#ifndef MEMORY_H
#define MEMORY_H

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN

#include <windows.h>
#include <psapi.h>
#include <winternl.h>
#pragma comment(lib, "ntdll.lib")

#ifndef NT_SUCCESS
#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0)
#endif

// https://github.com/winsiderss/systeminformer/blob/v3.2.25011.2103/SystemInformer/procprv.c
typedef struct _VM_COUNTERS_EX_LOCAL
{
	SIZE_T PeakVirtualSize;
	SIZE_T VirtualSize;
	ULONG PageFaultCount;
	SIZE_T PeakWorkingSetSize;
	SIZE_T WorkingSetSize;
	SIZE_T QuotaPeakPagedPoolUsage;
	SIZE_T QuotaPagedPoolUsage;
	SIZE_T QuotaPeakNonPagedPoolUsage;
	SIZE_T QuotaNonPagedPoolUsage;
	SIZE_T PagefileUsage;
	SIZE_T PeakPagefileUsage;
	SIZE_T PrivateUsage;
} VM_COUNTERS_EX_LOCAL;

static bool memory_isRunningUnderWine()
{
	HMODULE ntdll = GetModuleHandleA("ntdll.dll");
	if (!ntdll) return false;
	return GetProcAddress(ntdll, "wine_get_version") != NULL;
}

#elif defined(__unix__) || defined(__unix) || defined(unix) || (defined(__APPLE__) && defined(__MACH__))
#include <unistd.h>
#include <sys/resource.h>

#if defined(__APPLE__) && defined(__MACH__)
#include <mach/mach.h>

#elif (defined(_AIX) || defined(__TOS__AIX__)) || (defined(__sun__) || defined(__sun) || defined(sun) && (defined(__SVR4) || defined(__svr4__)))
#include <fcntl.h>
#include <procfs.h>

#elif defined(__linux__) || defined(__linux) || defined(linux) || defined(__gnu_linux__)
#include <stdio.h>

#endif

#else
#error "Cannot define getCurrentRSS( ) for an unknown OS."
#endif



/**
 * Returns the current memory footprint of the process measured in bytes, or
 * zero if the value cannot be determined on this OS.
 */
size_t getCurrentRSS( )
{
#if defined(_WIN32)
    /* Windows -------------------------------------------------- */
    // https://github.com/winsiderss/systeminformer/blob/v3.2.25011.2103/SystemInformer/procprv.c
    VM_COUNTERS_EX_LOCAL counters = {0};
    NTSTATUS status = NtQueryInformationProcess(
        GetCurrentProcess(),
        (PROCESSINFOCLASS)3, // ProcessVmCounters
        &counters,
        sizeof(counters),
        NULL
    );
    if (NT_SUCCESS(status))
        return (size_t)(memory_isRunningUnderWine() ? counters.PagefileUsage : counters.PrivateUsage);
    return (size_t)0L;

#elif defined(__APPLE__) && defined(__MACH__)
    /* OSX ------------------------------------------------------ */
    struct task_vm_info info;
    mach_msg_type_number_t infoCount = TASK_VM_INFO_COUNT;
    if ( task_info( mach_task_self( ), TASK_VM_INFO,
        (task_info_t)&info, &infoCount ) != KERN_SUCCESS )
        return (size_t)0L;      /* Can't access? */
    const mach_msg_type_number_t minCount =
        (mach_msg_type_number_t)((offsetof(task_vm_info_data_t, compressed) + sizeof(info.compressed)) / sizeof(natural_t));
    if (infoCount >= minCount)
        return (size_t)(info.resident_size + info.compressed);
    return (size_t)info.resident_size;

#elif defined(__linux__) || defined(__linux) || defined(linux) || defined(__gnu_linux__)
    /* Linux ---------------------------------------------------- */
    FILE* fp = NULL;
    if ( (fp = fopen( "/proc/self/status", "r" )) == NULL )
        return (size_t)0L;      /* Can't open? */
    char line[256];
    unsigned long vmPrivate = 0, vmRss = 0, vmSwap = 0;
    while ( fgets( line, sizeof(line), fp ) )
    {
        sscanf( line, "VmPrivate: %lu kB", &vmPrivate );
        sscanf( line, "VmRSS: %lu kB", &vmRss );
        sscanf( line, "VmSwap: %lu kB", &vmSwap );
    }
    fclose( fp );
    if ( vmPrivate > 0 )
        return (size_t)vmPrivate * 1024UL;
    return (size_t)(vmRss + vmSwap) * 1024UL;

#else
    /* AIX, BSD, Solaris, and Unknown OS ------------------------ */
    return (size_t)0L;          /* Unsupported. */
#endif
}

#endif // MEMORY_H
