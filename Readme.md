# CmakeResources

## Usage:

### Main `ResourcesLists` file
CmakeResporces works by reading resource configuration files named 'ResourcesLists.txt'. The main ResourcesLists file should be located in the CMake source directory. It shold contain all resource bundle defenitions, a resource bundle defenition should be as folows:
```YAML
    <bundle_name>:
      description: <bundle_description>
      directory: <bundle_directory>
```
- Name must follow CMake target naming limitations
- Description can be any string, treat it as a comment
- Directory must be a bundle directory, all bundle resource files/folders should be in this directory, as well as, bundle ResourcesLists file.
- Name tag shold not be indented and `description` and `directory` tags should be indented by 2 spaces, not less, not more.

### Bundle `ResourcesLists` file
Bundle ResourcesLists file should be as follows:
```YAML
    directories:
      <dir_1>
      [<dir_2>]
      [...]
    masks:
      <mask_1>
      [<mask_2>]
      [...]
    excludes:
      [<regex_1>]
      [...]
```
- Under `directories` tag search directory paths are specified. These are directories whose resource files will be indexed. All paths that begin with `./` will be treated as relative to the bundle direcory. If you want only to specify bundle direcory a path of `.` can be added.
- Under `masks` tag globbing expressions are specified. These expressions will glob files in all of search directories. If you want only to glob all files a mask of `*` cab be added.
- Under `excludes` tag regex expressions are specified. If one of defined expressions matches the file path, such file will be excluded from bundle. This tag can have no values.
- When indenting lines, all indentation should strictly follow example.

> **Note** that all file paths should not contain `| ? * < \" > ;` symbols and all non `[a-zA-Z0-9]` symbols will be replaced by `_` symbol when indexed (does not affect original files).

### Executing indexing
To index bundles a CmakeResporces script should be included into main CMakeLists file and somewhere in the main CMakeLists file a call to the `indexResources` function should be made.

### Assigning bundles
To add bundle to the executable or library a call to the `assignBundle` function should be made. Function accepts two arguments which are CMake target and a bundle name:
```cmake
    assignBundle(TARGET <target> BUNDLE <bundle_name>)
```
After configuration a 'resources.h' header file will be generated and added to the targets includes which can consequently be included in the code.

> **Note** that only one bundle can be added to the one target.

### Coding
After everything is configured and resources header file is included into the code. Everything is enclosed into `rc` namespace. All resource files are represented in the resource structure by size and begin varables.
```c++
    struct Resource {
        const void* begin;
        const unsigned long long size;
    
        Resource(const void* begin, const unsigned long long size);
    };
```
Every resource can be accessed from the bundle resource structure, for example:
```c++
    const rc::Resource& res = rc::R.<category_name>.<filename>;
```
Here `R` is the bundle resources root, `<category_name>` is name of sub-folder in the bundle directory. If file is nested more than one sub-folder deep, several `<category_name>`'s must be referenced by `.` before file can be referenced. Consider following example:

    <bundle_directory>
    ├─ file_1
    ├─ folder_1
    │  ├─ file_2
    │  └─ file_3
    └─ folder_2
        └─ folder_3
            └─ file_4

Would translate into:
```c++
    struct _ResourcesStructure{
        struct {
            Resource file_1;
            struct {
                Resource file_2;
                Resource file_3;
            } folder_1;
            struct {
                struct {
                    Resource file_4;
                } folder_3;
            } folder_2;
        } bundle;
    } extern const R;
```
So all the files, when referenced would look like:
```c++
    const rc::Resource& file_1 = rc::R.file_1;
    const rc::Resource& file_2 = rc::R.folder_1.file_2;
    const rc::Resource& file_3 = rc::R.folder_1.file_3;
    const rc::Resource& file_4 = rc::R.folder_2.folder_3.file_4;
```