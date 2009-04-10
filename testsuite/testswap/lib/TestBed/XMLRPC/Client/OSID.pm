#!/usr/bin/perl

package TestBed::XMLRPC::Client::OSID;
use SemiModern::Perl;
use Mouse;
use Data::Dumper;

extends 'TestBed::XMLRPC::Client';

#autoloaded/autogenerated/method_missings/etc getlist info

sub info { shift->augment( 'osid' => shift, @_ ); }

1;
