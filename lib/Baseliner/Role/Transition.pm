package Baseliner::Role::Transition;
use Moose::Role;

with 'Baseliner::Role::Baselined';

requires 'promote';
requires 'demote';
requires 'state';

=head1 DESCRIPTION

Something that can be promoted or demoted.

=cut

1;

