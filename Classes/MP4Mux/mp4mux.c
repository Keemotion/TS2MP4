/*
 *			GPAC - Multimedia Framework C SDK
 *
 *			Authors: Jean Le Feuvre
 *          Modified by: Gailliez Jonathan
 *                       Damien Leroy
 *			Copyright (c) Telecom ParisTech 2000-2012
 *					All rights reserved
 *
 *  This file is part of GPAC / mp4box application
 *
 *  GPAC is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  GPAC is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; see the file COPYING.  If not, write to
 *  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */


#include "mp4mux.h"

#include <gpac/download.h>
#include <gpac/network.h>

#include <gpac/fileimport.h>

#ifndef GPAC_DISABLE_SMGR
    #include <gpac/scene_manager.h>
#endif

#ifdef GPAC_DISABLE_ISOM
    #error "Cannot compile MP4Box if GPAC is not built with ISO File Format support"
#else
    #if defined(WIN32) && !defined(_WIN32_WCE)
    #include <io.h>
    #include <fcntl.h>
    #endif

    #include <gpac/media_tools.h>

    /*RTP packetizer flags*/
    #ifndef GPAC_DISABLE_STREAMING
        #include <gpac/ietf.h>
    #endif

    #ifndef GPAC_DISABLE_MCRYPT
    #include <gpac/ismacryp.h>
    #endif

    #include <gpac/constants.h>
    #include <gpac/internal/mpd.h>
    #include <time.h>
    #define BUFFSIZE	8192
#endif

Bool keep_sys_tracks = (Bool)0;
u32 swf_flags = 0;
Float swf_flatten_angle = 0;

void scene_coding_log(void *cbk, u32 log_level, u32 log_tool, const char *fmt, va_list vlist)
{
	FILE *logs = (FILE *)cbk;
	if (log_tool != GF_LOG_CODING) return;
    vfprintf(logs, fmt, vlist);
	fflush(logs);
}

/*return value:
	0: not supported
	1: ISO media
	2: input bt file (.bt, .wrl)
	3: input XML file (.xmt)
	4: input SVG file (.svg)
	5: input SWF file (.swf)
	6: input LASeR file (.lsr or .saf)
*/
u32 get_file_type_by_ext(char *inName)
{
	u32 type = 0;
	char *ext = strrchr(inName, '.');
	if (ext) {
		char *sep;
		if (!strcmp(ext, ".gz")) ext = strrchr(ext-1, '.');
		ext+=1;
		sep = strchr(ext, '.');
		if (sep) sep[0] = 0;

		if (!stricmp(ext, "mp4") || !stricmp(ext, "3gp") || !stricmp(ext, "mov") || !stricmp(ext, "3g2") || !stricmp(ext, "3gs")) type = 1;
		else if (!stricmp(ext, "bt") || !stricmp(ext, "wrl") || !stricmp(ext, "x3dv")) type = 2;
		else if (!stricmp(ext, "xmt") || !stricmp(ext, "x3d")) type = 3;
		else if (!stricmp(ext, "lsr") || !stricmp(ext, "saf")) type = 6;
		else if (!stricmp(ext, "svg")) type = 4;
		else if (!stricmp(ext, "xsr")) type = 4;
		else if (!stricmp(ext, "xml")) type = 4;
		else if (!stricmp(ext, "swf")) type = 5;
		else if (!stricmp(ext, "jp2")) {
			if (sep) sep[0] = '.';
			return 0;
		}
		else type = 0;

		if (sep) sep[0] = '.';
	}


	/*try open file in read mode*/
	if (!type && gf_isom_probe_file(inName)) type = 1;
	return type;
}



static void check_media_profile(GF_ISOFile *file, u32 track)
{
	u8 PL;
	GF_M4ADecSpecInfo dsi;
	GF_ESD *esd = gf_isom_get_esd(file, track, 1);
	if (!esd) return;

	switch (esd->decoderConfig->streamType) {
	case 0x04:
		PL = gf_isom_get_pl_indication(file, GF_ISOM_PL_VISUAL);
		if (esd->decoderConfig->objectTypeIndication==GPAC_OTI_VIDEO_MPEG4_PART2) {
			GF_M4VDecSpecInfo dsi;
			gf_m4v_get_config(esd->decoderConfig->decoderSpecificInfo->data, esd->decoderConfig->decoderSpecificInfo->dataLength, &dsi);
			if (dsi.VideoPL > PL) gf_isom_set_pl_indication(file, GF_ISOM_PL_VISUAL, dsi.VideoPL);
		} else if ((esd->decoderConfig->objectTypeIndication==GPAC_OTI_VIDEO_AVC) || (esd->decoderConfig->objectTypeIndication==GPAC_OTI_VIDEO_SVC)) {
			gf_isom_set_pl_indication(file, GF_ISOM_PL_VISUAL, 0x15);
		} else if (!PL) {
			gf_isom_set_pl_indication(file, GF_ISOM_PL_VISUAL, 0xFE);
		}
		break;
	case 0x05:
		PL = gf_isom_get_pl_indication(file, GF_ISOM_PL_AUDIO);
		switch (esd->decoderConfig->objectTypeIndication) {
		case GPAC_OTI_AUDIO_AAC_MPEG2_MP:
		case GPAC_OTI_AUDIO_AAC_MPEG2_LCP:
		case GPAC_OTI_AUDIO_AAC_MPEG2_SSRP:
		case GPAC_OTI_AUDIO_AAC_MPEG4:
			gf_m4a_get_config(esd->decoderConfig->decoderSpecificInfo->data, esd->decoderConfig->decoderSpecificInfo->dataLength, &dsi);
			if (dsi.audioPL > PL) gf_isom_set_pl_indication(file, GF_ISOM_PL_AUDIO, dsi.audioPL);
			break;
		default:
			if (!PL) gf_isom_set_pl_indication(file, GF_ISOM_PL_AUDIO, 0xFE);
		}
		break;
	}
	gf_odf_desc_del((GF_Descriptor *) esd);
}

void remove_systems_tracks(GF_ISOFile *file)
{
	u32 i, count;

	count = gf_isom_get_track_count(file);
	if (count==1) return;

	/*force PL rewrite*/
	gf_isom_set_pl_indication(file, GF_ISOM_PL_VISUAL, 0);
	gf_isom_set_pl_indication(file, GF_ISOM_PL_AUDIO, 0);
	gf_isom_set_pl_indication(file, GF_ISOM_PL_OD, 1);	/*the lib always remove IOD when no profiles are specified..*/

	for (i=0; i<gf_isom_get_track_count(file); i++) {
		switch (gf_isom_get_media_type(file, i+1)) {
		case GF_ISOM_MEDIA_VISUAL:
		case GF_ISOM_MEDIA_AUDIO:
		case GF_ISOM_MEDIA_TEXT:
		case GF_ISOM_MEDIA_SUBT:
			gf_isom_remove_track_from_root_od(file, i+1);
			check_media_profile(file, i+1);
			break;
		/*only remove real systems tracks (eg, delaing with scene description & presentation)
		but keep meta & all unknown tracks*/
		case GF_ISOM_MEDIA_SCENE:
			switch (gf_isom_get_media_subtype(file, i+1, 1)) {
			case GF_ISOM_MEDIA_DIMS:
				gf_isom_remove_track_from_root_od(file, i+1);
				continue;
			default:
				break;
			}
		case GF_ISOM_MEDIA_OD:
		case GF_ISOM_MEDIA_OCR:
		case GF_ISOM_MEDIA_MPEGJ:
			gf_isom_remove_track(file, i+1);
			i--;
			break;
		default:
			break;
		}
	}
	/*none required*/
	if (!gf_isom_get_pl_indication(file, GF_ISOM_PL_AUDIO)) gf_isom_set_pl_indication(file, GF_ISOM_PL_AUDIO, 0xFF);
	if (!gf_isom_get_pl_indication(file, GF_ISOM_PL_VISUAL)) gf_isom_set_pl_indication(file, GF_ISOM_PL_VISUAL, 0xFF);

	gf_isom_set_pl_indication(file, GF_ISOM_PL_OD, 0xFF);
	gf_isom_set_pl_indication(file, GF_ISOM_PL_SCENE, 0xFF);
	gf_isom_set_pl_indication(file, GF_ISOM_PL_GRAPHICS, 0xFF);
	gf_isom_set_pl_indication(file, GF_ISOM_PL_INLINE, 0);
}

int assemble_elementary_streams(char *left_stream, char *right_stream, char *output_file, double import_fps) {
    u32 level = GF_LOG_DEBUG;

    gf_log_set_tool_level(GF_LOG_CONTAINER, level);
    gf_log_set_tool_level(GF_LOG_SCENE, level);
    gf_log_set_tool_level(GF_LOG_PARSER, level);
    gf_log_set_tool_level(GF_LOG_AUTHOR, level);
    gf_log_set_tool_level(GF_LOG_CODING, level);

    /*
    1 - cannot open destination file
    2 - cannot import stream
    3 - cannot write file
    */

    int force_new = 1;
    int do_flat = 0;
    char *inName = output_file;
    char *outName = NULL;
    char *tmpdir = NULL;

    GF_ISOFile *file;
    GF_Err e;
    GF_Err error_left_stream;
    GF_Err error_right_stream;
    u32 import_flags = 0;

    u32 agg_samples = 0;
    u32 old_interleave = 0;
    Double interleaving_time = 0.0;

    u8 open_mode = GF_ISOM_OPEN_EDIT;
    if (force_new) {
        open_mode = (do_flat) ? GF_ISOM_OPEN_WRITE : GF_ISOM_WRITE_EDIT;
    } else {
        FILE *test = gf_f64_open(inName, "rb");
        if (!test) {
            open_mode = (do_flat) ? GF_ISOM_OPEN_WRITE : GF_ISOM_WRITE_EDIT;
            if (!outName) outName = inName;
        } else {
            fclose(test);
            if (! gf_isom_probe_file(inName) ) {
                open_mode = (do_flat) ? GF_ISOM_OPEN_WRITE : GF_ISOM_WRITE_EDIT;
                if (!outName) outName = inName;
            }
        }
    }

    file = gf_isom_open(inName, open_mode, tmpdir);
    if (!file) {
#ifdef VERBOSE
        fprintf(stderr, "Cannot open destination file %s: %s\n", inName, gf_error_to_string(gf_isom_last_error(NULL)) );
#endif
        return 1;
    }

    /*
    FOR elementary streams
    */
    error_left_stream = import_file(file, left_stream, import_flags, import_fps, agg_samples);
    error_right_stream = import_file(file, right_stream, import_flags, import_fps, agg_samples);
    
    if (error_left_stream && error_right_stream) {
#ifdef VERBOSE
        fprintf(stderr, "Cannot import video AND audio streams %s: %s\n", inName, gf_error_to_string(gf_isom_last_error(NULL)) );
#endif
        return 2;
    }

    /*
    FOR transport streams (ts files)
    e = cat_isomedia_file(file, left_stream, import_flags, import_fps, agg_samples, tmpdir, 1, 1, GF_TRUE);
    e = cat_isomedia_file(file, right_stream, import_flags, import_fps, agg_samples, tmpdir, 1, 1, GF_TRUE);
    */

    /*unless explicitly asked, remove all systems tracks*/
    if (!keep_sys_tracks) {
        remove_systems_tracks(file);
    }


    e = gf_isom_make_interleave(file, interleaving_time);
    if (!e && !old_interleave) e = gf_isom_set_storage_mode(file, GF_ISOM_STORE_DRIFT_INTERLEAVED);


    if (outName) {
#ifdef VERBOSE
        fprintf(stderr, "Saving to %s: ", output_file);
#endif
        gf_isom_set_final_name(file, output_file);
    } else {
#ifdef VERBOSE
        fprintf(stderr, "Saving %s: ", inName);
#endif
    }

    e = gf_isom_close(file);
    if (e) {
#ifdef VERBOSE
        fprintf(stderr, "Cannot import right stream %s: %s\n", inName, gf_error_to_string(gf_isom_last_error(NULL)) );
#endif
        return 3;
    }

	return 0;
}
