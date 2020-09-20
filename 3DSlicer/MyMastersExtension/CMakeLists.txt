cmake_minimum_required(VERSION 3.5)

project(MyMastersExtension)

#-----------------------------------------------------------------------------
# Extension meta-information
set(EXTENSION_HOMEPAGE "http://slicer.org/slicerWiki/index.php/Documentation/Nightly/Extensions/MyMastersExtension")
set(EXTENSION_CATEGORY "Segmentation Example")
set(EXTENSION_CONTRIBUTORS "Piotr Zakowski (-)")
set(EXTENSION_DESCRIPTION "This is an example of a segmentation extension.")
set(EXTENSION_ICONURL "http://www.example.com/Slicer/Extensions/MyMastersExtension.png")
set(EXTENSION_SCREENSHOTURLS "http://www.example.com/Slicer/Extensions/MyMastersExtension/Screenshots/1.png")
set(EXTENSION_DEPENDS "NA") # Specified as a space separated string, a list or 'NA' if any

#-----------------------------------------------------------------------------
# Extension dependencies
find_package(Slicer REQUIRED)
include(${Slicer_USE_FILE})

#-----------------------------------------------------------------------------
# Extension modules
add_subdirectory(Segmentation_Caller)
## NEXT_MODULE

#-----------------------------------------------------------------------------
include(${Slicer_EXTENSION_GENERATE_CONFIG})
include(${Slicer_EXTENSION_CPACK})
