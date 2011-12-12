package IPC::Share::BDB::Queue;

use 5.006;
use strict;
use warnings;
use BerkeleyDB;
use Carp;
use IPC::Share::BDB;
use IPC::Share::BDB::Array;
use Scalar::Util 1.10 qw(looks_like_number blessed reftype refaddr);
use Time::HiRes qw( usleep );

our $VERSION = '0.01_01';

our $env;
our $dbh;

# Predeclarations for internal functions
my ($validate_count, $validate_index);

sub new {
    my $class = shift;
    $class = ( ref $class ) || $class;

    $env = new IPC::Share::BDB()
      or croak "cannot open environment: $BerkeleyDB::Error\n";

    my @queue;
    $dbh = tie @queue, 'IPC::Share::BDB::Array',
      -Filename => "queue.$$.db",
      -Flags    => DB_CREATE, 
      -Env      => $env
      or croak "cannot open database: $BerkeleyDB::Error\n";

    push( @queue, @_ ) if (@_);

    return bless( \@queue, $class );
}

sub enqueue {
    my $queue = shift;
    my $ret = push( @$queue, @_ );
    return $ret;
}

sub pending {
    my $queue = shift;
    return scalar(@$queue);
}

sub dequeue {
    my $queue = shift;

    my $count = @_ ? $validate_count->(shift) : 1;

    # Wait for requisite number of items
    while ( @$queue < $count ) {
        usleep(1000)    # sleep one millisecond and check again
    }

    # Return single item
    return shift(@$queue) if ( $count == 1 );

    # Return multiple items
    my @items;
    push( @items, shift(@$queue) ) for ( 1 .. $count );
    return @items;
}

sub dequeue_nb {
    my $queue = shift;

    my $count = @_ ? $validate_count->(shift) : 1;

    # Return nothing if there is nothing to return
    return unless (@$queue);

    # Return single item
    return shift(@$queue) if ( $count == 1 );

    # Return multiple items
    my @items;
    push( @items, shift(@$queue) ) for ( 1 .. $count );
    return @items;
}

sub extract {
    my $queue = shift;

    my $index = @_ ? $validate_index->(shift) : 0;
    my $count = @_ ? $validate_count->(shift) : 1;

    # Support negative indices
    if ( $index < 0 ) {
        $index += @$queue;
        if ( $index < 0 ) {
            $count += $index;
            return if ( $count <= 0 );    # Beyond the head of the queue
            return $queue->dequeue_nb($count);    # Extract from the head
        }
    }

    # Dequeue items from $index+$count onward
    my @tmp;
    while ( @$queue > ( $index + $count ) ) {
        unshift( @tmp, pop(@$queue) );
    }

    # Extract desired items
    my @items;
    unshift( @items, pop(@$queue) ) while ( @$queue > $index );

    # Add back any removed items
    push( @$queue, @tmp );

    # Return single item
    return $items[0] if ( $count == 1 );

    # Return multiple items
    return @items;

}

sub insert {
    my $queue = shift;

    my $index = $validate_index->(shift);

    return if ( !@_ );    # Nothing to insert

    # Support negative indices
    if ( $index < 0 ) {
        $index += @$queue;
        if ( $index < 0 ) {
            $index = 0;
        }
    }

    # Dequeue items from $index onward
    my @tmp;
    while ( @$queue > $index ) {
        unshift( @tmp, pop(@$queue) );
    }

    # Add new items to the queue
    push( @$queue, map { shared_clone($_) } @_ );

    # Add previous items back onto the queue
    push( @$queue, @tmp );
}

sub peek {
    my $queue = shift;
    lock(@$queue);
    my $index = @_ ? $validate_index->(shift) : 0;
    return $$queue[$index];

}

### Internal Functions ###

## Check value of the requested index
$validate_index = sub {
    my $index = shift;

    if (   !defined($index)
        || !looks_like_number($index)
        || ( int($index) != $index ) )
    {
        require Carp;
        my ($method) = ( caller(1) )[3];
        $method =~ s/Thread::Queue:://;
        $index = 'undef' if ( !defined($index) );
        Carp::croak("Invalid 'index' argument ($index) to '$method' method");
    }

    return $index;
};

# Check value of the requested count
$validate_count = sub {
    my $count = shift;

    if (   !defined($count)
        || !looks_like_number($count)
        || ( int($count) != $count )
        || ( $count < 1 ) )
    {
        require Carp;
        my ($method) = ( caller(1) )[3];
        $method =~ s/Thread::Queue:://;
        $count = 'undef' if ( !defined($count) );
        Carp::croak("Invalid 'count' argument ($count) to '$method' method");
    }

    return $count;
};

1;    # End of IPC::Share::BDB::Array

__END__

=pod

=head1 NAME

IPC::Share::BDB::Array - a class that ties BerkeleyDB::Recno to a perl array.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

    use IPC::Share::BDB::Queue;
    my $q = new IPC::Share::BDB::Queue(); # A new empty queue

    # Send work to the process/thread
    $q->enqueue( $item1, ... );

    # Count of items in the queue
    my $left = $q->pending();
																			
    # Non-blocking dequeue
    if (defined(my $item = $q->dequeue_nb())) {
           # Work on $item
    }

    # Get the second item in the queue without dequeuing anything
    my $item = $q->peek(1);

    # Insert two items into the queue just behind the head
    $q->insert(1, $item1, $item2);

    # Extract the last two items on the queue
    my ($item1, $item2) = $q->extract(-2, 2);

=head1 DESCRIPTION

This module provides fork/thread-safe FIFO queues that can be accessed 
safely by any number of processes/threads.

Any data types supported by L<threads::shared> can be passed via queues:

=over 8

=item * Ordinary scalars

=item * Array refs

=item * Hash refs

=item * Scalar refs

=item * Objects based on the above

=back

Ordinary scalars are added to queues as they are.

This module can be a replacement for L<Thread::Queue> if more queue 
storage is needed than is available in RAM.  Additionally, unlike 
L<Thread::Queue>, all complex datatypes supported by L<MLDBM> are 
available for sharing immediately without needing to share separately.

I<This distribution is a work in progress (started 12/11/11).  There will 
be more to come.>

I<The goal of this distribution is to provide an easy means to share data 
structures between processes and threads.  It does so using objects with 
convenience methods that are tied to the BerkeleyDB hashes or recnos. This 
functionaly already exists for threads using threads::share which uses
shared memory (RAM).  This distribution may be useful in threads when 
the hash(es) and/or array(s) is too large to be stored in RAM.>

I<Additionally, this distribution provides a queue module, similar to
threads::queue, that can be used across processes.>

I<The data store of all objects are based upon Berkeley DB Concurrent Data
Store (CDS).  The module handles all locking needed to insure that only
a single writer is allowed at any one time.  The selection of CDS was
made to favor speed over absolutely integrity.  This means that if an
error occurs while a change is being written to the database, that the
database will be left in an uncertain state.  Given the overall stability
of BerkeleyDB code, this is unlikely, but still possible.  If absolutely
reliability is required, then one should use the BerkeleyDB directly
and make use of its Transacational Data Store (TDS) capability.>

I<As stated above, it is the author's intent that this model be used
between processes/threads; hence "thread safe" and "fork safe" are goals
that must be achieved in order to be successful.  Care has been
taken to insure that this module achieves this functionality; however,
given the lack of precisely clear definitions for either thread or
fork safety, it is very possible that the author has not adequately
contemplated situations that may cause deadlock or race problems.
As such, the author welcomes any feedback, preferably with corrected
code to address and tests to validate, problems.>

=head1 METHODS

=over

=item ->new()

Creates a new empty queue.

=item ->new(LIST)

Creates a new queue pre-populated with the provided list of items.

=back

=head1 BASIC METHODS

The following methods deal with queues on a FIFO basis.

=over

=item ->enqueue(LIST)

Adds a list of items onto the end of the queue.

=item ->dequeue()

=item ->dequeue(COUNT)

Removes the requested number of items (default is 1) from the head of the
queue, and returns them.  If the queue contains fewer than the requested
number of items, then the thread will be blocked until the requisite number
of items are available (i.e., until other threads <enqueue> more items).

=item ->dequeue_nb()

=item ->dequeue_nb(COUNT)

Removes the requested number of items (default is 1) from the head of the
queue, and returns them.  If the queue contains fewer than the requested
number of items, then it immediately (i.e., non-blocking) returns whatever
items there are on the queue.  If the queue is empty, then C<undef> is
returned.

=item ->pending()

Returns the number of items still in the queue.

=back

=head1 ADVANCED METHODS

The following methods can be used to manipulate items anywhere in a queue.

TODO - modify this section to use BerkelyDB cds_lock.  Will need to add method
to return  $dbh to caller.

To prevent the contents of a queue from being modified by another thread
while it is being examined and/or changed, L<lock|threads::shared/"lock
VARIABLE"> the queue inside a local block:

    {
        my lk = $q->dbh->cds_lock();
        my $item = $q->peek();
        if ($item ...) {
            ...
        }
    }
    # Queue is now unlocked

=over

=item ->peek()

=item ->peek(INDEX)

Returns an item from the queue without dequeuing anything.  Defaults to the
the head of queue (at index position 0) if no index is specified.  Negative
index values are supported as with L<arrays|perldata/"Subscripts"> (i.e., -1
is the end of the queue, -2 is next to last, and so on).

If no items exists at the specified index (i.e., the queue is empty, or the
index is beyond the number of items on the queue), then C<undef> is returned.

Remember, the returned item is not removed from the queue, so manipulating a
C<peek>ed at reference affects the item on the queue.

=item ->insert(INDEX, LIST)

Adds the list of items to the queue at the specified index position (0
is the head of the list).  Any existing items at and beyond that position are
pushed back past the newly added items:

    $q->enqueue(1, 2, 3, 4);
    $q->insert(1, qw/foo bar/);
    # Queue now contains:  1, foo, bar, 2, 3, 4

Specifying an index position greater than the number of items in the queue
just adds the list to the end.

Negative index positions are supported:

    $q->enqueue(1, 2, 3, 4);
    $q->insert(-2, qw/foo bar/);
    # Queue now contains:  1, 2, foo, bar, 3, 4

Specifying a negative index position greater than the number of items in the
queue adds the list to the head of the queue.

=item ->extract()

=item ->extract(INDEX)

=item ->extract(INDEX, COUNT)

Removes and returns the specified number of items (defaults to 1) from the
specified index position in the queue (0 is the head of the queue).  When
called with no arguments, C<extract> operates the same as C<dequeue_nb>.

This method is non-blocking, and will return only as many items as are
available to fulfill the request:

    $q->enqueue(1, 2, 3, 4);
    my $item  = $q->extract(2)     # Returns 3
                                   # Queue now contains:  1, 2, 4
    my @items = $q->extract(1, 3)  # Returns (2, 4)
                                   # Queue now contains:  1

Specifying an index position greater than the number of items in the
queue results in C<undef> or an empty list being returned.

    $q->enqueue('foo');
    my $nada = $q->extract(3)      # Returns undef
    my @nada = $q->extract(1, 3)   # Returns ()

Negative index positions are supported.  Specifying a negative index position
greater than the number of items in the queue may return items from the head
of the queue (similar to C<dequeue_nb>) if the count overlaps the head of the
queue from the specified position (i.e. if queue size + index + count is
greater than zero):

    $q->enqueue(qw/foo bar baz/);
    my @nada = $q->extract(-6, 2);   # Returns ()         - (3+(-6)+2) <= 0
    my @some = $q->extract(-6, 4);   # Returns (foo)      - (3+(-6)+4) > 0
                                     # Queue now contains:  bar, baz
    my @rest = $q->extract(-3, 4);   # Returns (bar, baz) - (2+(-3)+4) > 0

=back

=head1 NOTES

Queues created by L<Thread::Queue> can be used in both threaded and
non-threaded applications.

=head1 LIMITATIONS

Passing objects on queues may not work if the objects' classes do not support
sharing.  See L<threads::shared/"BUGS AND LIMITATIONS"> for more.

Passing array/hash refs that contain objects may not work for Perl prior to
5.10.0.

=head1 SEE ALSO

Thread::Queue Discussion Forum on CPAN:
L<http://www.cpanforum.com/dist/Thread-Queue>



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

This work is based directly upon L<Threads::Queue> Version 2.12 maintained by
Jerry D. Hedden, <jdhedden AT cpan DOT org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 lbe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

