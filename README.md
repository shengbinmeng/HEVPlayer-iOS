High Efficiency Video Player for iOS.

# Note

Build ffmpeg with [lenthevcdec](http://www.strongene.com/cn/downloads/downloadCenter.jsp) support:

1. Apply misc/*.patch to ffmpeg(v2.4.4) source (`patch -p1 < *.patch`);

2. Run misc/config-ios.sh in ffmpeg source folder to configure, then `make` and `make install`;

3. FFmpeg header files and libraries are then installed to the folder configured with "--prefix" and good to use.

The folder hierarchy required by config-ios.sh is:

	| ffmpeg source codes
	| config-ios.sh
	| thirdparty
		| lenthevcdec
			| include
				| lenthevcdec.h
			| lib
				| liblenthevcdec.a