/*
 * EMULAB-COPYRIGHT
 * Copyright (c) 2004, 2005 University of Utah and the Flux Group.
 * All rights reserved.
 */

/**
 * @file simulator-agent.cc
 *
 * Implementation file for the SIMULATOR agent.
 */

#include "config.h"

#include <stdlib.h>

#include "popenf.h"
#include "systemf.h"
#include "rpc.h"
#include "simulator-agent.h"

using namespace emulab;

/**
 * A "looper" function for the simulator agent that dequeues and processes
 * events destined for the Simulator object.  This function will be passed to
 * pthread_create when a new thread needs to be created to handle events.
 *
 * @param arg The simulator agent object to handle events for.
 * @return NULL
 *
 * @see send_report
 * @see add_report_data
 * @see local_agent_queue
 * @see local_agent_dequeue
 */
static void *simulator_agent_looper(void *arg);

/**
 * Add some message/log data that should be included in the generated report
 * for this simulator.  The data is appended to any previous additions along
 * with a newline if it does not have one.
 *
 * @param sa The simulator agent object where the data is kept.
 * @param rdk The type of data being added.
 * @param data The data to add, should just be ASCII text.
 * @return Zero on success, -1 otherwise.
 *
 * @see send_report
 */
static int add_report_data(simulator_agent_t sa,
			   sa_report_data_kind_t rdk,
			   char *data);

/**
 * Sends a summary report to the user via e-mail and also sort of marks the end
 * of a run of the experiment.  The content of the report is partially
 * generated by the user with the rest being automatically generated by the
 * testbed.  First, the function will sync the logholes so any data needed to
 * automatically generate parts of the report are readily available.  Then, the
 * body of the mail is constructed by appending any user provided messages and
 * log data with the digested error records.  Ideally, the user provided
 * messages should provide a human readable summary of the success/failure of
 * their experiment.  Any log data from the user should report any performance
 * metrics, warnings, or any other salient data.  Finally, the function will
 * iterate through the list of error records and append any available log files
 * or messages paired with those records.
 *
 * After sending the mail, the simulator object will be reset to a pristine
 * state so another experimental run can begin with a clean slate.
 *
 * @param sa The simulator agent object to summarize.
 * @return Zero on success, -1 otherwise.
 *
 * @see dump_error_records
 */
static int send_report(simulator_agent_t sa);

simulator_agent_t create_simulator_agent(void)
{
	simulator_agent_t sa, retval;

	if ((sa = (simulator_agent_t)
	     malloc(sizeof(struct _simulator_agent))) == NULL) {
		retval = NULL;
		errno = ENOMEM;
	}
	else if (local_agent_init(&sa->sa_local_agent) != 0) {
		retval = NULL;
	}
	else {
		int lpc;
		
		sa->sa_local_agent.la_looper = simulator_agent_looper;
		lnNewList(&sa->sa_error_records);
		for (lpc = 0; lpc < SA_RDK_MAX; lpc++)
			sa->sa_report_data[lpc] = NULL;
		
		retval = sa;
		sa = NULL;
	}

	free(sa);
	sa = NULL;

	return retval;
}

int simulator_agent_invariant(simulator_agent_t sa)
{
	assert(sa != NULL);
	assert(local_agent_invariant(&sa->sa_local_agent));
	lnCheck(&sa->sa_error_records);
	
	return 1;
}

static int add_report_data(simulator_agent_t sa,
			   sa_report_data_kind_t rdk,
			   char *data)
{
	char *new_data;
	int retval;

	assert(sa != NULL);
	assert(rdk >= 0);
	assert(rdk < SA_RDK_MAX);
	assert(data != NULL);

	if ((new_data = (char *)realloc(sa->sa_report_data[rdk],
					((sa->sa_report_data[rdk] != NULL) ?
					 strlen(sa->sa_report_data[rdk]) : 0) +
					strlen(data) +
					1 +
					1)) == NULL) {
		retval = -1;
		errno = ENOMEM;
	}
	else {
		if (sa->sa_report_data[rdk] == NULL)
			new_data[0] = '\0'; // Need to clear the fresh malloc.
		sa->sa_report_data[rdk] = new_data;
		
		strcat(sa->sa_report_data[rdk], data);
		if (data[strlen(data) - 1] != '\n')
			strcat(sa->sa_report_data[rdk], "\n");
		
		retval = 0;
	}
	
	return retval;
}

static int remap_experiment(simulator_agent_t sa, int token)
{
	char nsfile[BUFSIZ];
	EmulabResponse er;
	int retval;

	rename("tbdata/feedback_data.tcl",
	       "tbdata/feedback_data_old.tcl");
	snprintf(nsfile, sizeof(nsfile),
		 "/proj/%s/exp/%s/tbdata/%s-modify.ns",
		 pid, eid, eid);
	if (access(nsfile, R_OK) == -1) {
		snprintf(nsfile, sizeof(nsfile),
			 "/proj/%s/exp/%s/tbdata/%s.ns",
			 pid, eid, eid);
	}
	RPC_grab();
	retval = RPC_invoke("experiment.modify",
			&er,
			SPA_String, "proj", pid,
			SPA_String, "exp", eid,
			SPA_Boolean, "wait", true,
			SPA_Boolean, "reboot", true,
			SPA_Boolean, "restart_eventsys", true,
			SPA_String, "nsfilepath", nsfile,
			SPA_TAG_DONE);
	RPC_drop();

	if (retval != 0) {
		rename("tbdata/feedback_data.tcl",
		       "tbdata/feedback_data_failed.tcl");
		rename("tbdata/feedback_data_old.tcl",
		       "tbdata/feedback_data.tcl");
	}

	return retval;
}

static int do_modify(simulator_agent_t sa, int token, char *args)
{
	int rc, retval = 0;
	char *mode;

	assert(sa != NULL);
	assert(args != NULL);
	
	if ((rc = event_arg_get(args, "MODE", &mode)) <= 0) {
		error("no mode specified\n");
	}
	else if (strncasecmp("stabilize", mode, rc) == 0) {
		if (systemf("loghole --port=%d --quiet sync",
			    DEFAULT_RPC_PORT) != 0) {
			error("failed to sync log holes\n");
		}
		else if (systemf("feedbacklogs %s %s", pid, eid) != 0) {
			if (sa->sa_flags & SAF_STABLE) {
				/* XXX log error */
				warning("unstabilized!\n");
			}
			else {
				retval = remap_experiment(sa, token);
			}
		}
		else {
			info("stabilized\n");
			sa->sa_flags |= SAF_STABLE;
		}
	}
	else {
		warning("unknown mode %s\n", mode);
	}

	return retval;
}

static void dump_report_data(FILE *file,
			     simulator_agent_t sa,
			     sa_report_data_kind_t srdk)
{
	assert(file != NULL);
	assert(sa != NULL);
	assert(srdk >= 0);
	assert(srdk < SA_RDK_MAX);

	if ((sa->sa_report_data[srdk] != NULL) &&
	    (strlen(sa->sa_report_data[srdk]) > 0)) {
		fprintf(file, "\n%s\n", sa->sa_report_data[srdk]);
		free(sa->sa_report_data[srdk]);
		sa->sa_report_data[srdk] = NULL;
	}
}

static int send_report(simulator_agent_t sa, char *args)
{
	struct lnList error_records;
	int retval;
	FILE *file;

	assert(sa != NULL);
	assert(args != NULL);
	
	/*
	 * Atomically move the error records from the agent object onto our
	 * local list and make the agent's list empty.
	 */
	if (pthread_mutex_lock(&sa->sa_local_agent.la_mutex) != 0)
		assert(0);
	lnMoveList(&error_records, &sa->sa_error_records);

	assert(lnEmptyList(&sa->sa_error_records));
	if (pthread_mutex_unlock(&sa->sa_local_agent.la_mutex) != 0)
		assert(0);

	/*
	 * Get the logs off the nodes so we can generate summaries from the
	 * error records.
	 */
	if (systemf("loghole --port=%d --quiet sync", DEFAULT_RPC_PORT) != 0) {
		error("failed to sync log holes\n");
	}
	
	if ((file = popenf("mail -s \"%s: %s experiment report\" %s",
			   "w",
			   OURDOMAIN,
			   pideid,
			   getenv("USER"))) == NULL) {
		errorc("could not execute send report\n");
		retval = -1;
	}
	else {
		char *digester;
		int rc, lpc;
		FILE *dfile;
		
		retval = 0;

		/* Dump user supplied stuff first, */
		dump_report_data(file, sa, SA_RDK_MESSAGE);

		/* ... run the user-specified log digester, then */
		if ((rc = event_arg_get(args, "DIGESTER", &digester)) > 0) {
			digester[rc] = '\0';

			if ((dfile = popenf("%s | tee logs/digest.out",
					    "r",
					    digester)) == NULL) {
				fprintf(file,
					"[failed to run digester %s]\n",
					digester);
			}
			else {
				char buf[BUFSIZ];
				
				while ((rc = fread(buf,
						   1,
						   sizeof(buf),
						   dfile)) > 0) {
					fwrite(buf, 1, rc, file);
				}
				pclose(dfile);
				dfile = NULL;
			}

			fprintf(file, "\n");
		}
		
		if ((dfile = popenf("loghole --port=%d --quiet archive",
				    "r",
				    DEFAULT_RPC_PORT)) == NULL) {
			error("failed to archive log holes\n");
		}
		else {
			char buf[BUFSIZ];

			fgets(buf, sizeof(buf), dfile);
			pclose(dfile);
			dfile = NULL;

			fprintf(file, "loghole-archive: %s\n\n", buf);
		}
		
		dump_report_data(file, sa, SA_RDK_LOG);
		
		/* ... dump the error records. */
		if (dump_error_records(&error_records, file) != 0) {
			errorc("dump_error_records failed");
			retval = -1;
		}
		
		if (pclose(file) == -1) {
			errorc("pclose failed for report mail");
		}
		file = NULL;
	}
	delete_error_records(&error_records);

	assert(lnEmptyList(&error_records));
	
	return retval;
}

static void *simulator_agent_looper(void *arg)
{
	simulator_agent_t sa = (simulator_agent_t)arg;
	event_handle_t handle;
	void *retval = NULL;
	sched_event_t se;
	
	assert(arg != NULL);

	handle = sa->sa_local_agent.la_handle;

	while (local_agent_dequeue(&sa->sa_local_agent, 0, &se) == 0) {
		char evtype[TBDB_FLEN_EVEVENTTYPE];
		char argsbuf[BUFSIZ];

		assert(se.length == 1);
		
		if (!event_notification_get_eventtype(
			handle, se.notification, evtype, sizeof(evtype))) {
			error("couldn't get event type from notification %p\n",
			      se.notification);
		}
		else {
			int rc = 0, token = ~0;
			
			event_notification_get_arguments(handle,
							 se.notification,
							 argsbuf,
							 sizeof(argsbuf));
			event_notification_get_int32(handle,
						     se.notification,
						     "TOKEN",
						     (int32_t *)&token);
			argsbuf[sizeof(argsbuf) - 1] = '\0';

			if (strcmp(evtype, TBDB_EVENTTYPE_SWAPOUT) == 0) {
				EmulabResponse er;
				
				RPC_grab();
				RPC_invoke("experiment.swapexp",
					   &er,
					   SPA_String, "proj", pid,
					   SPA_String, "exp", eid,
					   SPA_String, "direction", "out",
					   SPA_TAG_DONE);
				RPC_drop();
			}
			else if (strcmp(evtype, TBDB_EVENTTYPE_MODIFY) == 0) {
				do_modify(sa, token, argsbuf);
			}
			else if (strcmp(evtype, TBDB_EVENTTYPE_HALT) == 0) {
				rc = systemf("endexp %s %s", pid, eid);
			}
			else if (strcmp(evtype, TBDB_EVENTTYPE_DEBUG) == 0) {
				fprintf(stderr, "debug: %s\n", argsbuf);
			}
			else if (strcmp(evtype, TBDB_EVENTTYPE_MESSAGE) == 0) {
				fprintf(stderr, "msg: %s\n", argsbuf);
				add_report_data(sa, SA_RDK_MESSAGE, argsbuf);
			}
			else if (strcmp(evtype, TBDB_EVENTTYPE_LOG) == 0) {
				fprintf(stderr, "log: %s\n", argsbuf);
				add_report_data(sa, SA_RDK_LOG, argsbuf);
			}
			else if (strcmp(evtype, TBDB_EVENTTYPE_REPORT) == 0) {
				send_report(sa, argsbuf);
			}
			else {
				error("cannot handle SIMULATOR event %s.",
				      evtype);
			}
			event_do(handle,
				 EA_Experiment, pideid,
				 EA_Type, TBDB_OBJECTTYPE_SIMULATOR,
				 EA_Name, sa->sa_local_agent.la_link.ln_Name,
				 EA_Event, TBDB_EVENTTYPE_COMPLETE,
				 EA_ArgInteger, "ERROR", rc != 0,
				 EA_ArgInteger, "CTOKEN", token,
				 EA_TAG_DONE);
		}

		sched_event_free(handle, &se);
	}

	return retval;
}
