#!/usr/local/bin/tclsh

proc outs {args} {
    global logFp
    if {[llength $args] == 1} {
	set out stdout
	set s [lindex $args 0]
    } else {
	set out [lindex $args 0]
	set s [lindex $args 1]
    }
    
    puts $out $s
    puts $logFp $s
}

if {[file dirname [info script]] == "."} {
    set updir ".."
} else {
    set updir [file dirname [file dirname [info script]]]
}

set nfree "$updir/db/nfree"
set libir "$updir/ir/libir.tcl"
set resetvlans "$updir/switch_tools/intel510/resetvlans.tcl"

source $libir
namespace import TB_LIBIR::ir

if {$argc != 1} {
    puts stderr "Syntax: $argv0 <ir-file>"
    exit 1
}

set nsFile [lindex $argv 0]
set t [split $nsFile .]
set prefix [join [lrange $t 0 [expr [llength $t] - 2]] .]
set irFile "$prefix.ir"
set logFile "$prefix.log"

if {[catch "open $logFile a+" logFp]} {
    puts stderr "Could not open $logFile for writing."
    exit 1
}

outs "Input: $irFile"
outs "Log: $logFile"

if {! [file exists $irFile]} {
    outs stderr "$irFile does not exist"
    exit 1
}

outs ""
outs "Ending Testbed run for $irFile. [clock format [clock seconds]]"

ir read $irFile

outs "Unallocating resources"

set nodemap [ir get /virtual/nodes]
set machines {}
foreach pair $nodemap {
    lappend machines [lindex $pair 1]
}

if {[catch "exec $nfree $prefix $machines >@ $logFp 2>@ $logFp err"]} {
    outs stderr "Error freeing resources. ($err)"
    exit 1
}

outs "Resetting VLANs"
if {[catch "exec $resetvlans $machines >@ $logFp 2>@ $logFp" err]} {
    outs stderr "Error reseting vlans ($err)"
    exit 1
}
