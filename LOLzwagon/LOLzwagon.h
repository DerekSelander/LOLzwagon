//
//  LOLzwagon.h
//  LOLzwagon
//
//  Created by Derek Selander on 1/30/19.
//  Copyright © 2019 Derek Selander. All rights reserved.
//

#ifndef LOLzwagon_h
#define LOLzwagon_h

#ifndef fishhook_h
#define fishhook_h

#include <stddef.h>
#include <stdint.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/getsect.h>
#include <mach-o/nlist.h>
#include <libgen.h>


#endif //fishhook_h


#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

#ifndef SEG_DATA_CONST
#define SEG_DATA_CONST  "__DATA_CONST"
#endif


struct rebindings_entry {
    struct rebinding *rebindings;
    size_t rebindings_nel;
    struct rebindings_entry *next;
};

#include <dispatch/dispatch.h>
#include <objc/runtime.h>
#include <objc/NSObject.h> // Swizzling for XCTest Expectations
#include <Foundation/Foundation.h>
#include <CommonCrypto/CommonDigest.h>

//*****************************************************************************/
#pragma mark - LLVM Code Coverage Stuff
//*****************************************************************************/

typedef struct llvm_profile_data {
    uint64_t name_ref;
    uint64_t function_hash;
    uintptr_t *counter;
    void *function;
    void *values;
    uint32_t nr_counters;
    uint16_t nr_value_sites[2];
} llvm_profile_data;


// https://llvm.org/docs/CoverageMappingFormat.html
typedef struct __attribute__((packed, aligned(1))) llvm_function_record {
    uint64_t md5;
    uint32_t data_len;
    uint64_t st_hash; // so, like an id?
} llvm_function_record;

typedef struct llvm_mapping_data {
    /// llvm_function_record count of records
    uint32_t num_records;
    /// The length of the string in encoded data
    uint32_t str_len;
    /// The total length of the encoded coverage mapping (broken down further by llvm_function_record's data_len
    uint32_t cov_len;
    uint32_t version; // 2 == v3... yep, I know....
    llvm_function_record records[];
    
    // After the variable sized array of records comes the encodings
} llvm_mapping_data;

#if HAVE_BYTESWAP_H
#include <byteswap.h>
#else
#define bswap_16(value) \
((((value) & 0xff) << 8) | ((value) >> 8))

#define bswap_32(value) \
(((uint32_t)bswap_16((uint16_t)((value) & 0xffff)) << 16) | \
(uint32_t)bswap_16((uint16_t)((value) >> 16)))

#define bswap_64(value) \
(((uint64_t)bswap_32((uint32_t)((value) & 0xffffffff)) \
<< 32) | \
(uint64_t)bswap_32((uint32_t)((value) >> 32)))
#endif

#endif /* LOLzwagon_h */
