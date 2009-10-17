package Baseliner::Role::Approvable;
use Moose::Role;

requires 'approve';
requires 'reject';
requires 'is_approved';
requires 'is_rejected';
requires 'user_can_approve';

=head1 DESCRIPTION

Something that can be approved. 

=cut

1;

