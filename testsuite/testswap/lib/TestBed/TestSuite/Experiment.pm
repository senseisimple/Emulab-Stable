#!/usr/bin/perl
use SemiModern::Perl;

package TestBed::TestSuite::Experiment;
use Mouse;
use TestBed::XMLRPC::Client::Experiment;
use Tools::PingTest;
use Tools::TBSSH;
use Data::Dumper;

extends 'Exporter', 'TestBed::XMLRPC::Client::Experiment';
require Exporter;
our @EXPORT;

push @EXPORT, qw(e ep launchpingkill launchpingswapkill);

sub ep { TestBed::TestSuite::Experiment->new }
sub e  { TestBed::TestSuite::Experiment->new('pid'=> shift, 'eid' => shift) }

sub ping_test {
  my ($e) = @_;
  my $nodes = $e->nodeinfo();
  for (@$nodes) {
    ping($_);
  }
}

sub ssh_hostname_test {
  my ($e) = @_;
  my $nodes = $e->nodeinfo();
  for (@$nodes) {
    Tools::TBSSH::sshhostname($_, $TBConfig::EMULAB_USER);
  }
}

sub trytest(&$) {
  eval {$_[0]->()};
  if ($@) {
    say $@;
    $_[1]->end;
    0; 
  }
  else {
    1;
  }
}

sub launchpingkill {
  my ($pid, $eid, $ns) = @_;
  my $e = e($pid, $eid);
  trytest {
    $e->batchexp_ns_wait($ns) && die "batchexp $eid failed";
    $e->ping_test             && die "connectivity test $eid failed";
    $e->end                   && die "exp end $eid failed";
  } $e;
}

sub launchpingswapkill {
  my ($pid, $eid, $ns) = @_;
  my $e = e($pid, $eid);
  trytest {
    $e->batchexp_ns_wait($ns) && die "batchexp $eid failed";
    $e->ping_test             && die "connectivity test $eid failed";
    $e->swapout_wait          && die "swap out $eid failed";
    $e->swapin_wait           && die "swap in $eid failed";
    $e->ping_test             && die "connectivity test $eid failed";
    $e->end                   && die "exp end $eid failed";
  } $e;
}
1;