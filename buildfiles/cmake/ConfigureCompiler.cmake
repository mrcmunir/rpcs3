# Check and configure compiler options for RPCS3

if(MSVC)
	add_compile_options(/Zc:throwingNew- /constexpr:steps16777216)
	add_compile_definitions(
		_CRT_SECURE_NO_DEPRECATE=1 _CRT_NON_CONFORMING_SWPRINTFS=1 _SCL_SECURE_NO_WARNINGS=1
		NOMINMAX _ENABLE_EXTENDED_ALIGNED_STORAGE=1 _HAS_EXCEPTIONS=0)

	#TODO: Some of these could be cleaned up
	add_compile_options(/wd4805) # Comparing boolean and int
	add_compile_options(/wd4804) # Using integer operators with booleans
	add_compile_options(/wd4200) # Zero-sized array in struct/union

	# MSVC 2017 uses iterator as base class internally, causing a lot of warning spam
	add_compile_definitions(_SILENCE_CXX17_ITERATOR_BASE_CLASS_DEPRECATION_WARNING=1)

	# Increase stack limit to 8 MB
	add_link_options(/STACK:8388608,1048576)
else()
	check_cxx_compiler_flag("-march=native" COMPILER_SUPPORTS_MARCH_NATIVE)
	check_cxx_compiler_flag("-msse -msse2 -mcx16" COMPILER_X86)
	
	# Explicitly select architecture based on user input or customized defaults
	if(DEFINED ARM_TARGET_VERSION)
		if(ARM_TARGET_VERSION STREQUAL "8.0")
			set(ARM_MARCH_FLAG "-march=armv8-a+crc+simd+fp")
		elseif(ARM_TARGET_VERSION STREQUAL "8.1")
			set(ARM_MARCH_FLAG "-march=armv8.1-a")
		elseif(ARM_TARGET_VERSION STREQUAL "8.4")
			set(ARM_MARCH_FLAG "-march=armv8.4-a")
		endif()
	else()
		# Customized default logic to prioritize ARMv8.0-A on non-Apple environments
		if(APPLE)
			set(ARM_MARCH_FLAG "-march=armv8.4-a")
		else()
			set(ARM_MARCH_FLAG "-march=armv8-a+crc+simd+fp")
		endif()
	endif()

	check_cxx_compiler_flag("${ARM_MARCH_FLAG}" COMPILER_ARM)

	add_compile_options(-Wall)
	add_compile_options(-fno-exceptions)
	add_compile_options(-fstack-protector)

	if(USE_NATIVE_INSTRUCTIONS AND COMPILER_SUPPORTS_MARCH_NATIVE)
		add_compile_options(-march=native)
	elseif(COMPILER_ARM)
		add_compile_options(${ARM_MARCH_FLAG})
		
		# Print status when targeting ARMv8.0-A either by choice or by default
		if((NOT DEFINED ARM_TARGET_VERSION OR ARM_TARGET_VERSION STREQUAL "8.0") AND NOT APPLE)
			message(STATUS "Using ARMv8-a with standard extensions (+crc+simd+fp) as default")
		endif()
	elseif(COMPILER_X86)
		# Some compilers will set both X86 and ARM, so check explicitly for ARM first
		add_compile_options(-msse -msse2 -mcx16)
	endif()

	add_compile_options(-Werror=old-style-cast)
	add_compile_options(-Werror=sign-compare)
	add_compile_options(-Werror=reorder)
	add_compile_options(-Werror=return-type)
	add_compile_options(-Werror=overloaded-virtual)
	add_compile_options(-Werror=missing-noreturn)
	add_compile_options(-Werror=implicit-fallthrough)
	add_compile_options(-Wunused-parameter)
	add_compile_options(-Wignored-qualifiers)
	add_compile_options(-Wredundant-move)
	add_compile_options(-Wcast-qual)
	add_compile_options(-Wdeprecated-copy)
	add_compile_options(-Wtautological-compare)
	#add_compile_options(-Wshadow)
	#add_compile_options(-Wconversion)
	#add_compile_options(-Wpadded)
	add_compile_options(-Wempty-body)
	add_compile_options(-Wredundant-decls)
	#add_compile_options(-Weffc++)

	add_compile_options(-Wstrict-aliasing=1)
	#add_compile_options(-Wnull-dereference)

	if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
		add_compile_options(-Werror=inconsistent-missing-override)
		add_compile_options(-Werror=delete-non-virtual-dtor)
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
		add_compile_options(-Werror=suggest-override)
		add_compile_options(-Wclobbered)
		# add_compile_options(-Wcast-function-type)
		add_compile_options(-Wduplicated-branches)
		add_compile_options(-Wduplicated-cond)
	endif()

	#TODO Clean the code so these are removed
	if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
		add_compile_options(-fconstexpr-steps=16777216)
		add_compile_options(-Wno-unused-lambda-capture)
		add_compile_options(-Wno-unused-private-field)
		add_compile_options(-Wno-unused-command-line-argument)
		add_compile_options(-Wno-elaborated-enum-base)
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
		add_compile_options(-Wno-class-memaccess)
	endif()

	# Note that this refers to binary size optimization during linking, it differs from optimization compiler level
	add_link_options(-Wl,-O2)

	if(NOT APPLE AND NOT WIN32)
		# This hides our LLVM from mesa's LLVM, otherwise we get some unresolvable conflicts.
		add_link_options(-Wl,--exclude-libs,ALL)
	elseif(WIN32)
		add_compile_definitions(__STDC_FORMAT_MACROS=1)

		# Workaround for mingw64 (MSYS2)
		add_link_options(-Wl,--allow-multiple-definition)

		# Increase stack limit to 8 MB
		add_link_options(-Wl,--stack -Wl,8388608)
	endif()

	# Specify C++ library to use as standard C++ when using clang (not required on linux due to GNU)
	if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND (APPLE OR WIN32))
		add_compile_options(-stdlib=libc++)
	endif()
endif()
