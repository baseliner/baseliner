package Baseliner::Role::Service;
use Moose::Role;

has 'log' => ( is=>'rw', isa=>'BaselinerX::Type::Service::Logger', required=>1 );

1;
