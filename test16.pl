#!/usr/bin/perl 

use strict;
use warnings;
use BerkeleyDB;
use IPC::Share::BDB;
use IPC::Share::BDB::Array2;
use Data::Dumper;
use Time::HiRes qw( time );

print "Main($$) started\n";

my $env = new IPC::Share::BDB()
#my $env = new BerkeleyDB::Env
#  -Home  => "/tmp/bdb",
#  -Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL
  or die "cannot open environment: $BerkeleyDB::Error\n";

my @q1;
my $db1 = tie @q1, 'IPC::Shared::BDB::Array2',
  -Filename => 'q1.db',
  -Flags    => DB_CREATE,
  -Env      => $env
  or die "cannot open database:  $BerkeleyDB::Error\n";

my @q2;
my $db2 = tie @q2, 'IPC::Shared::BDB::Array2',
  -Filename => 'q2.db',
  -Flags    => DB_CREATE,
  -Env      => $env
  or die "cannot open database:  $BerkeleyDB::Error\n";

for ( 1 .. 3000 ) { push(@q1, "11"); }
print "pushed ", scalar(@q1), " entries in \@q1\n";
my $j = 0;
foreach (@q1) {
	$j++;
	my $a = pop(@q1);
}
print "popped $j entries from \@q1\n";

for ( 1 .. 3000 ) { push(@q2, "11"); }
print "pushed ", scalar(@q2), " entries in \@q2\n";
$j = 0;
foreach (@q2) {
	$j++;
	my $a = pop(@q2);
}
print "popped $j entries from \@q2\n";


