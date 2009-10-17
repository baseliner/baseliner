package Baseliner::Role::Namespace::Application;
use Moose::Role;

with 'Baseliner::Role::Namespace';

requires 'checkout';

1;
