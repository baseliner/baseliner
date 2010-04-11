package BaselinerX::Nature::J2EE::Common;
use Baseliner::Plug;
use Baseliner::Utils;

sub list_J2EE_namespaces  {
    my ( $self, $c ) = @_;
    my @NS;
    my @ns_list = $c->model('Namespaces')->namespaces();
    for my $ns ( @ns_list ) {
    	push @NS, [$ns->ns, $ns->ns_text ] 
    			if( $ns->ns eq '/' 
    				|| $ns->ns =~ m{^application}
    				|| $ns->ns =~ m{^harvest.subapplication}
    				|| $ns->ns =~ m{^harvest.package}
    			);
    }
    
    $c->stash->{namespaces} = \@NS;
}

sub getFileLOB {
    my ( $self, $filePath) = @_;
	my $buff = qq{};
    open( my $FL, '<', $filePath ) or return -1;
	binmode($FL); 
	$buff = join('',<$FL>);
	close $FL;
    return $buff;	
}

sub getDeployType{
     my ( $self, $elements, $application, $bl ) = @_;	
     $elements = $elements->cut_to_subset( 'application', $application );
     my ($package) = $elements->list('packages'); 
     
	 my $rs = Baseliner->model('Baseliner::BaliConfig')->search({ ns=>'harvest.package/$package', bl=>$bl, key=>'config.j2ee.deploy.xtype'})
				or die $!;
	if($rs->next){
		
	}	
	
}

1;