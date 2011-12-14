package IPC::Share::BDB::Array;

use 5.006;
use strict;
use warnings;
use BerkeleyDB;
use Carp;

use base 'BerkeleyDB::Recno';

our $VERSION = '0.01_01';

sub FETCH {
    my $self = shift;
    my $lk   = $self->cds_lock();
    my $ret  = $self->SUPER::FETCH(@_);
    return $ret;
}

sub CLEAR {
    my $self = shift;
    my $lk   = $self->cds_lock();
    my $ret  = $self->SUPER::CLEAR();
    return $ret;
}

sub POP {
    my $self = shift;
    my $lk   = $self->cds_lock();
    my $ret  = $self->SUPER::POP(@_);
    return $ret;
}

sub PUSH {
    my $self = shift;
    my $lk   = $self->cds_lock();
    my $ret  = $self->SUPER::PUSH(@_);
    return $ret;
}

sub SHIFT {
    my $self = shift;
    my $lk   = $self->cds_lock();
    my $ret  = $self->SUPER::SHIFT(@_);
    return $ret;
}

sub SPLICE {
    my $self = shift;
    my $lk   = $self->cds_lock();
    my $ret  = $self->SUPER::SPLICE(@_);
    return $ret;
}

sub STORE {
    my $self = shift;
    my $lk   = $self->cds_lock();
    my $ret  = $self->SUPER::STORE(@_);
    return $ret;
}

sub STORESIZE {
    my $self = shift;
    my $lk   = $self->cds_lock();
    my $ret  = $self->SUPER::STORESIZE(@_);
    return $ret;
}

sub UNSHIFT {
    my $self = shift;
    my $lk   = $self->cds_lock();
    my $ret  = $self->SUPER::UNSHIFT(@_);
    return $ret;
}

1;    # End of IPC::Share::BDB::Array

__END__

=pod

=head1 NAME

IPC::Share::BDB::Array - a class that ties BerkeleyDB::Recno to a perl array.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

    use BerkeleyDB;
    use IPC::Share::BDB;
    use IPC::Share::BDB::Array;

    my $env = new IPC::Share::BDB()
        or die "cannot open environment: $BerkeleyDB::Error\n";
        
    my $db = tie my @q1, 'IPC::Share::BDB::Array', -Env => $env
        or die "cannot open datbase: $BerkeleyDB::Error\n";

=head1 DESCRIPTION

This module provides methods for array-tying classes. See
L<perltie> for a list of the functions required in order to tie an array
to a package.

This distribution is a work in progress (started 12/11/11).  There will 
be more to come.

The goal of this distribution is to provide an easy means to share data 
structures between processes and threads.  It does so using objects with 
convenience methods that are tied to the BerkeleyDB hashes or recnos. This 
functionaly already exists for threads using threads::share which uses
shared memory (RAM).  This distribution may be useful in threads when 
the hash(es) and/or array(s) is too large to be stored in RAM.

Additionally, this distribution provides a queue module, similar to
threads::queue, that can be used across processes.

The data store of all objects are based upon Berkeley DB Concurrent Data
Store (CDS).  The module handles all locking needed to insure that only
a single writer is allowed at any one time.  The selection of CDS was
made to favor speed over absolutely integrity.  This means that if an
error occurs while a change is being written to the database, that the
database will be left in an uncertain state.  Given the overall stability
of BerkeleyDB code, this is unlikely, but still possible.  If absolutely
reliability is required, then one should use the BerkeleyDB directly
and make use of its Transacational Data Store (TDS) capability.

As stated above, it is the author's intent that this model be used
between processes/threads; hence "thread safe" and "fork safe" are goals
that must be achieved in order to be successful.  Care has been
taken to insure that this module achieves this functionality; however,
given the lack of precisely clear definitions for either thread or
fork safety, it is very possible that the author has not adequately
contemplated situations that may cause deadlock or race problems.
As such, the author welcomes any feedback, preferably with corrected
code to address and tests to validate, problems.

=head1 METHODS

The following methods are used by perl Tie and should not be called directly.

=head2 TIEARRAY

The class method is invoked by the command C<tie @array, classname>. Associates
an array instance with the specified class. C<LIST> would represent
additional arguments (along the lines of L<AnyDBM_File> and compatriots) needed
to complete the association. The method should return an object of a class which
provides the methods below.

=head2 CLEAR

Clear (remove, delete, ...) all values from the tied array associated with
object I<this>.

=head2 FETCH

Retrieve the datum in I<index> for the tied array associated with
object I<this>.

=head2 POP this

Remove last element of the array and return it.

=head2 PUSH this, LIST

Append elements of LIST to the array.

=head2 SHIFT

Remove the first element of the array (shifting other elements down)
and return it.

=head2 SPLICE  this, offset, length, LIST

Not implemented in BerkeleyDB 0.50.  This module is designed to 
automatically pick up this this function when it is available in the 
installed BerkelelyDB version

If implemented, perform the equivalent of C<splice> on the array.

I<offset> is optional and defaults to zero, negative values count back
from the end of the array.

I<length> is optional and defaults to rest of the array.

I<LIST> may be empty.

Returns a list of the original I<length> elements at I<offset>.

=head2 STORE

Store datum I<value> into I<index> for the tied array associated with
object I<this>. If this makes the array larger then
class's mapping of C<undef> should be returned for new positions.

=head2 STORESIZE

Not implemented in BerkeleyDB 0.50.  This module is designed to 
automatically pick up this this function when it is available in the 
installed BerkelelyDB version

If implemented, sets the total number of items in the tied array associated with
object I<this> to be I<count>. If this makes the array larger then
class's mapping of C<undef> should be returned for new positions.
If the array becomes smaller then entries beyond count should be
deleted.

=head2 UNSHIFT this, LIST

Insert LIST elements at the beginning of the array, moving existing elements
up to make room.


=head1 AUTHOR

lbe, C<< <learnedbyerror at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc::share::bdb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC::Share::BDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::Share::BDB::Array


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPC::Share::BDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPC::Share::BDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPC::Share::BDB>

=item * Search CPAN

L<http://search.cpan.org/dist/IPC::Share::BDB/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 lbe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
