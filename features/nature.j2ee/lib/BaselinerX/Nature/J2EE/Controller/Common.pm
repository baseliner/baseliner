package BaselinerX::Nature::J2EE::Controller::Common;
use Baseliner::Plug;
use Baseliner::Utils;

BEGIN { extends 'Catalyst::Controller' }
use YAML;
use JavaScript::Dumper;

sub list_packages : Path('/j2ee/list_packages') {
    my ( $self, $c ) = @_;
    my @NS;
    my @ns_list = $c->model('Namespaces')->namespaces();
    for my $ns ( @ns_list ) {
    	push @NS, [$ns->ns, $ns->ns_text ] 
    			if( $ns->ns eq '/' 
    				|| $ns->ns =~ m{^/nature/J2EE}
    				|| $ns->ns =~ m{^/apl}
    				|| $ns->ns =~ m{^/package}
    			);
    }
    $c->stash->{namespaces} = \@NS;
}

1;