package Baseliner::Role::Namespace::Item;
use Moose::Role;

with 'Baseliner::Role::Namespace';

# attributes
requires 'name';

# methods
requires 'checkout';

=head1 DESCRIPTION

A change element. An artefact.

=cut

1;
