package Baseliner::Role::Namespace::Nature;
use Moose::Role;

with 'Baseliner::Role::Namespace';

requires 'checkout';

=head1 DESCRIPTION

A physical folder that holds change elements of similar type. 

=cut

1;
