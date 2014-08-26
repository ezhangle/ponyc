#ifndef PLATFORM_PLATFORM_H
#define PLATFORM_PLATFORM_H

#include <stdbool.h>
#include <stdint.h>

/** Convenience macro for making extern "C" more succinct.
*
*/
#if defined(__cplusplus) && !defined(_MSC_VER)
#  define PONY_EXTERN_C_BEGIN extern "C" {
#  define PONY_EXTERN_C_END }
#else
#  define PONY_EXTERN_C_BEGIN
#  define PONY_EXTERN_C_END
#endif

/** Determines the operating system.
*
*/
#if defined(__APPLE__) && defined(__MACH__)
#  define PLATFORM_IS_MACOSX
#elif defined(__linux__)
#  define PLATFORM_IS_LINUX
#elif defined(_WIN64)
#  define PLATFORM_IS_WINDOWS
#  if defined(_MSC_VER)
#  define PLATFORM_IS_VISUAL_STUDIO
/** Allow formal parameters of functions to remain unused
*
*  http://msdn.microsoft.com/en-us/library/26kb9fy0.aspx
*/
#  pragma warning(disable:4100)
/** Allow constant conditional expressions (e.g. while(true)).
*
*  Microsoft advises to replace expressions like while(true) with for(;;).
*  http://msdn.microsoft.com/en-us/library/6t66728h%28v=vs.90%29.aspx
*/
#  pragma warning(disable:4127)
#  include <BaseTsd.h>
typedef SSIZE_T ssize_t;
typedef SIZE_T size_t;
#endif
# include <Windows.h>
#else
#  error PLATFORM NOT SUPPORTED!
#endif

#if defined(PLATFORM_IS_MACOSX) || defined(PLATFORM_IS_LINUX)
# define PLATFORM_IS_POSIX_BASED
#endif

#if defined(PLATFORM_IS_POSIX_BASED) || defined(__MINGW64__)
#  define PLATFORM_IS_CLANG_OR_GCC
#endif

#ifdef PLATFORM_IS_POSIX_BASED
#  include <stddef.h>
#endif

#define PONY_ERRNO uint32_t

#include "io.h"
#include "utils.h"
#include "format.h"

#if defined(PONY_USE_BIGINT)
#  ifdef __cplusplus
#    include "../bigint/bigint.h"
#  else
#    error Usage of bigint requires C++ compilation!
#  endif
#endif

#endif