package Baseliner::Role::Namespace::Package;
use Moose::Role;

with 'Baseliner::Role::Namespace::Tag';
with 'Baseliner::Role::Approvable';
with 'Baseliner::Role::Transition';
with 'Baseliner::Role::Baselined';

requires 'created_on';
requires 'created_by';

=head1 DESCRIPTION

Just like a tag, but that can be promoted, demoted, approved, etc..

=cut

1;
