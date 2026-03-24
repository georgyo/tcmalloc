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

# Remove libstdc++ new/delete objects that conflict with tcmalloc's overrides.
# tcmalloc provides its own operator new/delete, so we must exclude libstdc++'s.
set(CONFLICTING_PATTERNS
  "new_op" "new_opnt" "new_opv" "new_opvnt"
  "new_opa" "new_opant" "new_opva" "new_opvant"
  "del_op" "del_opnt" "del_opv" "del_opvnt"
  "del_ops" "del_opvs"
  "del_opa" "del_opant" "del_opva" "del_opvant"
  "del_opsa" "del_opvsa"
)
set(filtered_objects "")
foreach(obj IN LISTS all_objects)
  get_filename_component(obj_name "${obj}" NAME_WE)
  get_filename_component(obj_parent "${obj}" DIRECTORY)
  get_filename_component(parent_name "${obj_parent}" NAME)
  set(skip FALSE)
  if(parent_name STREQUAL "libstdc++")
    foreach(pattern IN LISTS CONFLICTING_PATTERNS)
      if(obj_name STREQUAL "${pattern}")
        set(skip TRUE)
        break()
      endif()
    endforeach()
  endif()
  if(NOT skip)
    list(APPEND filtered_objects "${obj}")
  endif()
endforeach()
set(all_objects ${filtered_objects})

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
