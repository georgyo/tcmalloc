# Script to bundle multiple static archives into one fat archive.
# Expected variables: ARCHIVES_FILE (file with one archive path per line),
#                     OUTPUT, AR, WORKDIR
cmake_minimum_required(VERSION 3.24)

file(STRINGS "${ARCHIVES_FILE}" ARCHIVES)

file(REMOVE_RECURSE "${WORKDIR}")
file(MAKE_DIRECTORY "${WORKDIR}")

foreach(archive IN LISTS ARCHIVES)
  if("${archive}" STREQUAL "")
    continue()
  endif()
  # Use a unique subdirectory per archive to avoid .o filename collisions
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
execute_process(
  COMMAND "${AR}" crs "${OUTPUT}" ${all_objects}
  RESULT_VARIABLE result
)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "Failed to create ${OUTPUT}")
endif()

file(REMOVE_RECURSE "${WORKDIR}")
