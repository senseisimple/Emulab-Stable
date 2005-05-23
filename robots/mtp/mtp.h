/*
 * EMULAB-COPYRIGHT
 * Copyright (c) 2004, 2005 University of Utah and the Flux Group.
 * All rights reserved.
 */

/**
 * @file mtp.h
 *
 * Header file for the mtp library.
 *
 * @see mtp.x
 */

#ifndef __MTP_H__
#define __MTP_H__

#include <stdio.h>
#include <sys/types.h>
#include <sys/un.h>
#include <netinet/in.h>

#include "mtp_xdr.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Typedef for the mtp_packet structure generated by rpcgen(1).
 */
typedef struct mtp_packet mtp_packet_t;

enum {
    MHB_EOF,
};

enum {
    MHF_EOF = (1L << MHB_EOF),	/*< Indicates an EOF for an MTP connection. */
};

/**
 * Structure that manages an MTP connection.
 */
struct mtp_handle {
    int mh_fd;			/*< The socket connected to the MTP peer. */
    size_t mh_remaining;	/*<
				 * The number of bytes remaining in the XDR
				 * read buffers.  Be sure to clear them out
				 * before doing another select(2).  XXX
				 */
    unsigned long mh_flags;	/*< Holds any MHF flags defined above. */
    XDR mh_xdr;			/*< The xdrrec stream for this connection. */
};

/**
 * Pointer type for an mtp_handle structure.
 */
typedef struct mtp_handle *mtp_handle_t;

/**
 * Error codes for the MTP functions.
 */
typedef enum {
    MTP_PP_SUCCESS	= 0,
    MTP_PP_ERROR	= -1,
    MTP_PP_ERROR_MALLOC	= -10,
    MTP_PP_ERROR_ARGS	= -11,
    MTP_PP_ERROR_READ	= -12,
    MTP_PP_ERROR_LENGTH	= -13,
    MTP_PP_ERROR_WRITE	= -14,
    MTP_PP_ERROR_EOF	= -15
} mtp_error_t;

/**
 * Check the given packet against a series of invariants to make sure it is
 * sane.  A poorly formed packet will trigger an assert on the offending
 * constraint.
 *
 * @param packet A packet initialized by the current program.
 * @return True
 */
int mtp_packet_invariant(mtp_packet_t *packet);

/**
 * Create and initialize an mtp_handle structure.
 *
 * @param fd A socket file descriptor connected to an MTP peer.
 * @return An initialized mtp_handle object or NULL if there was error.
 */
mtp_handle_t mtp_create_handle(int fd);

/**
 * Create and initialize an mtp_handle structure.
 *
 * @param host The hostname of the server.  If NULL, the "path" parameter is
 * used.
 * @param port The port the server is listening on.
 * @param path The path of the unix-domain socket to connect to.
 * @return An initialized mtp_handle object or NULL if there was error.
 */
mtp_handle_t mtp_create_handle2(char *host, int port, char *path);

/**
 * Create and initialize an mtp_handle structure.
 *
 * @param host The hostname of the server.  If NULL, the "path" parameter is
 * used.
 * @param port The port the server is listening on.
 * @param path The path of the unix-domain socket to connect to.
 * @param nb True if the socket and connection should be non-blocking.
 * @return An initialized mtp_handle object or NULL if there was error.
 */
mtp_handle_t mtp_create_handle3(char *host, int port, char *path, int nb);

/**
 * Bind a socket to the given host/port specification.
 *
 * @see mtp_create_handle3
 *
 * @param host The hostname to bind to.  If NULL, the "path" parameter is used.
 * @param port The port number to bind to.
 * @param path The unix-domain path to bind to.
 * @return The newly created and bound socket file descriptor or -1 if there
 * was an error.
 */
int mtp_bind(char *host, int port, char *path);

/**
 * Perform a hostname lookup and fill out the given socket address structure.
 *
 * @param host_addr The socket address structure to fill out with the host and
 * port values.
 * @param host The hostname to lookup.
 * @param port The port number, in host order.
 * @return True if the lookup succeeded, false otherwise.
 */
int mtp_gethostbyname(struct sockaddr_in *host_addr, char *host, int port);

/**
 * Initialize the socket address structure with the given path.
 *
 * @param host_addr The socket address structure to fill out with the path.
 * @param path The path of the unix-domain socket.
 * @return True if the path is valid, false otherwise.
 */
int mtp_initunixpath(struct sockaddr_un *host_addr, char *path);

/**
 * Delete an initialized mtp_handle structure.
 *
 * @param mh An initialized mtp_handle object or NULL.
 */
void mtp_delete_handle(mtp_handle_t mh);

/**
 * Wait for, and demarshal, a packet from an MTP connection.
 *
 * @param mh An initialized mtp_handle on which to wait for the packet.
 * @param packet The mtp_packet object to copy the received packet to.
 * @return An mtp_error_t code.
 */
mtp_error_t mtp_receive_packet(mtp_handle_t mh, struct mtp_packet *packet);

/**
 * Marshal and send a packet over an MTP connection.
 *
 * @param mh An initialized mtp_handle on which to send the packet.
 * @param packet The mtp_packet object to marshal and send to the peer.
 * @param An mtp_error_t code.
 */
mtp_error_t mtp_send_packet(mtp_handle_t mh, struct mtp_packet *packet);

/**
 * Tags for the mtp_init_packet and mtp_send_packet2 functions.  These tags are
 * used to specify the fields of the packet that you wish to initialize.
 */
typedef enum {
    MA_TAG_DONE,	 /*< () Terminator tag. */
    MA_Opcode,	 	 /*< (mtp_opcode_t) */
    MA_Role,	 	 /*< (mtp_role_t) */
    MA_ID,	 	 /*< (int) */
    MA_Code,	 	 /*< (int) */
    MA_Message,	 	 /*< (char *) */
    MA_RobotLen,	 /*< (int) */
    MA_RobotVal,	 /*< (robot_config *) */
    MA_CameraLen,	 /*< (int) */
    MA_CameraVal,	 /*< (camera_config *) */
    MA_BoundsVal,        /*< (box *) */
    MA_BoundsLen,        /*< (int) */
    MA_ObstacleLen,	 /*< (int) */
    MA_ObstacleVal,	 /*< (obstacle_config *) */
    MA_RobotID,	 	 /*< (int) */
    MA_Position,	 /*< (robot_position *) */
    MA_X,	 	 /*< (double) */
    MA_Y,	 	 /*< (double) */
    MA_Theta,	 	 /*< (double) */
    MA_Timestamp,	 /*< (double) */
    MA_Status,	 	 /*< (mtp_status_t) */
    MA_RequestID,	 /*< (int) */
    MA_CommandID,	 /*< (int) */
    MA_GarciaTelemetry,	 /*< (mtp_garcia_telemetry *) */
    MA_WiggleType,	 /*< (mtp_wiggle_t) */
    MA_ContactPointCount,	 /*< (int) */
    MA_ContactPoints,	 /*< (contact_point *) */
    MA_Speed,		 /*< (float) */

    MA_TAG_MAX
} mtp_tag_t;

/**
 * Initialize an MTP packet to zero and then set any fields given in the
 * taglist.  The taglist consists of any number of tag/value pairs passed to
 * the function followed by the terminator tag, MA_TAG_DONE.  For example, to
 * initialize a request position packet:
 *
 * @code
 *   mtp_init_packet(&mp,
 *                   MA_Opcode, MTP_REQUEST_POSITION,
 *                   MA_Role, MTP_ROLE_RMC,
 *                   MA_RobotID, 1,
 *                   MA_TAG_DONE);
 * @endcode
 *
 * @param mp The packet to initialize.
 * @param tag The first tag in the sequence.
 * @return An mtp_error_t code.
 */
mtp_error_t mtp_init_packet(struct mtp_packet *mp, mtp_tag_t tag, ...);

/**
 * Construct, marshal, and send a packet over an MTP connection.
 *
 * @see mtp_init_packet
 *
 * @param mh An initialized mtp_handle on which to send the packet.
 * @param tag The first tag in the sequence.
 * @return An mtp_error_t code.
 */
mtp_error_t mtp_send_packet2(mtp_handle_t mh, mtp_tag_t tag, ...);

/**
 * Free any memory allocated by the XDR code when unmarshalling a packet.
 *
 * @param mp A packet received by mtp_receive_packet.
 */
void mtp_free_packet(struct mtp_packet *mp);

/**
 * Convert a given angle to be between -PI and +PI.
 *
 * @param theta The angle, in radians, to convert.
 * @return The converted angle.
 */
float mtp_theta(float theta);

/**
 * Convert a cartesian coordinate into polar coordinates relative to a given
 * origin (the "current" parameter).
 *
 * @param current The current position of the object.
 * @param dest The destination position of the object.
 * @param r_out The distance from the current position to the destination.
 * @param theta_out The angle, in radians, from the current position to the
 * destination.
 */
void mtp_polar(struct robot_position *current,
	       struct robot_position *dest,
	       float *r_out,
	       float *theta_out);

/**
 * Convert a polar coordinate relative to a given origin into a cartesian
 * coordinate.
 *
 * @param current The current position of the object.
 * @param r The distance to the destination position.
 * @param theta The angle, in radians, to the destination position.
 * @param dest_out The destination position in cartesian coordinates.
 */
void mtp_cartesian(struct robot_position *current,
		   float r,
		   float theta,
		   struct robot_position *dest_out);

/**
 * Convert a move in world coordinates into a local coordinate move.
 *
 * @param local_out The structure to fill out with the move in local
 * coordinates.
 * @param world_start The starting position/posture.
 * @param world_finish The ending position/posture.
 * @return local_out
 */
struct robot_position *mtp_world2local(struct robot_position *local_out,
				       struct robot_position *world_start,
				       struct robot_position *world_finish);

/**
 * Tags for the mtp_dispatch function.  These tags are used to describe what
 * packets to match and what to do with them.
 */
typedef enum {
    MD_TAG_DONE,	/*< Terminator tag. */

    MD_OnOpcode,	/*< (mtp_opcode_t) */
    MD_OnStatus,	/*< (mtp_status_t) */
    MD_OnWiggleType,	/*< (mtp_wiggle_t) */
    MD_OnCommandID,	/*< (int) */

    MD_Integer,		/*< (int) Specify an integer to compare against. */
    
    MD_OnInteger,	/*< (int) Check an MD_Integer. */
    MD_OnFlags,		/*< (int) Bitwise check of an MD_Integer. */
    MD_SkipInteger,	/*< (void) Skip checking an MD_Integer. */
    
    MD_Return,		/*< (void) On match, return immediately. */
    MD_Call,		/*<
			 * (mtp_dispatcher_t) On match, call function and
			 * return.
			 */
    MD_AlsoCall,	/*<
			 * (mtp_dispatcher_t) On match, call function and
			 * continue.
			 */

    MD_OR = (0x80000000)	/*<
				 * When bitwise or'd with the other tags, they
				 * become optional conditions.  Note that the
				 * last condition passed should not be or'd
				 * with this tag.  For example:
				 *
				 * @code
				 *   MD_OR | MD_OnStatus, ...,
				 *   MD_OR | MD_OnStatus, ...,
				 *   MD_OnStatus, ...,
				 * @endcode
				 */
} mtp_dispatch_tag_t;

/**
 * Type for handler functions passed to mtp_dispatch.
 *
 * @param userdata The userdata value passed to mtp_dispatch.
 * @param mp The packet to dispatch.
 */
typedef int (*mtp_dispatcher_t)(void *userdata, mtp_packet_t *mp);

/**
 * Dispatches an mtp_packet_t to one or more handler functions based on certain
 * criteria.  The function takes a large taglist that describes what packets
 * you are interested in and what functions should be called to handle them.
 * For example, to pass a packet to the do_goto and do_stop functions for the
 * corresponding packet types, you would call:
 *
 * @code
 *   mtp_distach(foo, mp,
 *
 *               MD_OnOpcode, MTP_COMMAND_GOTO,
 *               MD_Call, do_goto,
 *
 *               MD_OnOpcode, MTP_COMMAND_STOP,
 *               MD_Call, do_stop,
 *
 *               MD_TAG_DONE);
 * @endcode
 *
 * The function works by comparing any requirements against the given packet
 * (e.g. opcode == GOTO) until it reaches the MD_Call tag.  If the all of the
 * requirements are met, the handler function is called and mtp_dispatch
 * returns.  Otherwise, the next set of requirements is checked for a match.
 * If no match is found, the packet will be dumped to standard error.
 *
 * Besides the opcode, the function can also match other parts of the packet.
 * The next example passes update-position packets with an error status to the
 * "handle_error" function and everything else to the "handle_update" function.
 *
 * @code
 *   mtp_distach(foo, mp,
 *
 *               MD_OnOpcode, MTP_UPDATE_POSITION,
 *               MD_OR | MD_OnStatus, MTP_POSITION_STATUS_ERROR,
 *               MD_OnStatus, MTP_POSITION_STATUS_ABORT,
 *               MD_Call, handle_error,
 *
 *               MD_OnOpcode, MTP_UPDATE_POSITION,
 *               MD_Call, handle_update,
 *
 *               MD_TAG_DONE);
 * @endcode
 *
 * Notice the use of the MD_OR flag, which causes the function to match one
 * value or another.  Without this flag, the first MD_OnStatus would fail to
 * match and cause the function to not be called.
 *
 *
 * This is mostly just me experimenting and having fun... -tss
 *
 * @see mtp_dispatch_tag_t, mtp_dispatcher_t
 *
 * @param userdata The value to pass to any handler functions.
 * @param mp The packet to dispatch.
 * @param tag The first tag in the sequence.
 */
int mtp_dispatch(void *userdata, mtp_packet_t *mp,
		 mtp_dispatch_tag_t tag,
		 ...);

enum {
    MCB_NORTH,
    MCB_EAST,
    MCB_WEST,
    MCB_SOUTH
};

enum {
    MCF_NORTH = (1L << MCB_NORTH),
    MCF_EAST = (1L << MCB_EAST),
    MCF_WEST = (1L << MCB_WEST),
    MCF_SOUTH = (1L << MCB_SOUTH),
};

/**
 * Convert a compass bitmask containing MCF_ values into a human readable
 * string.
 *
 * @param x The compass bitmask.
 * @return A static string that represents the given compass value.
 */
#define MTP_COMPASS_STRING(x) ( \
    (x) == (MCF_NORTH|MCF_WEST) ? "nw" : \
    (x) == (MCF_NORTH) ? "n" : \
    (x) == (MCF_NORTH|MCF_EAST) ? "ne" : \
    (x) == (MCF_EAST) ? "e" : \
    (x) == (MCF_SOUTH|MCF_EAST) ? "se" : \
    (x) == (MCF_SOUTH) ? "s" : \
    (x) == (MCF_SOUTH|MCF_WEST) ? "sw" : \
    (x) == (MCF_WEST) ? "w" : "u")

/**
 * Reduce an angle in radians to a compass direction.
 *
 * @param theta The angle to reduce.
 * @return The compass bitmask made up of MCF_ values.
 */
int mtp_compass(float theta);

/**
 * Convert a relative coordinate system into absolute.
 *
 * @param _dst The destination 
 */
#define REL2ABS(_dst, _theta, _rpoint, _apoint) { \
    float _ct, _st; \
    \
    _ct = cosf(_theta); \
    _st = sinf(_theta); \
    (_dst)->x = _ct * (_rpoint)->x - _st * -(_rpoint)->y + (_apoint)->x; \
    (_dst)->y = _ct * (_rpoint)->y + _st * -(_rpoint)->x + (_apoint)->y; \
}

/**
 * Check the sanity of an obstacle object.
 *
 * @param oc An initialized obstacle structure.
 * @return true
 */
int mtp_obstacle_config_invariant(struct obstacle_config *oc);

/**
 * Print the contents of the given packet to the given FILE object.
 *
 * @param file The file to print to.
 * @param mp The initialized packet to print.
 */
void mtp_print_packet(FILE *file, struct mtp_packet *mp);

#ifndef min
#define min(x, y) (((x) < (y)) ? (x) : (y))
#endif

#ifndef max
#define max(x, y) (((x) > (y)) ? (x) : (y))
#endif

#ifndef abs
#define abs(x) (((x) < 0) ? -(x) : (x))
#endif

#ifdef __cplusplus
}
#endif

#endif
