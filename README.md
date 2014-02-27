# TS2MP4

[![Version](http://cocoapod-badges.herokuapp.com/v/TS2MP4/badge.png)](http://cocoadocs.org/docsets/TS2MP4)
[![Platform](http://cocoapod-badges.herokuapp.com/p/TS2MP4/badge.png)](http://cocoadocs.org/docsets/TS2MP4)

TS2MP4 converts a set of TS files to a MP4 file. 

## How it works
The conversion of a TS file into a MP4 file is done in two steps.

1. The first step is the demuxing of the TS files. It consist of extracting the audio and the video elementary streams of the TS files and saving them into two distinct files on the disk. (using a modified version of [tsdemux][1] 1.52 )
2. The second step is the muxing of the two elementary streams. It consist of assemble the two elementary streams into one MP4 file. (using the [libgpac][2] library as external lib, which is distributed as a GPAC4iOS Pod)

The concatenation of multiple TS files into a single MP4 file follow the same steps but the elementary streams are concatenated.

The C and C++ library are wrapped by an Objective-C interface KMMedia.

## Usage

To run the example project: clone the repo, and launch the TS2MP4 project and run the TS2MP4Demo target. You have to manually put some TS files into the ressources directory of the App to be able to test it.

## Installation

TS2MP4 is available through [CocoaPods](http://cocoapods.org), to install it simply add the following line to your Podfile:

    pod "TS2MP4"

## Authors

* Jonathan Gailliez, Keemotion s.a.
* Damien Leroy, Keemotion s.a.
* Anton Burdinuk (parts of TSDemux in /Classes/TSDemux)
* GPAC (parts of MP4Box in /Classes/MP4Mux)

## License

* TS2MP4 is distributed under the GPLv2 license. See the LICENSE file for more info.
* TSDemux (parts in /Classes/TSDemux) is distributed under the GPLv2 license.
* GPAC (parts in /Classes/MP4Mux) is distributed under the LGPLv2 license.

  [1]: http://code.google.com/p/tsdemuxer/downloads/list
  [2]: http://gpac.wp.mines-telecom.fr/