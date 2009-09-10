/* GENIPUBLIC-COPYRIGHT
 * Copyright (c) 2008, 2009 University of Utah and the Flux Group.
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
  public class Geni
  {
    static var sa : String = "sa";
    static var cm : String = "cm";
    static var ses : String = "ses";

    static var sesUrl : String = "https://myboss.emulab.geni.emulab.net/protogeni/xmlrpc/";
//"https://boss.emulab.net:443/protogeni/xmlrpc/";

    public static var getCredential = new Array(sa, "GetCredential");
    public static var getKeys = new Array(sa, "GetKeys");
    public static var resolve = new Array(sa, "Resolve");
    public static var remove = new Array(sa, "Remove");
    public static var register = new Array(sa, "Register");

    public static var discoverResources = new Array(cm, "DiscoverResources");
    public static var getTicket = new Array(cm, "GetTicket");
    public static var updateTicket = new Array(cm, "UpdateTicket");
    public static var redeemTicket = new Array(cm, "RedeemTicket");
    public static var releaseTicket = new Array(cm, "ReleaseTicket");
    public static var deleteSliver = new Array(cm, "DeleteSliver");
    public static var startSliver = new Array(cm, "StartSliver");
    public static var updateSliver = new Array(cm, "UpdateSliver");
    public static var resolveNode = new Array(cm, "Resolve");

    public static var map = new Array(ses, "Map");
  }
}
