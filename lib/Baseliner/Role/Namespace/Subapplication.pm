package Baseliner::Role::Namespace::Subapplication;
use Moose::Role;

with 'Baseliner::Role::Namespace';

requires 'checkout';

1;
