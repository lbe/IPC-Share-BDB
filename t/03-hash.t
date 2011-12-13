#!.kperl -w

# ID: %I%, %G%

use strict;

use lib 't';
use BerkeleyDB;
use IPC::Share::BDB;
use IPC::Share::BDB::Hash;
use util;
use Test::More;

plan tests => 100;

my $Dfile  = "dbhash.tmp";
my $Dfile2 = "dbhash2.tmp";
my $Dfile3 = "dbhash3.tmp";
unlink $Dfile;

umask(0);

# Check for invalid parameters
{

    # Check for invalid parameters
    my $db;
    eval ' $db = new IPC::Share::BDB::Hash  -Stupid => 3 ; ';
    ok $@ =~ /unknown key value\(s\) Stupid/;

    eval
' $db = new IPC::Share::BDB::Hash -Bad => 2, -Mode => 0345, -Stupid => 3; ';
    ok $@ =~ /unknown key value\(s\) (Bad,? |Stupid,? ){2}/;

    eval ' $db = new IPC::Share::BDB::Hash -Env => 2 ';
    ok $@ =~ /^Env not of type BerkeleyDB::Env/;

    eval ' $db = new IPC::Share::BDB::Hash -Txn => "fred" ';
    ok $@ =~ /^Txn not of type BerkeleyDB::Txn/;

    my $obj = bless [], "main";
    eval ' $db = new IPC::Share::BDB::Hash -Env => $obj ';
    ok $@ =~ /^Env not of type BerkeleyDB::Env/;
}

# Now check the interface to HASH

{
    my $lex = new LexFile $Dfile ;

    ok my $env =
      new IPC::Share::BDB -Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL;

    ok my $db = new IPC::Share::BDB::Hash
      -Filename => $Dfile,
      -Flags    => DB_CREATE;

    # Add a k/v pair
    my $value;
    my $status;
    is $db->Env, undef;
    ok $db->db_put( "some key", "some value" ) == 0;
    ok $db->status() == 0;
    ok $db->db_get( "some key", $value ) == 0;
    ok $value eq "some value";
    ok $db->db_put( "key", "value" ) == 0;
    ok $db->db_get( "key", $value ) == 0;
    ok $value eq "value";
    ok $db->db_del("some key") == 0;
    ok( ( $status = $db->db_get( "some key", $value ) ) == DB_NOTFOUND );
    ok $status =~ $DB_errors{'DB_NOTFOUND'};
    ok $db->status() == DB_NOTFOUND;
    ok $db->status() =~ $DB_errors{'DB_NOTFOUND'};

    ok $db->db_sync() == 0;

    # Check NOOVERWRITE will make put fail when attempting to overwrite
    # an existing record.

    ok $db->db_put( 'key', 'x', DB_NOOVERWRITE ) == DB_KEYEXIST;
    ok $db->status() =~ $DB_errors{'DB_KEYEXIST'};
    ok $db->status() == DB_KEYEXIST;

    # check that the value of the key  has not been changed by the
    # previous test
    ok $db->db_get( "key", $value ) == 0;
    ok $value eq "value";

    # test DB_GET_BOTH
    my ( $k, $v ) = ( "key", "value" );
    ok $db->db_get( $k, $v, DB_GET_BOTH ) == 0;

    ( $k, $v ) = ( "key", "fred" );
    ok $db->db_get( $k, $v, DB_GET_BOTH ) == DB_NOTFOUND;

    ( $k, $v ) = ( "another", "value" );
    ok $db->db_get( $k, $v, DB_GET_BOTH ) == DB_NOTFOUND;

}

{

    # Check simple env works with a hash.
    my $lex = new LexFile $Dfile ;

    my $home = "./fred";
    ok my $lexD = new LexDir($home);

    ok my $env = new IPC::Share::BDB
      -Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL,
      -Home  => $home;
    ok my $db = new IPC::Share::BDB::Hash
      -Filename => $Dfile,
      -Env      => $env,
      -Flags    => DB_CREATE;

    isa_ok $db->Env, 'BerkeleyDB::Env';

    # Add a k/v pair
    my $value;
    ok $db->db_put( "some key", "some value" ) == 0;
    ok $db->db_get( "some key", $value ) == 0;
    ok $value eq "some value";
    undef $db;
    undef $env;
}

{

    # override default hash
    my $lex = new LexFile $Dfile ;
    my $value;
    $::count = 0;
    ok my $env =
      new IPC::Share::BDB -Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL;
    ok my $db = new IPC::Share::BDB::Hash
      -Filename => $Dfile,
      -Hash     => sub { ++$::count; length $_[0] },
      -Env      => $env,
      -Flags    => DB_CREATE;

    ok $db->db_put( "some key", "some value" ) == 0;
    ok $db->db_get( "some key", $value ) == 0;
    ok $value eq "some value";
    ok $::count > 0;

}

{

    # cursors

    my $lex = new LexFile $Dfile ;
    my %hash;
    my ( $k, $v );
    ok my $env =
      new IPC::Share::BDB -Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL;
    ok my $db = new IPC::Share::BDB::Hash
      -Filename => $Dfile,
      -Env      => $env,
      -Flags    => DB_CREATE;

    # create some data
    my %data = (
        "red"   => 2,
        "green" => "house",
        "blue"  => "sea",
    );

    my $ret = 0;
    while ( ( $k, $v ) = each %data ) {
        $ret += $db->db_put( $k, $v );
    }
    ok $ret == 0;

    # create the cursor
    ok my $cursor = $db->db_cursor();

    $k = $v = "";
    my %copy   = %data;
    my $extras = 0;

    # sequence forwards
    while ( $cursor->c_get( $k, $v, DB_NEXT ) == 0 ) {
        if   ( $copy{$k} eq $v ) { delete $copy{$k} }
        else                     { ++$extras }
    }
    ok $cursor->status() == DB_NOTFOUND;
    ok $cursor->status() =~ $DB_errors{'DB_NOTFOUND'};
    ok keys %copy == 0;
    ok $extras == 0;

    # sequence backwards
    %copy   = %data;
    $extras = 0;
    my $status;
    for (
        $status = $cursor->c_get( $k, $v, DB_LAST ) ;
        $status == 0 ;
        $status = $cursor->c_get( $k, $v, DB_PREV )
      )
    {
        if   ( $copy{$k} eq $v ) { delete $copy{$k} }
        else                     { ++$extras }
    }
    ok $status == DB_NOTFOUND;
    ok $status =~ $DB_errors{'DB_NOTFOUND'};
    ok $cursor->status() == $status;
    ok $cursor->status() eq $status;
    ok keys %copy == 0;
    ok $extras == 0;

    ( $k, $v ) = ( "green", "house" );
    ok $cursor->c_get( $k, $v, DB_GET_BOTH ) == 0;

    ( $k, $v ) = ( "green", "door" );
    ok $cursor->c_get( $k, $v, DB_GET_BOTH ) == DB_NOTFOUND;

    ( $k, $v ) = ( "black", "house" );
    ok $cursor->c_get( $k, $v, DB_GET_BOTH ) == DB_NOTFOUND;

}

{

    # Tied Hash interface

    my $lex = new LexFile $Dfile ;
    my %hash;
    ok my $env =
      new IPC::Share::BDB -Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL;
    ok tie %hash, 'IPC::Share::BDB::Hash',
      -Filename => $Dfile,
      -Env      => $env,
      -Flags    => DB_CREATE;

    # check "each" with an empty database
    my $count = 0;
    while ( my ( $k, $v ) = each %hash ) {
        ++$count;
    }
    ok( ( tied %hash )->status() == DB_NOTFOUND );
    ok $count == 0;

    # Add a k/v pair
    my $value;
    $hash{"some key"} = "some value";
    ok( ( tied %hash )->status() == 0 );
    ok $hash{"some key"} eq "some value";
    ok defined $hash{"some key"};
    ok( ( tied %hash )->status() == 0 );
    ok exists $hash{"some key"};
    ok !defined $hash{"jimmy"};
    ok( ( tied %hash )->status() == DB_NOTFOUND );
    ok !exists $hash{"jimmy"};
    ok( ( tied %hash )->status() == DB_NOTFOUND );

    delete $hash{"some key"};
    ok( ( tied %hash )->status() == 0 );
    ok !defined $hash{"some key"};
    ok( ( tied %hash )->status() == DB_NOTFOUND );
    ok !exists $hash{"some key"};
    ok( ( tied %hash )->status() == DB_NOTFOUND );

    $hash{1}    = 2;
    $hash{10}   = 20;
    $hash{1000} = 2000;

    my ( $keys, $values ) = ( 0, 0 );
    $count = 0;
    while ( my ( $k, $v ) = each %hash ) {
        $keys   += $k;
        $values += $v;
        ++$count;
    }
    ok $count == 3;
    ok $keys == 1011;
    ok $values == 2022;

    # now clear the hash
    %hash = ();
    ok keys %hash == 0;

    untie %hash;
}

{

    # in-memory file

    my $lex = new LexFile $Dfile ;
    my %hash;
    my $fd;
    my $value;
    ok my $env =
      new IPC::Share::BDB -Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL;
    ok my $db = tie %hash, 'IPC::Share::BDB::Hash', -Env => $env
      or die $BerkeleyDB::Error;

    ok $db->db_put( "some key", "some value" ) == 0;
    ok $db->db_get( "some key", $value ) == 0;
    ok $value eq "some value";

    undef $db;
    untie %hash;
}


{

    # transaction

    my $home = "./fred";
    ok my $lexD = new LexDir($home);
    my $lex = new LexFile $Dfile ;
    my %hash;
    my $value;
    ok my $env = new IPC::Share::BDB
      -Home  => $home,
      -Flags => DB_CREATE | DB_INIT_TXN | DB_INIT_MPOOL | DB_INIT_LOCK;
    ok my $txn = $env->txn_begin();
    ok my $db1 = tie %hash, 'IPC::Share::BDB::Hash',
      -Filename => $Dfile,
      -Flags    => DB_CREATE,
      -Env      => $env,
      -Txn      => $txn;

    isa_ok( ( tied %hash )->Env, 'BerkeleyDB::Env' );
    ( tied %hash )->Env->errPrefix("abc");
    is( ( tied %hash )->Env->errPrefix("abc"), 'abc' );

    ok $txn->txn_commit() == 0;
    ok $txn = $env->txn_begin();
    $db1->Txn($txn);

    # create some data
    my %data = (
        "red"   => "boat",
        "green" => "house",
        "blue"  => "sea",
    );

    my $ret = 0;
    while ( my ( $k, $v ) = each %data ) {
        $ret += $db1->db_put( $k, $v );
    }
    ok $ret == 0;

    # should be able to see all the records

    ok my $cursor = $db1->db_cursor();
    my ( $k, $v ) = ( "", "" );
    my $count = 0;

    # sequence forwards
    while ( $cursor->c_get( $k, $v, DB_NEXT ) == 0 ) {
        ++$count;
    }
    ok $count == 3;
    undef $cursor;

    # now abort the transaction
    ok $txn->txn_abort() == 0;

    # there shouldn't be any records in the database
    $count = 0;

    # sequence forwards
    ok $cursor = $db1->db_cursor();
    while ( $cursor->c_get( $k, $v, DB_NEXT ) == 0 ) {
        ++$count;
    }
    ok $count == 0;

    undef $txn;
    undef $cursor;
    undef $db1;
    undef $env;
    untie %hash;
}


