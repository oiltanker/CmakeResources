//Version 1.0.0
/*
 * This is a resource builder source file
 * Do not change as it is used to generate resources for other targets
 * If you change the source it will affect your project resources
 */

#ifndef _RESOURCES_H
#define _RESOURCES_H

namespace rc {
    struct Resource {
        const void* begin;
        const unsigned long long size;

        Resource(const void* begin, const unsigned long long size);
    };

    struct _ResourcesStructure{
        struct {
            struct {
                Resource f1_1_txt;
                Resource f1_2_txt;
            } f1;
            struct {
                struct {
                    Resource f2_f21_1_txt;
                } f21;
                struct {
                    Resource f2_f22_1_txt;
                } f22;
            } f2;
        } bundle;
    } extern const R;
}

#endif // _RESOURCES_H
