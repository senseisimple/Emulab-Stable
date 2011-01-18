/*
 * emulab_proxy.h
 *
 * Copyright (c) 2004 The University of Utah and the Flux Group.
 * All rights reserved.
 *
 * This file is licensed under the terms of the GNU Public License.  
 * See the file "license.terms" for restrictions on redistribution 
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 */

#ifndef emulab_proxy_h
#define emulab_proxy_h

#include <xmlrpc-c/base.hpp>

#include <stdarg.h>
#include <string>
#include <xmlrpc-c/client.hpp>

namespace emulab {

/**
 * Response codes used by the Emulab server.
 */
typedef enum {
    ERC_SUCCESS = 0,	/**< Method completed successfully. */
    ERC_BADARGS,	/**< Bad arguments. */
    ERC_ERROR,		/**< There was an error while executing the method. */
    ERC_FORBIDDEN,	/**< You are forbidden from executing a method. */
    ERC_BADVERSION,	/**< The supplied version number was incorrect. */ 
    ERC_SERVERERROR,	/**< The server encountered an unrecoverable error. */
    ERC_TOOBIG,		/**< The request message is too large. */
    ERC_REFUSED,	/**< The server refused to execute the method.
			   (a temporary condition, retry later.) */

    ERC_MAX
} er_code_t;

/**
 * Class used to encode a standard response to a method.
 */
class EmulabResponse
{
 public:

    /**
     * Empty constructor.
     */
    explicit EmulabResponse() {};

    /**
     * Construct an EmulabResponse object with the given values.
     *
     * @param code The response code, indicates success or failure.
     * @param value The result of executing the method.
     * @param output The debugging output generated by the method.
     */
    EmulabResponse(const er_code_t code,
                   const xmlrpc_c::value value,
                   const xmlrpc_c::value output);

    /**
     * Construct an EmulabResponse from a ulxmlrpcpp style response.
     *
     * @param result The response to turn into an EmulabResponse.
     */
    EmulabResponse(xmlrpc_c::value result);

    /**
     * Destructor...
     */
    virtual ~EmulabResponse();

    /**
     * @return The response code, indicates success or failure.
     */
    er_code_t getCode() { return( this->er_Code ); };

    /**
     * @return The result of executing the method.
     */
    xmlrpc_c::value getValue() { return( this->er_Value ); };

    /**
     * @return The debugging output generated by the method.
     */
    xmlrpc_c::value_string getOutput() { return( (xmlrpc_c::value_string)this->er_Output ); };

    /**
     * @return True if this response indicates a successful method execution.
     */
    bool isSuccess() { return( this->er_Code == ERC_SUCCESS ); };

 private:

    /**
     * The response code, indicates success or failure.
     */
    er_code_t er_Code;
    
    /**
     * The result of executing the method.
     */
    xmlrpc_c::value er_Value;

    /**
     * The debugging output generated by the method.
     */
    xmlrpc_c::value er_Output;
    
};

/**
 * Attribute tags passed to ServerProxy::invoke.
 *
 * @sa emulab::ServerProxy
 */
typedef enum {
    SPA_TAG_DONE,	/**< Terminator tag. */
    SPA_Boolean,	/**< (const char *key, bool val) */
    SPA_Integer,	/**< (const char *key, int val) */
    SPA_Double,		/**< (const char *key, double val) */
    SPA_String,		/**< (const char *key, const char *val) */
} spa_attr_t;

class ServerProxy
{
 public:

    /**
     * Construct ServerProxy with the given values.
     *
     * @param transport The transport to use when communicating with the server.
     * @param wbxml_mode Indicate whether or not wbxml should be used.
     * @param url The url to use.
     */
	ServerProxy(xmlrpc_c::clientXmlTransport *transport,
		bool wbxml_mode = false,
		const char *url = "");

    /**
     * Destructor...
     */
    virtual ~ServerProxy();

    /**
     * Invoke an Emulab method with the given parameters.  The arguments are
     * given in a tag list, where you specify the type, parameter name, and
     * its value.  For example, the following code would get the state of the
     * experiment "bar" in project "foo":
     *
     * @code
     * sp.invoke("state",
     *           SPA_String, "proj", "foo",
     *           SPA_String, "exp", "bar",
     *           SPA_TAG_DONE);
     * @endcode
     *
     * @param method_name The name of the method to execute.
     * @param tag The tag in the list.
     */
    EmulabResponse invoke(const char *method_name, spa_attr_t tag, ...);

    /**
     * The va_list version of the invoke method.
     *
     * @param method_name The name of the method to execute.
     * @param tag The tag in the list.
     * @param args The rest of the tag list.
     */
    virtual EmulabResponse invoke(const char *method_name,
				  spa_attr_t tag,
				  va_list args);

private:
    xmlrpc_c::value call(xmlrpc_c::rpcPtr rpc);
    
    xmlrpc_c::clientXmlTransport *transport;
    std::string server_url;
};
    
}

#endif
