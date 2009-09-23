package Baseliner::Core::User::LDAP;
use Moose;
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Authentication::Store::LDAP::User'; }

with 'Baseliner::Role::User';

1;
