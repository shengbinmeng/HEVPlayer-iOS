HEVPlayer is a High Efficiency Video Player.

## Build ffmpeg with lenthevcdec support

1. Apply doc/*.patch to ffmpeg(v2.4.4) source (`patch -p1 < *.patch`).

2. Run doc/config-ios.sh in ffmpeg source folder to configure, then `make` and `make install`.

3. The header files and libraries are installed to the folder configured with "--prefix" and good to use.

The folder hierarchy required by config-ios.sh is:

	| ffmpeg source codes
	| config-ios.sh
	| thirdparty
		| lenthevcdec
			| include
				| lenthevcdec.h
			| lib
				| liblenthevcdec.a