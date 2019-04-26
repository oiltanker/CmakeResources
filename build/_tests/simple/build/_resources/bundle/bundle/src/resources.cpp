//Version 1.0.0
/*
 * This is a resource builder source file
 * Do not change as it is used to generate resources for other targets
 * If you change the source it will affect your project resources
 */

#include "resources.h"

namespace rc {
    Resource::Resource(const void* _begin, const unsigned long long _size):
        begin(_begin), size(_size)
    { };

    // Binary resource variables
    extern const unsigned long long _binary_R_bundle_f1_f1_1_txt_size_;
    extern const unsigned char _binary_R_bundle_f1_f1_1_txt_begin_[];

    extern const unsigned long long _binary_R_bundle_f1_f1_2_txt_size_;
    extern const unsigned char _binary_R_bundle_f1_f1_2_txt_begin_[];

    extern const unsigned long long _binary_R_bundle_f2_f21_f2_f21_1_txt_size_;
    extern const unsigned char _binary_R_bundle_f2_f21_f2_f21_1_txt_begin_[];

    extern const unsigned long long _binary_R_bundle_f2_f22_f2_f22_1_txt_size_;
    extern const unsigned char _binary_R_bundle_f2_f22_f2_f22_1_txt_begin_[];

    const _ResourcesStructure R = {
        {
            {
                Resource(&_binary_R_bundle_f1_f1_1_txt_begin_, _binary_R_bundle_f1_f1_1_txt_size_),
                Resource(&_binary_R_bundle_f1_f1_2_txt_begin_, _binary_R_bundle_f1_f1_2_txt_size_)
            },
            {
                {
                    Resource(&_binary_R_bundle_f2_f21_f2_f21_1_txt_begin_, _binary_R_bundle_f2_f21_f2_f21_1_txt_size_)
                },
                {
                    Resource(&_binary_R_bundle_f2_f22_f2_f22_1_txt_begin_, _binary_R_bundle_f2_f22_f2_f22_1_txt_size_)
                },
            },
        },
    };
}
