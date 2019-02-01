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
#import "LOLzwagon.h"

//*****************************************************************************/
#pragma mark - LLVM Mapping Functions
//*****************************************************************************/

/// Records can be variable in size, need to look at the func count to get address
__attribute__((used)) static char* LLVMMappingGetEncodedFilename(llvm_mapping_data *data) {
    return (char*)(&data->records) + (sizeof(llvm_function_record) * data->num_records);
}

__attribute__((used)) static BOOL LLVMMappingContainsFunction(char *function_name, llvm_mapping_data *data) {
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(function_name, (CC_LONG)strlen(function_name), r);
    uint64_t *md5 = (uint64_t *)r;
    bswap_64((uint64_t)md5);
    for (int i = 0; i < data->num_records; i++) {
        llvm_function_record *function = &data->records[i];
        if (function->md5 == *md5) {
            return YES;
        }
    }
    return  NO;
}

__attribute__((used)) static char* LLVMMappingGetEncodedData(llvm_mapping_data *data) {
    return (char*)(&data->records) + (sizeof(llvm_function_record) * data->num_records) + data->str_len;
}

__attribute__((used))
static size_t LLVMMappingGetSize(llvm_mapping_data *data) {
    size_t size = data->num_records * sizeof(llvm_function_record) + data->str_len + data->cov_len + 16;
    size += size % 8; // Docs say 8 byte alignment
    return size;
}

__attribute__((used))
static void LLVMMappingPrintData(llvm_mapping_data *data) {
    
    char *str = LLVMMappingGetEncodedFilename(data);
    printf("%s, %d functions: ", basename(str), data->num_records);
    
    size_t cur_length = 0;
    for (int i = 0; i < data->num_records; i++) {
        
        llvm_function_record *record = &data->records[i];
        char *encodedData = LLVMMappingGetEncodedData(data);
        
        printf("\n\tfunction %d (%p), en_len:%d st_len:%llu\n\t\t", i, (void*)record->md5, record->data_len, record->st_hash);
        
        encodedData[cur_length + 3] = 0x0;
        for (int j = (int)cur_length; j < record->data_len + cur_length; j++) {
            printf(" %02x", encodedData[j]);
        }
        cur_length += record->data_len;
        printf("\n");
    }
}

/// Used for the majority of wiping out the XCTest functions
__attribute__((used)) static void noOpFunction() { }




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

 void lolzwagon(const struct mach_header *header, intptr_t slide) {
    
#ifdef __LP64__
    uint64_t size = 0;
    uint64_t llvm_size = 0;
    uint64_t llvm_prf_size = 0;
    char *data = getsectdatafromheader_64((const struct mach_header_64*)header, "__DATA", "__llvm_prf_cnts", &size) + slide;
    char *llvm_data = getsectdatafromheader_64((const struct mach_header_64*)header, "__LLVM_COV", "__llvm_covmap", &llvm_size) + slide;
    char *llvm_prf = getsectdatafromheader_64((const struct mach_header_64*)header, "__DATA", "__llvm_prf_data", &llvm_prf_size) + slide;
#else
    uint32_t size = 0;
    uint32_t llvm_size = 0;
    uint64_t llvm_prf_size = 0;
    char *data = getsectdatafromheader(header, "__DATA", "__llvm_covmap", &size) + slide;
    char *llvm_data = getsectdatafromheader(header, "__LLVM_COV", "__llvm_covmap", &llvm_size) + slide;
    char *llvm_prf = getsectdatafromheader(header, "__DATA", "__llvm_prf_data", &llvm_prf_size) + slide;
#endif
    
//    if (llvm_size) {
//
//        uintptr_t cur = (uintptr_t)llvm_data;
//        
////        while (cur < (uintptr_t)(llvm_data + llvm_size)) {
////            llvm_mapping_data *mapping_data = (llvm_mapping_data *)cur;
//////            printf("%p\n", mapping_data);
////            llvm_function_record *records = (llvm_function_record *)&mapping_data->records;
//////            printf("mapping %p, len %d, mapping: %d, encoded str %s\n", mapping_data, mapping_data->string_encoded_translation_length, mapping_data->string_encoded_coverage_mapping, LLVMMappingGetEncodedFilename(mapping_data));
//////            BOOL yay = LLVMMappingContainsFunction("+[TestView test]", data);
//////            LLVMMappingPrintData(mapping_data);
//////            LLVMMappingPrintData(mapping_data);
////            cur += LLVMMappingGetSize(mapping_data);
////        }
    }
    
    
    
//    If we wanted to go through the __DATA,__llvm_prf_data instead
//
    if (llvm_prf_size) {
        llvm_profile_data *llvm_data_ptr = (llvm_profile_data *)llvm_prf;
        for (int j = 0; j < llvm_prf_size / sizeof(llvm_profile_data); j++) {
            llvm_profile_data *profile = &llvm_data_ptr[j];
            int f_counter = profile->nr_counters;
            for (int z = 0; z < profile->nr_counters; z++) {
                
//#ifdef FuckYeahIWantAPromotion // enables 100% code coverage, use IWantARaise scheme
                if (z == 0) {
                    profile->counter[z]+= 3;
                } else {
                    profile->counter[z]++;
                }
//#else
//                profile->counter[z]++;
//#endif // FuckYeahIWantAPromotion
            }
        }
    }

    rebind_xctest_symbols_for_image(header, slide);
}


/******************************************************************************/
// MARK: - XCTest Swizzling
/******************************************************************************/
@interface NSObject (DS_XCTestCase_Swizzle)
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

@implementation NSObject (DS_XCTestCase_Swizzle)

-(void)dsXCTestCase_waitForExpectations:(NSArray*)expectations timeout:(void *)timeout enforceOrder:(BOOL)enforceOrder  {
    for (id expectation in expectations) {
        if (![expectation performSelector:@selector(isFulfilled)]) {
            [expectation performSelector:@selector(fulfill)];
        }
    }
    [self dsXCTestCase_waitForExpectations:expectations timeout:timeout enforceOrder:enforceOrder];
}

-(void)dsXCTestExpectation_fulfill {
    if ([self respondsToSelector:@selector(isFulfilled)]) {
        if ([self performSelector:@selector(isFulfilled)]) {
            return;
        }
    }
    [self dsXCTestExpectation_fulfill];
}

// noOP for XCTestCase
-(void)dsXCTestCase_recordFailureWithAssertionName:(id)arg0 subject:(id)arg1 reason:(id)arg2 message:(id)arg3 inFile:(id)arg4 atLine:(NSInteger)arg5 expected:(BOOL)arg6  {
    [self dsXCTestCase_recordFailureWithAssertionName: arg0 subject: arg1 reason: arg2 message: arg3 inFile: arg4 atLine: arg5 expected: arg6 ];
}


@end
#pragma clang diagnostic pop

static void do_that_swizzle_thing(void) {
    __unused static void (^swizzle)(NSString *, NSString *) = ^(NSString *className, NSString *method) {
        Class cls = NSClassFromString(className);
        if (!cls) { return; }
        
        NSString *swizzledString = [(NSString *)[(NSString *)[@"ds" stringByAppendingString:className] stringByAppendingString:@"_"] stringByAppendingString:method];
        
        SEL originalSelector = NSSelectorFromString(method);
        SEL swizzledSelector = NSSelectorFromString(swizzledString);
        Method originalMethod = class_getInstanceMethod(cls, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
        
        if (!originalMethod || !swizzledMethod) {
            assert(NO);
            return;
        }
        method_exchangeImplementations(originalMethod, swizzledMethod);
       
    };
    
    static dispatch_once_t onceToken;
    dispatch_once (&onceToken, ^{
        swizzle(@"XCTestCase", @"recordFailureWithAssertionName:subject:reason:message:inFile:atLine:expected:");
        swizzle(@"XCTestExpectation", @"fulfill");
        swizzle(@"XCTestCase", @"waitForExpectations:timeout:enforceOrder:");
//        swizzle(@"waitForExpectationsWithTimeout:handler:", NO);
//        swizzle(@"recordFailureWithDescription:inFile:atLine:expected:", NO);
    });
}

/******************************************************************************/
// MARK: - Fun starts here
/******************************************************************************/
__attribute__((constructor)) static void lets_get_it_started_in_haaaaa(void) {
    _dyld_register_func_for_add_image(lolzwagon);
    do_that_swizzle_thing();
}
