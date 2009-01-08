/* EMULAB-COPYRIGHT
 * Copyright (c) 2008 University of Utah and the Flux Group.
 * All rights reserved.
 *
 * Permission to use, copy, modify and distribute this software is hereby
 * granted provided that (1) source code retains these copyright, permission,
 * and disclaimer notices, and (2) redistributions including binaries
 * reproduce the notices in supporting documentation.
 *
 * THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
 * CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
 * FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
 */

package
{
  import flash.events.ErrorEvent;
  import com.mattism.http.xmlrpc.MethodFault;

  class Util
  {
    public static function getResponse(name : String, xml : String) : String
    {
      return "\n-----------------------------------------\n"
        + "RESPONSE: " + name + "\n"
        + "-----------------------------------------\n\n"
        + xml;
    }

    public static function getSend(name : String, xml : String) : String
    {
      return "\n-----------------------------------------\n"
        + "SEND: " + name + "\n"
        + "-----------------------------------------\n\n"
        + xml;
    }

    public static function getFailure(opName : String,
                                      event : ErrorEvent,
                                      fault : MethodFault) : String
    {
      if (fault != null)
      {
        return "FAILURE fault: " + opName + ": " + fault.getFaultString()
          + "\n";
      }
      else
      {
        return "FAILURE event: " + opName + ": " + event.toString() + "\n";
      }
    }
  }
}