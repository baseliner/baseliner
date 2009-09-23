package BaselinerX::CA::Endevor::Provider::Packages;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::CA::Endevor;
use BaselinerX::CA::Endevor::Namespace::Package;

with 'Baseliner::Role::Provider';

register 'namespace.endevor.package' => {
	name	=>_loc('Endevor Packages'),
	root    => 'endevor.package',
	can_job => 1,
    finder  => \&find,
    handler => \&list,
};

sub domain { 'endevor.package' }
sub namespace { 'BaselinerX::CA::Endevor::Namespace::Package' }

sub find {
    my ($self, $c, $p) = @_;
    #TODO  check the list and find a value, but $self is not this package
    return undef;
}

sub list {
    my ($self, $c, $p) = @_;
    my $bl = $p->{bl};
    my $job_type = $p->{job_type};
    my $query = $p->{query};
    my $sql_query;
    
    my $inf = Baseliner->registry->get( 'config.endevor.connection' )->factory( 'Baseliner', bl=>$bl );
    #my $inf = Baseliner->inf( bl=>$bl, domain=>'config.endevor.connection');

    my @ns;
    eval {
        alarm $inf->{timeout};
        $SIG{ALRM}=sub { die _loc "Timeout Error (timeout=".$inf->{timeout}."s) while connected to MVS" };
        my $ret;

        ## Retrieve endevor packages
        my %pkgs;
        my $cache_key = 'endevor.packages';
        my $cache = $c->cache( backend=>'endevor' );
        if( my $cached = $cache->get( $cache_key )  ) {
            #warn "Tirando de cache.... \n\n " . Dump( $cached ) . "\n\n ";
            %pkgs = %{ $cached || {} };
        } else {
            my $e = BaselinerX::CA::Endevor->new( host=>$inf->{host}, user=>$inf->{user}, pw=>$inf->{pw}, surr=>$inf->{surr}, class=>$inf->{class});
            %pkgs = $e->pkgs;
            $cache->set( $cache_key, \%pkgs );
        }

        ## Provide Namespace list
        my $ns_type= _loc('Endevor Package');
        for my $pkg ( keys %pkgs ) {
            my $pkg_data = $pkgs{$pkg};
            my $status = $pkg_data->{STATUS};
            my $can_job = 1;
            my $why_not = '';
            if( $job_type ) { 
                for( $job_type ) {
                    if( /promote/ ) { 
                        if( $status ne 'APPROVED' ) {
                            $can_job = 0;
                            $why_not = _loc('Package has not been approved');
                            next; #TODO delete this when why_not and can_job work in the interface
                        }
                        if( $pkg_data->{PROM_PKG} ne 'Y' ) {
                            $can_job = 0;
                            $why_not = _loc('Package is not a Promotion Package');
                            next; #TODO delete this when why_not and can_job work in the interface
                        }
                        if( substr($pkg_data->{PROM_TGT_ENV},0,3) ne substr($bl,0,3) ) {
                            next;
                        }
                    }
                    elsif( m/rollback|demote/i ) {
                        if( $status !~ m/EXECUTED|IN-EXECUTION|EXEC-FAILED/i ) {
                            $can_job = 0;
                            $why_not = _loc('Package has not been executed');
                            next; 
                        }
                        if( substr($pkg_data->{PROM_TGT_ENV},0,3) ne substr($bl,0,3) ) { #TODO packages de backout always prod
                            next;
                        }
                        if( $pkg_data->{PKG_BACKOUT_STATUS} eq 'BACKED-OUT' ) {
                            $can_job = 0;
                            $why_not = _loc('Package has already been backed-out');
                            next; 
                        }
                        if( $pkg_data->{BACKOUT_FLG} ne 'Y' ) {
                            $can_job = 0;
                            $why_not = _loc('Package is not available for backout');
                            next; 
                        }
                    }
                } 
            }
            # _log "PKG=$pkg, TYPE=",$pkg_data->{'PKG_TYPE'},",STATUS=$pkg_data->{'STATUS'}, DESC=$pkg_data->{DESCRIPTION}, TARGET_ENV=$pkg_data->{PROM_TGT_ENV}\n";
            next if( $query && !query_array($query, $ns_type, $pkg, $pkg_data->{CREATE_DATE}, $pkg_data->{CREATE_USRID} ));
            push @ns, BaselinerX::CA::Endevor::Namespace::Package->new({
                    ns      => 'endevor.package/' . $pkg,
                    ns_name => $pkg,
                    ns_info => $pkg,
                    user    => $pkg_data->{CREATE_USRID},
                    date    => $pkg_data->{CREATE_DATE} . ' '. $pkg_data->{CREATE_TIME},
                    icon    => '/static/images/scm/package.gif',
                    can_job => $can_job,
                    service => 'service.endevor.runner.package',
                    why_not => $why_not,
                    ns_type => $ns_type,
                    ns_id   => $pkg,
                    ns_data => $pkg_data,
                    provider=> 'namespace.endevor.package',
             });
        }
        $ret && (my $rc = $ret)=~ s{^.*Highest return code is (\d+).*$}{$1}sg; 
        $rc && _log "\n\nRETURN CODE = [".$rc."]\n";
        #warn " Endev Namespaces: " . Dump(\@ns) . " ";
        alarm 0;
    };
    alarm 0;
    _log "ERROR: $@" if $@;
    return \@ns;
} 

1;

