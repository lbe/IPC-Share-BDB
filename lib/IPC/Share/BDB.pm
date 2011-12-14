package IPC::Share::BDB;

use 5.006;
use strict;
use warnings;
use BerkeleyDB;

our @ISA = qw( BerkeleyDB::Env );

=head1 NAME

IPC::Share::BDB - The great new IPC::Share::BDB!

=head1 VERSION

Version 0.01_01

=cut

our $VERSION = '0.01_01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use IPC::Share::BDB;

    my $foo = IPC::Share::BDB->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {

    # Usage:
    #
    #	$env = new BerkeleyDB::Env
    #			[ -Home		=> $path, ]
    #			[ -Mode		=> mode, ]
    #			[ -Config	=> { name => value, name => value }
    #			[ -ErrFile   	=> filename, ]
    #			[ -ErrPrefix 	=> "string", ]
    #			[ -Flags	=> DB_INIT_LOCK| ]
    #			[ -Set_Flags	=> $flags,]
    #			[ -Cachesize	=> number ]
    #			[ -LockDetect	=>  ]
    #			[ -Verbose	=> boolean ]
    #			[ -Encrypt	=> { Password => string, Flags => value}
    #
    #			;

    my $self = shift;
    my $class = ( ref $self ) || $self;

    my @args = BerkeleyDB::ParseParameters( 
        {
            Home  => "/tmp/bdb",
            Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL
        },
        @_
    );
        
    $self = $class->SUPER::new( @args ) or die "cannot open environment: $BerkeleyDB::Error\n";
    return($self);
}

=head2 function2

=cut

    sub function2 {
    }

=head1 AUTHOR

lbe, C<< <learnedbyerror at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc::share::bdb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC::Share::BDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::Share::BDB


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

    1;    # End of IPC::Share::BDB
