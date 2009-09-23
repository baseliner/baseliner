package Baseliner::Role::Namespace::Branch;
use Moose::Role;

with 'Baseliner::Role::Namespace';

requires 'checkout';

=head1 DESCRIPTION

A branch.

=cut

1;
