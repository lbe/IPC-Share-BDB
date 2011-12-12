#!/usr/bin/perl

use IPC::Share::BDB;
use Data::Dumper;

my $senv = new IPC::Share::BDB -Home => "/tmp/bdb2" ;

1;
