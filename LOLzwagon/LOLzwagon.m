// Copyright (c) 2013, Facebook, Inc.
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//   * Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//   * Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//   * Neither the name Facebook nor the names of its contributors may be used to
//     endorse or promote products derived from this software without specific
//     prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  LOLzwagon.c
//  LOLzwagon
//
//  Created by Derek Selander on 1/27/19.
//  Copyright © 2019 Derek Selander. All rights reserved.
//


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
#include <dispatch/dispatch.h>
#include <objc/runtime.h>
#include <objc/NSObject.h>
#include <Foundation/Foundation.h>

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

typedef struct llvm_profile_data {
    uint64_t name_ref;
    uint64_t function_hash;
    uintptr_t *counter;
    void *function;
    void *values;
    uint32_t nr_counters;
    uint16_t nr_value_sites[2];
} llvm_profile_data;

/// Used for the majority of wiping out the XCTest functions
__attribute((used)) static void noOpFunction() { }


static void rebind_xctest_functions(section_t *section,
                                           intptr_t slide,
                                           nlist_t *symtab,
                                           char *strtab,
                                           uint32_t *indirect_symtab) {
    uint32_t *indirect_symbol_indices = indirect_symtab + section->reserved1;
    void **indirect_symbol_bindings = (void **)((uintptr_t)slide + section->addr);
    for (uint i = 0; i < section->size / sizeof(void *); i++) {
        uint32_t symtab_index = indirect_symbol_indices[i];
        if (symtab_index == INDIRECT_SYMBOL_ABS || symtab_index == INDIRECT_SYMBOL_LOCAL ||
            symtab_index == (INDIRECT_SYMBOL_LOCAL   | INDIRECT_SYMBOL_ABS)) {
            continue;
        }
        uint32_t strtab_offset = symtab[symtab_index].n_un.n_strx;
        char *symbol_name = strtab + strtab_offset;
        
        bool symbol_name_longer_than_1 = symbol_name[0] && symbol_name[1];
        
        
        if (!symbol_name_longer_than_1) {
            continue;
        }
        // Objective-C XCTest calls #define'd wrappers to this func
        if (strcmp(symbol_name, "__XCTFailureHandler") == 0) {
             indirect_symbol_bindings[i] = &noOpFunction;
            
        }
        // Swift wraps funcs to XCTest swift mangled names
        else if (strnstr(symbol_name, "_$S6XCTest", 10) && strstr(&symbol_name[6], "XCT")) {
            indirect_symbol_bindings[i] = &noOpFunction;
        }
    }
}

static void rebind_xctest_symbols_for_image(const struct mach_header *header,
                                     intptr_t slide ) {
    Dl_info info;
    if (dladdr(header, &info) == 0) {
        return;
    }
    
    segment_command_t *cur_seg_cmd;
    segment_command_t *linkedit_segment = NULL;
    struct symtab_command* symtab_cmd = NULL;
    struct dysymtab_command* dysymtab_cmd = NULL;
    
    uintptr_t cur = (uintptr_t)header + sizeof(mach_header_t);
    bool linkdsToXCTestOrlibSwiftXCTest = false;
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_LINKEDIT) == 0) {
                linkedit_segment = cur_seg_cmd;
            }
        } else if (cur_seg_cmd->cmd == LC_SYMTAB) {
            symtab_cmd = (struct symtab_command*)cur_seg_cmd;
        } else if (cur_seg_cmd->cmd == LC_DYSYMTAB) {
            dysymtab_cmd = (struct dysymtab_command*)cur_seg_cmd;
        } else if (cur_seg_cmd->cmd == LC_LOAD_DYLIB) {
            struct dylib_command *dyld_cmd = (struct dylib_command *)cur_seg_cmd;
#ifdef __LP64__
            char *libraryPath = (char *)(cur + dyld_cmd->dylib.name.offset);
#else
            char *libraryPath = dyld_cmd->dylib.name.ptr;
#endif
            
            char * libraryName = basename(libraryPath);
            if (strcmp(libraryName, "libswiftXCTest.dylib") == 0
                || strcmp(libraryName, "XCTest") == 0) {
                linkdsToXCTestOrlibSwiftXCTest = true;
            }
        }
    }
    
    if (!linkdsToXCTestOrlibSwiftXCTest || !symtab_cmd || !dysymtab_cmd || !linkedit_segment ||
        !dysymtab_cmd->nindirectsyms) {
        return;
    }
    
    // Find base symbol/string table addresses
    uintptr_t linkedit_base = (uintptr_t)slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
    nlist_t *symtab = (nlist_t *)(linkedit_base + symtab_cmd->symoff);
    char *strtab = (char *)(linkedit_base + symtab_cmd->stroff);
    
    // Get indirect symbol table (array of uint32_t indices into symbol table)
    uint32_t *indirect_symtab = (uint32_t *)(linkedit_base + dysymtab_cmd->indirectsymoff);
    
    cur = (uintptr_t)header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_DATA) != 0 &&
                strcmp(cur_seg_cmd->segname, SEG_DATA_CONST) != 0) {
                continue;
            }
            for (uint j = 0; j < cur_seg_cmd->nsects; j++) {
                section_t *sect =
                (section_t *)(cur + sizeof(segment_command_t)) + j;
                if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS) {
                    rebind_xctest_functions(sect, slide, symtab, strtab, indirect_symtab);
                }
                if ((sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
                    rebind_xctest_functions(sect, slide, symtab, strtab, indirect_symtab);
                }
            }
        }
    }
}

static void lolzwagon(const struct mach_header *header, intptr_t slide) {
    
#ifdef __LP64__
    uint64_t size = 0;
    char *data = getsectdatafromheader_64((const struct mach_header_64*)header, "__DATA", "__llvm_prf_cnts", &size) + slide;
#else
    uint32_t size = 0;
    char *data = getsectdatafromheader(header, "__DATA", "__llvm_prf_cnts", &size) + slide;
#endif
    
    if (!size) { return; }
    
//    If we wanted to go through the __DATA,__llvm_prf_data instead
//    llvm_profile_data *llvm_data_ptr = (llvm_profile_data *)data;
//    
//
//    for (int j = 0; j < size / sizeof(llvm_profile_data); j++) {
//        llvm_profile_data profile = llvm_data_ptr[j];
//        for (int z = 0; z < profile.nr_counters; z++) {
//            profile.counter[z]++;
//        }
//        profile.nr_counters = 1;
//    }

    
    
    uintptr_t *ptr = (uintptr_t*)data;
    for (int j = 0; j < size / sizeof(void*); j++) {
        // array of longs in __llvm_prf_cnts,
        // if != 0, then that code section has been explored
        ptr[j]++;
    }
    
    rebind_xctest_symbols_for_image(header, slide);
}



/// Logic to knock out XCTestExpectations...
@interface NSObject (DS_XCTestCase_Swizzle)
@end

@implementation NSObject (DS_XCTestCase_Swizzle)
-(void)dsXCTestCase_waitForExpectations:(NSArray*)expectations timeout:(void *)timeout enforceOrder:(BOOL)enforceOrder  {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    for (id expectation in expectations) {
        [expectation performSelector:@selector(fulfill)];
    }
#pragma clang diagnostic pop
    [self dsXCTestCase_waitForExpectations:expectations timeout:timeout enforceOrder:enforceOrder];
}
@end

static void do_that_swizzle_thing_you_always_do() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"XCTestCase");
        if (!cls) { return; }
        
        NSString *method = @"waitForExpectations:timeout:enforceOrder:";
        SEL originalSelector = NSSelectorFromString(method);
        SEL swizzledSelector = NSSelectorFromString(@"dsXCTestCase_waitForExpectations:timeout:enforceOrder:");
        Method originalMethod = class_getInstanceMethod(cls, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

/// The fun starts here
__attribute__((constructor)) static void lets_get_it_started_in_haaaaa(void) {
    _dyld_register_func_for_add_image(lolzwagon);
    do_that_swizzle_thing_you_always_do();
}