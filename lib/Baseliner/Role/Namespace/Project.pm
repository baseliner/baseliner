package Baseliner::Role::Namespace::Application;
use Moose::Role;

with 'Baseliner::Role::Namespace';

requires 'checkout';

=head1 DESCRIPTION

A project is directory that belongs to a subapplication. 

=cut

1;
