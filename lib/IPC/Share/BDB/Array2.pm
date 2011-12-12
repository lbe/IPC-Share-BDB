package IPC::Share::BDB::Array;

use 5.006;
use strict;
use warnings;
use BerkeleyDB;
use Carp ;

our @ISA = qw( BerkeleyDB::Recno );


our $VERSION = '0.01';

sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	return bless($self, $class);
}

*IPC::Share::BDB::TIEARRAY = \&IPC::Share::BDB::new;


1; # End of IPC::Share::BDB::Array
