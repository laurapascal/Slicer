set(proj HDF5)

# Set dependency list
set(${proj}_DEPENDENCIES "")

# Include dependent projects if any
ExternalProject_Include_Dependencies(${proj} PROJECT_VAR proj DEPENDS_VAR ${proj}_DEPENDENCIES)

if(${CMAKE_PROJECT_NAME}_USE_SYSTEM_${proj})
  unset(HDF5_DIR CACHE)
  find_package(HDF5 REQUIRED)
  set(HDF5_INCLUDE_DIR ${HDF5_INCLUDE_DIRS})
  set(HDF5_LIBRARY ${HDF5_LIBRARIES})
endif()

# Sanity checks
if(DEFINED HDF5_DIR AND NOT EXISTS ${HDF5_DIR})
message(FATAL_ERROR "HDF5_DIR variable is defined but corresponds to nonexistent directory")
endif()

if(NOT DEFINED HDF5_DIR AND NOT ${CMAKE_PROJECT_NAME}_USE_SYSTEM_${proj})

  if(NOT DEFINED git_protocol)
    set(git_protocol "git")
  endif()

  set(EP_SOURCE_DIR ${CMAKE_BINARY_DIR}/${proj})
  set(EP_BINARY_DIR ${CMAKE_BINARY_DIR}/${proj}-build)
  set(EP_INSTALL_DIR ${CMAKE_BINARY_DIR}/${proj}-install)

message(${EP_INSTALL_DIR})

  ExternalProject_Add(${proj}
    ${${proj}_EP_ARGS}
    SOURCE_DIR ${EP_SOURCE_DIR}
    BINARY_DIR ${EP_BINARY_DIR}
    INSTALL_DIR ${EP_INSTALL_DIR}
    URL http://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.13/src/hdf5-1.8.13.tar.gz
    UPDATE_COMMAND ""
    CMAKE_ARGS
      -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE}
      -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=OFF
      -DHDF5_BUILD_CPP_LIB:BOOL=ON
      -DBUILD_SHARED_LIBS:BOOL=OFF
      -DHDF5_BUILD_TOOLS:BOOL=OFF
      -DHDF5_BUILD_HL_LIB:BOOL=ON
      -DCMAKE_INSTALL_PREFIX:PATH=${EP_INSTALL_DIR}
      -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER}
      -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
      -DCMAKE_C_FLAGS:STRING=${ep_common_c_flags}
      -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
    DEPENDS
      ${${proj}_DEPENDENCIES}
)

set(cmake_hdf5_libs " ")
  if(WIN32)
    set( HDF5_DIR ${INSTALL_DEPENDENCIES_DIR}/cmake/hdf5/ )
    add_custom_command(
      TARGET HDF5
      POST_BUILD
        COMMAND ${CMAKE_COMMAND}
          -D INSTALL_DEPENDENCIES_DIR=${INSTALL_DEPENDENCIES_DIR}
          -P ${CMAKE_CURRENT_SOURCE_DIR}/normalize_hdf5_lib_names.cmake
      COMMENT "normalizing hdf5 library filename"
    )

    # On Windows, find_package(HDF5) with cmake 2.8.[8,9] always ends up finding
    # the dlls instead of the libs. So setting the variables explicitly for
    # dependent projects.
    set(cmake_hdf5_c_lib    -DHDF5_C_LIBRARY:FILEPATH=${EP_INSTALL_DIR}/lib/hdf5.lib)
    set(cmake_hdf5_cxx_lib  -DHDF5_CXX_LIBRARY:FILEPATH=${EP_INSTALL_DIR}/lib/hdf5_cpp.lib)
    set(cmake_hdf5_libs     ${cmake_hdf5_c_lib} ${cmake_hdf5_cxx_lib})
  else()
    set(HDF5_DIR ${EP_INSTALL_DIR}/share/cmake/hdf5/ )
  endif()
else()
  # The project is provided using HDF5_DIR, nevertheless since other project may depend on hdf5,
  # let's add an 'empty' one
  ExternalProject_Add_Empty(${proj} DEPENDS ${${proj}_DEPENDENCIES})
endif()

mark_as_superbuild(
  VARS
  HDF5_DIR:PATH
  LABELS "FIND_PACKAGE"
)

ExternalProject_Message(${proj} "HDF5_DIR:${HDF5_DIR}")
