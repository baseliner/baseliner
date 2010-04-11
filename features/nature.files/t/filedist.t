use strict;
use warnings;
use Test::More tests => 1;
    use BaselinerX::Type::Config;

BEGIN { use_ok 'Catalyst::Test', }

    require Baseliner;
    my $c = Baseliner->commandline;
    Baseliner->app( $c );

	my @mappings = ();
	my $rs = Baseliner->model('Baseliner::BaliFileDist')->search();
	while(my $r = $rs->next){
        my $row = { $r->get_columns };
		push @mappings, { 
            ns => $row->{ns},
            bl => $row->{bl},
            value => $row,
        };
	}

    my @v = BaselinerX::Type::Config::best_match_on_viagra( 'harvest.package/GBP.328.N-000002_carga_inicial', 'DESA', @mappings  );

    use YAML;
    print Dump [ @v ];
