#!/usr/bin/perl -w

#
# EMULAB-LGPL
# Copyright (c) 2000-2010 University of Utah and the Flux Group.
# All rights reserved.
#

#
# library of functions to manipulate the Apcon layer 1 switch by CLI
#
package apcon_clilib;

use Exporter;
@ISA = ("Exporter");
@EXPORT = qw( create_expect_object
              parse_connections
              parse_names
              parse_classes
              parse_zones
              parse_class_ports
              parse_zone_ports
              get_raw_output
              get_all_vlans
              get_port_vlan
              get_vlan_ports
              get_vlan_connections
              add_cls
              add_zone
              add_class_ports
              connect_multicast
              connect_duplex
              connect_simplex
              create_vlan
              add_vlan_ports
              unname_ports
              disconnect_ports
              remove_vlan
              port_control);

use strict;

$| = 1;

use English;
use Expect;

# some constants
my $APCON_SSH_CONN_STR = "ssh -l admin apcon1";

# This seems to be a bad practice... It will be better if we cancel 
# the password on the switch.
my $APCON1_PASSWD = "daApcon!";
my $CLI_PROMPT = "apcon1>> ";
my $CLI_UNNAMED_PATTERN = "[Uu]nnamed";
my $CLI_UNNAMED_NAME = "unnamed";
my $CLI_NOCONNECTION = "A00";
my $CLI_TIMEOUT = 10000;

# commands to show something
my $CLI_SHOW_CONNECTIONS = "show connections raw\r";
my $CLI_SHOW_PORT_NAMES  = "show port names *\r";

# mappings from port control command to CLI command
my %portCMDs =
(
    "enable" => "00",
    "disable"=> "00",
    "1000mbit"=> "9f",
    "100mbit"=> "9b",
    "10mbit" => "99",
    "auto"   => "00",
    "full"   => "94",
    "half"   => "8c",
    "auto1000mbit" => "9c",
    "full1000mbit" => "94",
    "half1000mbit" => "8c",
    "auto100mbit"  => "9a",
    "full100mbit"  => "92",
    "half100mbit"  => "8a",
    "auto10mbit"   => "99",
    "full10mbit"   => "91",
    "half10mbit"   => "89",
);


#
# Create an Expect object that spawns the ssh process 
# to switch.
#
sub create_expect_object()
{
    # default connection string:
    my $spawn_cmd = $APCON_SSH_CONN_STR;
    if ( @_ ) {
	$spawn_cmd = shift @_;
    }

    # Create Expect object and initialize it:
    my $exp = new Expect();
    $exp->raw_pty(0);
    $exp->log_stdout(0);
    $exp->spawn($spawn_cmd)
	or die "Cannot spawn $spawn_cmd: $!\n";
    $exp->expect($CLI_TIMEOUT,
		 ["admin\@apcon1's password:" => sub { my $e = shift;
						       $e->send($APCON1_PASSWD."\n");
						       exp_continue;}],
		 ["Permission denied (password)." => sub { die "Password incorrect!\n";} ],
		 [ timeout => sub { die "Timeout when connect to switch!\n";} ],
		 $CLI_PROMPT );
    return $exp;
}


#
# parse the connection output
# return two hashes for query from either direction
#
sub parse_connections($) 
{
    my $raw = shift;

    my @lines = split( /\n/, $raw );
    my %dst = ();
    my %src = ();

    foreach my $line ( @lines ) {
	if ( $line =~ /^([A-I][0-9]{2}):\s+([A-I][0-9]{2})\W*$/ ) {
	    if ( $2 ne $CLI_NOCONNECTION ) {
		$src{$1} = $2;
		if ( ! (exists $dst{$2}) ) {
		    $dst{$2} = {};
		}

		$dst{$2}{$1} = 1;
	    }
	}
    }

    return (\%src, \%dst);
}


#
# parse the port names output
# return the port => name hashtable
#
sub parse_names($)
{
    my $raw = shift;

    my %names = ();

    foreach ( split ( /\n/, $raw ) ) {
	if ( /^([A-I][0-9]{2}):\s+(\w+)\W*/ ) {
	    if ( $2 !~ /$CLI_UNNAMED_PATTERN/ ) {
		$names{$1} = $2;
	    }
	}
    }

    return \%names;
}


#
# parse the show classes output
# return the classname => 1 hashtable, not a list.
#
sub parse_classes($)
{
    my $raw = shift;
    
    my %clses = ();

    foreach ( split ( /\n/, $raw ) ) {
	if ( /^Class\s\d{1,2}:\s+(\w+)\s+(\w+)\W*$/ ) {
	    $clses{$2} = 1;
	}
    }

    return \%clses;
}

#
# parse the show zones output
# return the zonename => 1 hashtable, not a list
#
sub parse_zones($)
{
    my $raw = shift;

    my %zones = ();

    foreach ( split ( /\n/, $raw) ) {
	if ( /^\d{1,2}:\s+(\w+)\W*$/ ) {
	    $zones{$1} = 1;
	}
    }

    return \%zones;
}


#
# parse the show class ports output
# return the ports list
#
sub parse_class_ports($)
{
    my $raw = shift;
    my @ports = ();

    foreach ( split ( /\n/, $raw) ) {
	if ( /^Port\s+\d+:\s+([A-I][0-9]{2})\W*$/ ) {
	    push @ports, $1;
	}
    }

    return \@ports;
}


#
# parse the show zone ports output
# same to parse_class_ports
#
sub parse_zone_ports($)
{
    return parse_class_ports(@_[0]);
}


#
# helper to do CLI command and check the error msg
#
sub _do_cli_cmd($$)
{
    my ($exp, $cmd) = @_;
    my $output = "";

    $exp->clear_accum(); # Clean the accumulated output, as a rule.
    $exp->send($cmd);
    $exp->expect($CLI_TIMEOUT,
		 [$CLI_PROMPT => sub {
		     my $e = shift;
		     $output = $e->before();
		  }]);

    $cmd = quotemeta($cmd);
    if ( $output =~ /^($cmd)\n(ERROR:.+)\r\n[.\n]*$/ ) {
	return (1, $2);
    } else {
	return (0, $output);
    }
}


#
# get the raw CLI output of a command
#
sub get_raw_output($$)
{
    my ($exp, $cmd) = @_;
    my ($rt, $output) = _do_cli_cmd($exp, $cmd);
    if ( !$rt ) {    	
    	my $qcmd = quotemeta($cmd);
	if ( $output =~ /^($qcmd)/ ) {
	    return substr($output, length($cmd)+1);
	}		
    }

    return undef;
}


#
# get all vlans and their ports
# return the vlanname => port list hashtable
#
sub get_all_vlans($)
{
    my $exp = shift;

    my $raw = get_raw_output($exp, $CLI_SHOW_PORT_NAMES);
    my $names = parse_names($raw); 

    my %vlans = ();
    foreach my $k (keys %{$names}) {
	if ( !(exists $vlans{$names->{$k}}) ) {
	    $vlans{$names->{$k}} = ();
	}

	push @{$vlans{$names->{$k}}}, $k;
    }

    return \%vlans;
}


#
# get the vlanname of a port
#
sub get_port_vlan($$)
{
    my ($exp, $port) = @_;

    my $raw = get_raw_output($exp, "show port info $port\r");
    if ( $raw =~ /$port Name:\s+(\w+)\W*\n/ ) {
	if (  $1 !~ /$CLI_UNNAMED_PATTERN/ ) {
	    return $1;
	}
    }

    return undef;
}

#
# get the ports list of a vlan
#
sub get_vlan_ports($$)
{
    my ($exp, $vlan) = @_;
    my @ports = ();

    my $raw = get_raw_output($exp, $CLI_SHOW_PORT_NAMES);
    foreach ( split /\n/, $raw ) {
	if ( /^([A-I][0-9]{2}):\s+($vlan)\W*/ ) {
	    push @ports, $1;
	}
    }

    return \@ports;
}

#
# get connections within a vlan
# return two hashtabls whose format is same to parse_connections
#
sub get_vlan_connections($$)
{
    my ($exp, $vlan) = @_;

    my $raw_conns = get_raw_output($exp, $CLI_SHOW_CONNECTIONS);
    my ($allsrc, $alldst) = parse_connections($raw_conns);
    my $ports = get_vlan_ports($exp, $vlan);

    my %src = ();
    my %dst = ();

    #
    # There may be something special: a vlan port may connect to
    # a port that doesn't belong to the vlan. Then this connection
    # should not belong to the vlan. Till now the following codes
    # have not dealt with it yet.
    #
    # TODO: remove those connections containning ports don't belong
    #       to the vlan.
    #
    foreach my $p (@$ports) {
	if ( exists($allsrc->{$p}) ) {
	    $src{$p} = $allsrc->{$p};
	} 

	if ( exists($alldst->{$p}) ) {
	    $dst{$p} = $alldst->{$p};
	}
    }

    return (\%src, \%dst);
}

#
# Add a new class
#
sub add_cls($$)
{
    my ($exp, $clsname) = @_;
    my $cmd = "add class I $clsname\r";

    return _do_cli_cmd($exp, $cmd);
}

#
# Add a new zone
#
sub add_zone($$)
{
    my ($exp, $zonename) = @_;
    my $cmd = "add zone $zonename\r";

    return _do_cli_cmd($exp, $cmd);
}

#
# Add some ports to a class
#
sub add_class_ports($$@)
{
    my ($exp, $clsname, @ports) = @_;
    my $cmd = "add class ports $clsname ".join("", @ports)."\r";

    return _do_cli_cmd($exp, $cmd);
}

# 
# Connect ports functions:
#

#
# Make a multicast connection $src --> @dsts
#
sub connect_multicast($$@)
{
    my ($exp, $src, @dsts) = @_;
    my $cmd = "connect multicast $src".join("", @dsts)."\r";

    return _do_cli_cmd($exp, $cmd);
}

#
# Make a duplex connection $src <> $dst
#
sub connect_duplex($$$)
{
    my ($exp, $src, $dst) = @_;
    my $cmd = "connect duplex $src"."$dst"."\r";

    return _do_cli_cmd($exp, $cmd);
}

#
# Make a simplex connection $src -> $dst
#
sub connect_simplex($$$)
{
    my ($exp, $src, $dst) = @_;
    my $cmd = "connect simplex $src"."$dst"."\r";

    return _do_cli_cmd($exp, $cmd);
}

#
# Create a new vlan, it actually does nothing.
# Maybe I should find a way to reserve the name.
#
sub create_vlan($$)
{
    # do nothing, but it is perfect if we can reserve the name here.
}

#
# Add some ports to a vlan, 
# it actually names those ports to the vlanname. 
#
sub add_vlan_ports($$@)
{
    my ($exp, $vlan, @ports) = @_;

    for( my $i = 0; $i < @ports; $i++ ) {    	
	my ($rt, $msg) = _do_cli_cmd($exp, 
				     "configure port name $ports[$i] $vlan\r");

	# undo set name
	if ( $rt ) {
	    for ($i--; $i >= 0; $i-- ) {	    	
		_do_cli_cmd($exp, 
			    "configure port name $ports[$i] $CLI_UNNAMED_NAME\r");
	    }
	    return $msg;
	}
    }

    return 0;
}


#
# Unname ports, the name of those ports will be $CLI_UNNAMED_NAME
#
sub unname_ports($@)
{
    my ($exp, @ports) = @_;

    my $emsg = "";
    foreach my $p (@ports) {
	my ($rt, $msg) = _do_cli_cmd($exp,
				     "configure port name $p $CLI_UNNAMED_NAME\r");
	if ( $rt ) {
	    $emsg = $emsg.$msg."\n";
	}
    }

    if ( $emsg eq "" ) {
	return 0;
    }

    return $emsg;
}


#
# Disconnect ports
# $sconns: the dst => src hashtable.
#
sub disconnect_ports($$) 
{
    my ($exp, $sconns) = @_;

    my $emsg = "";
    foreach my $src (keys %$sconns) {
	my ($rt, $msg) = _do_cli_cmd($exp,
				     "disconnect $src".$sconns->{$src}."\r");
	if ( $rt ) {
	    $emsg = $emsg.$msg."\n";
	}
    }

    if ( $emsg eq "" ) {
	return 0;
    }

    return $emsg;
}


#
# Remove a vlan, unname the ports and disconnect them
#
sub remove_vlan($$)
{
    my ($exp, $vlan) =  @_;

    # Disconnect ports:
    my ($src, $dst) = get_vlan_connections($exp, $vlan);
    my $disrt = disconnect_ports($exp, $src);

    # Unname ports:
    my $ports = get_vlan_ports($exp, $vlan);
    my $unrt = unnamed_ports($exp, @$ports);
    if ( $unrt || $disrt) {
	return $disrt.$unrt;
    }

    return 0;
}

#
# Obsoleted:
# I found a better way to name the 'vlan'.
# Ports can share the same name, so we can name
# the ports in a vlan the same name, which is the vlan name.
# However, extra work is required to parse the port names.
#
# Make a name from the ports of a VLAN
# The naming rule is "vlan"+(sorted ports), e.g.:
# A vlan has A01, A03, B02, its name is 'vlanA01A03B02'.
#
sub make_vlan_name(@)
{
    my @ports = shift;

    return "vlan".join("", sort @ports);
}


#
# Do port control, set port rate.
# Rates are defined in %portCMDs.
#
sub port_control($$$)
{
    my ($exp, $port, $rate) = @_;

    if ( !exists($portCMDs{$rate}) ) {
	return "ERROR: port rate unsupported!\n";
    }

    my $cmd = "configure rate $port $portCMDs{$rate}\r";
    my ($rt, $msg) = _do_cli_cmd($exp, $cmd);
    if ( $rt ) {
	return $msg;
    }

    return 0;
}
