use strict;
use warnings;
use Test::More tests => 12;

$ENV{BALI_CMD} = 1;

require Baseliner;
my $c = Baseliner->new();
Baseliner->app( $c );

use_ok 'Catalyst::Test';
use_ok 'Baseliner::Utils';

ok( my $n = $c->model('Namespaces'), 'model namespaces' );

my @providers = $n->find_providers_for( domain=>'package' );

ok( scalar @providers, 'find providers for a domain' );

{
    ok( my $root = $n->get('/') , 'get root namespace');

    ok( $root->parents, 'root parents is empty' );
}

{
    ok( my $item = $n->get( 'harvest.package/GBP.328.N-000002 carga inicial' ), 'found package with exact name' );
    ok( $item->isa('BaselinerX::CA::Harvest::Namespace::Package'), 'isa package');
}

{
    ok( my $item = $n->get( 'package/GBP.328.N-000002 carga inicial' ), 'found package with a package domain' );
    ok( $item->does('Baseliner::Role::Namespace::Package'), 'does role package');
    my @parents = $item->parents;
    print join ',',@parents, "\n";

    ok( scalar @parents, 'has parents' );

    ok( grep( m{application/GBP.328}, @parents ),
            'belongs to app GBP.328' );
}


