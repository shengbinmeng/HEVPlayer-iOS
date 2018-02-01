High Efficiency Video Player for iOS.

# Note

Build ffmpeg with [qy265dec] support:

1. Apply misc/ffmpeg-3.3.6-qy265.patch to ffmpeg source (`patch -p1 < ffmpeg-3.3.6-qy265.patch`);

2. Run misc/config-ios.sh in ffmpeg source folder to configure, then `make` and `make install`;

3. FFmpeg header files and libraries are then installed to the folder configured with "--prefix" and good to use.

The folder hierarchy required by config-ios.sh is:

	| ffmpeg source codes
	| config-ios.sh
	| qy265
		| libqycommon.a
		| libqydecoder.a
