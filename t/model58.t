use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Baseliner' }
BEGIN { use_ok 'BaselinerX::Type::Model::Menus' }

my $c = Baseliner->new();

ok( $c->model('Menus') );

