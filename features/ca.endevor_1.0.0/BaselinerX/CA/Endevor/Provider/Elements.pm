package BaselinerX::CA::Endevor::Provider::Elements;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Provider';

use BaselinerX::CA::Endevor;
use BaselinerX::CA::Endevor::Namespace::Element;

use YAML::Syck;

register 'namespace.endevor.element' => {
	name	=>_loc('Endevor Elements'),
	domain  => 'endevor.item',
    finder  => \&find,
	handler => \&list,
};

sub namespace { 'BaselinerX::CA::Endevor::Namespace::Element' }
sub domain { 'endevor.item' }
sub find {
    #TODO find endevor ns 
}

sub list {
    my ($self, $c, $p) = @_;
    my $bl = $p->{bl};
    my $query = $p->{query};

    my $inf = Baseliner->registry->get( 'config.endevor.connection' )->factory( 'Baseliner', bl=>$bl );
return []; #TODO no funciona cache??
    my @ns;
    eval {
        alarm $inf->{timeout};
        $SIG{ALRM}=sub { die _loc "Timeout Error (timeout=".$inf->{timeout}."s) while connected to MVS" };

        ## Retrieve endevor packages
        my %elems;
        my $cache_key = 'endevor.elements';
        my $cache = $c->cache( backend=>'endevor' );
        if( (!$p->{nocache}) && ( my $cached = $cache->get( $cache_key ) ) ) {
            #warn "Tirando de cache.... \n\n " . Dump( $cached ) . "\n\n ";
            %elems = %{ $cached || {} };
        } else {
            my $e = BaselinerX::CA::Endevor->new( host=>$inf->{host}, user=>$inf->{user}, pw=>$inf->{pw}, surr=>$inf->{surr}, class=>$inf->{class});
            %elems = $e->elems;
            $cache->set( $cache_key, \%elems );
        }
        alarm 0;

        my $ns_type = 'Endevor Element';

        foreach my $elem ( keys %elems ) {
            my $data = $elems{$elem};
            my $version = $data->{'ELM_VV'} . '.' . $data->{'ELM_LL'} ;
            my $username = $data->{'LAST_ACT_USRID'};
            my $modified_on = parse_dt( '%Y/%m/%d %H:%M', $data->{'LAST_ACT_DATE'} . " ". $data->{'LAST_ACT_TIME'} );
            next if( $query && !query_array($query, $ns_type, $elem, $data->{CREATE_DATE}, $data->{CREATE_USRID} ));
            push @ns,
              BaselinerX::CA::Endevor::Namespace::Element->new(
                {
                    ns          => 'endevor.item/' . $elem,
                    ns_name     => $elem,
                    ns_info     => $elem,
                    ns_type     => $ns_type,
                    version     => $version,
                    ns_id       => $elem,
                    ns_data     => $data,
                    name        => $elem,
                    modified_by    => $username,
                    modified_on => $modified_on,
                    icon        => '/static/images/scm/version.gif',
                    provider    => 'namespace.endevor.element',
                }
              );
        }
    };
    alarm 0;
    _log "ERROR: $@" if $@;
    return \@ns;
}

1;
