package Baseliner::Role::Namespace::Tag;
use Moose::Role;

with 'Baseliner::Role::Namespace';

requires 'checkout';

1;
