#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'IPC::Share::BDB' ) || print "Bail out!\n";
    use_ok( 'IPC::Share::BDB::Array' ) || print "Bail out!\n";
    use_ok( 'IPC::Share::BDB::Hash' ) || print "Bail out!\n";
    use_ok( 'IPC::Share::BDB::Queue' ) || print "Bail out!\n";
}

diag( "Testing IPC::Share::BDB $IPC::Share::BDB::VERSION, Perl $], $^X" );
