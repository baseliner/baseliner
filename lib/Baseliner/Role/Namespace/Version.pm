package Baseliner::Role::Namespace::Version;
use Moose::Role;

with 'Baseliner::Role::Namespace::Item';

requires 'version';
requires 'checkout';
requires 'modified_on';
requires 'modified_by';

=head1 DESCRIPTION

A change element version, with content. 

=cut

1;
