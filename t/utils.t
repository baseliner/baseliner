use strict;
use warnings;
use Test::More tests => 20;

$ENV{BALI_CMD} = 1;

require Baseliner;
my $c = Baseliner->new();
Baseliner->app( $c );

use_ok 'Catalyst::Test';
use_ok 'Baseliner::Utils';

#use Baseliner::Utils;

my ( $domain, $item ) = Baseliner::Utils::ns_split( 'application/app name' );

ok( $domain eq 'application', 'domain split' );
ok( $item eq 'app name', 'item split' );

ok( Baseliner::Utils::domain_match( 'harvest.package', 'package' ), 'sub domain match' );
ok( Baseliner::Utils::domain_match( 'harvest.package', 'harvest.package' ), 'full domain match' );
ok( ! Baseliner::Utils::domain_match( 'subapplication', 'application' ), 'no domain mismatch' );
ok( ! Baseliner::Utils::domain_match( 'application', 'subapplication' ), 'no subdomain mismatch' );

ok( Baseliner::Utils::ns_match( 'harvest.package/package name', 'package/' ), 'partial domain match' );
ok( Baseliner::Utils::ns_match( 'harvest.package/package name', 'harvest.package/' ), 'full domain match' );

ok( Baseliner::Utils::ns_match( 'harvest.package/package name', '/package name' ), 'package item match' );
ok( ! Baseliner::Utils::ns_match( 'harvest.package/package name', '/package' ), 'partial item mismatch' );

ok( ! Baseliner::Utils::ns_match( 'harvest.package/package name', 'application/' ), 'mismatch domain' );
ok( ! Baseliner::Utils::ns_match( 'harvest.package/package name', '/package' ), 'mismatch item' );

ok( Baseliner::Utils::ns_match( 'harvest.package/package name', 'package name' ), 'item match fallback' );

ok( 1 eq scalar Baseliner::Utils::_array( qw/aa/ ), 'array of 1' );
ok( 2 eq scalar Baseliner::Utils::_array( [ qw/aa bb/ ] ), 'array of 2' );
ok( 3 eq scalar Baseliner::Utils::_array( qw/aa bb/, 'cc' ), 'array of 3' );
ok( 4 eq scalar Baseliner::Utils::_array( qw/aa bb/, [ 'cc', 'dd' ] ), 'array of 4' );
ok( 5 eq scalar Baseliner::Utils::_array( { aa => 'bb' }, [ 'cc', 'dd' ], 'rr' ), 'array of 5' );


