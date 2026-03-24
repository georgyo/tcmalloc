# Script to bundle multiple static archives into one fat archive with
# internal symbols localized (hidden). Uses ld -r for partial linking
# then objcopy to keep only exported symbols global.
#
# Expected variables:
#   ARCHIVES_FILE  - file with one archive path per line
#   OUTPUT         - output .a path
#   AR             - path to ar
#   WORKDIR        - temporary working directory
#   EXPORTED_SYMS  - file listing symbols to keep global (one per line)
cmake_minimum_required(VERSION 3.24)

file(STRINGS "${ARCHIVES_FILE}" ARCHIVES)

file(REMOVE_RECURSE "${WORKDIR}")
file(MAKE_DIRECTORY "${WORKDIR}")

# Extract all .o files from each archive into unique subdirectories
foreach(archive IN LISTS ARCHIVES)
  if("${archive}" STREQUAL "")
    continue()
  endif()
  get_filename_component(archive_name "${archive}" NAME_WE)
  set(subdir "${WORKDIR}/${archive_name}")
  file(MAKE_DIRECTORY "${subdir}")
  execute_process(
    COMMAND "${AR}" x "${archive}"
    WORKING_DIRECTORY "${subdir}"
    RESULT_VARIABLE result
  )
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "Failed to extract ${archive}")
  endif()
endforeach()

file(GLOB_RECURSE all_objects "${WORKDIR}/*.o")

# Partial link all objects into a single relocatable object
set(MERGED_OBJ "${WORKDIR}/tcmalloc_merged.o")
execute_process(
  COMMAND ld -r -o "${MERGED_OBJ}" ${all_objects}
  RESULT_VARIABLE result
)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "Partial link (ld -r) failed")
endif()

# Build objcopy arguments to keep only exported symbols global
if(EXPORTED_SYMS)
  # Read the exported symbols file, skipping comments and blanks
  file(STRINGS "${EXPORTED_SYMS}" symbols)
  set(keep_args "")
  foreach(sym IN LISTS symbols)
    # Skip comments and empty lines
    string(STRIP "${sym}" sym)
    if("${sym}" STREQUAL "" OR "${sym}" MATCHES "^#")
      continue()
    endif()
    list(APPEND keep_args "--keep-global-symbol=${sym}")
  endforeach()

  execute_process(
    COMMAND objcopy ${keep_args} "${MERGED_OBJ}"
    RESULT_VARIABLE result
  )
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "objcopy failed to localize symbols")
  endif()
endif()

# Package the merged object into an archive
execute_process(
  COMMAND "${AR}" crs "${OUTPUT}" "${MERGED_OBJ}"
  RESULT_VARIABLE result
)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "Failed to create ${OUTPUT}")
endif()

file(REMOVE_RECURSE "${WORKDIR}")
