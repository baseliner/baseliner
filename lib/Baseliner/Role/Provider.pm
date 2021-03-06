package Baseliner::Role::Provider;
use Moose::Role;
use Baseliner::Utils;

requires 'find';   # by some primary key
requires 'list';

requires 'namespace';    # the package class it works with
requires 'domain';       # for identifying its objects

sub not_implemented {
	my $self = shift;
	my ($package, $filename, $line) = caller;
	_throw $self->domain . " not implemented yet.";
}

# search? as in ->search( 'owner', /dude/ );

=head1 DESCRIPTION

A Provider has methods to create a collection of namespace objects.

For now, this collection is an array. In the future, should be some CPAN package,
a propietary collection object or a hash even.

=cut
1;
