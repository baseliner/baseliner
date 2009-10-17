package BaselinerX::Type::Model::ConfigStore;
use Moose;
extends qw/Catalyst::Model/;
#with 'Catalyst::Component::InstancePerContext';

no Moose;
use Baseliner::Utils;

# stores a hashref of long.keys => value
sub store_long {
	my ($self, %p ) = @_;
	my $data = $p{data};
	$p{ns} ||= '/';
	$p{bl} ||= '*';
	for my $key ( keys %{ $p{data} || {} } ) {
        my $rs = Baseliner->model('Baseliner::BaliConfig')->search({ ns=>$p{ns}, bl=>$p{bl}, key=>$key })
				or die $!;	
        my $exist = 0;		
        while( my $r = $rs->next ) {
            $r->value( $data->{ $key } );
            $r->update;
            $exist = 1;
        }		

        #TODO check for duplicates

        #TODO if bl=DESA and bl=* values are equal, don't store

        # Modificado para que en caso de que no exista la clave la cree
        unless($exist){
            my $r = Baseliner->model('Baseliner::BaliConfig')->create({
                    ns => $p{ns},
                    bl => $p{bl},
                    key => $key,
                    value => $data->{$key},					
                });
            $r->update;
        }
    }
	return 1;
}

=head2 get

The one and definitive way to get things out of the Config table. 

Can check one or more keys.

Options:
    
    long_key : uses the full key "config.etc.etc" as hash key names.

    stash    : stashes the return value in the $c->stash->{inf}->{..}

Returns a hashref to the config data structure. 

=cut
use BaselinerX::Type::Config;
sub get {
	my ($self, $key, %p ) = @_;
	$p{ns} ||= '/';
	$p{bl} ||= '*';
    my $data = $p{data} || {};
    my $enforce_metadata = delete $p{enforce_metadata};
    my $long_key = $p{long_key};
	my $rs = Baseliner->model('Baseliner::BaliConfig')->search({ key=>{ -or=>[ {-like=>"$key.%" } , {-like=>"$key" } ]  } });
    my %values;

    # load all values for the keyinto a temp hash
	while( my $r = $rs->next  ) {
        push @{ $values{$r->key} }, { ns=>$r->ns, bl=>$r->bl, value=>$r->value };
	}	

    # now find the best_match
    foreach my $k ( keys %values ) {
        if( $k =~ /^(.*)\.(.*?)$/ ) {  # get the last word as value
            my $k1 = $1;
            my $k2 = $2;
            my $value = BaselinerX::Type::Config::best_match_on_viagra( $p{ns}, $p{bl}, @{ $values{$k} || [] } );
            $data->{ $long_key ? $k : $k2} = $value;
        }
    }

    # if no data found, use default values
    my $config;
    my $single_key = 0;
    eval { $config = Baseliner->registry->get( $key ) };
    if( $@ || !$config ) {  # try a shorter key if the key is not found
        eval { $config = Baseliner->registry->get( _cut(-1, '\.', $key ) ) };
        $single_key = 1 unless $@;
    }
    if( defined $config && blessed($config) eq 'BaselinerX::Type::Config' ) {
        foreach my $item ( @{ $config->metadata || [] } ) {
            my $data_key = $long_key ? $key.$item->{id} : $item->{id};

            # use default value ?
            $data->{ $data_key } = $item->{default}
                unless exists $data->{ $data_key }; 

            # expand key type
            $data->{$data_key} = $self->_expand( $item->{type}, $data->{ $data_key } );

            # resolve vars
            my $new_value = $data->{ $data_key } || '';
			$new_value =~ s/\$\{ns\}/$p{ns}/g ; 
            $new_value =~ s/\$\{bl\}/$p{bl}/g ; 
            $new_value =~ s/\$\{key\}/$key/g ; 
            $new_value =~ s/\$\{id\}/$item->{id}/g;
            if( ref $p{vars} eq 'HASH' ) {

                # now the rest
                foreach my $var ( keys %{ $p{vars} } ) {
                   my $variable = '${' . $var . '}';
                   my $var_value = $p{vars}{$var};
                   $new_value =~ s/\Q$variable\E/$var_value/g;
                }
            }
            $data->{ $data_key } = $new_value;

            # callbacks
            if( ref $p{callback} eq 'CODE' ) {
                #TODO - maybe it's not necessary
            }

        }
    } else {
        my $msg = _loc( "Could not find the metadata for the key '$key' in the registry." );
        if   ($enforce_metadata) { die($msg) }
        else                     { _loc($msg) }
    }
    
    if( $p{value} ) {
        my ( $first_key ) = keys %{ $data || {} };
        return $data->{ $first_key };
    } else {
        return $data;
    }
}

# convert value data to metadata type
sub _expand {
    my ( $self, $type, $value ) = @_;
    if( defined $type && $type eq 'hash' ) {
        return eval "{ $value }";
    } else {
        return $value;
    }
}

# find to which config object this key belongs to (config.my.stuff.key => config.my.stuff )
sub ns_config {
    my ($self, $key ) = @_;
    #TODO pending     
}

# just give me all keys
sub all_keys {
    my ($self) = @_;
	return Baseliner::Core::Registry->starts_with('config');
}

# just give me all config objects
sub all {
    my ($self) = @_;
    my @configs;
    foreach my $key ( $self->all_keys ) {
        push @configs, Baseliner->registry->get( $key );
    }
    return @configs;
}
    
# get all config keys available for a ns
sub filter_ns {
    my ($self, $ns, $bl ) = @_;
    $ns ||= '/';
    my $search = { ns=>$ns };
    $search->{bl} = $bl if( $bl );
    my $rs = Baseliner->model('Baseliner::BaliConfig')->search($search);
    my %keys;
    while( my $r = $rs->next ) {
        $keys{ $r->key } = ();
    }
    return keys %keys;
}

sub set {
	my ($self,%p) = @_;
	my $ns = $p{ns} || '/';
	my $bl = $p{bl} || '*';
	_throw 'Missing parameter key' unless $p{key};
	_throw 'Missing parameter value' unless defined $p{value};
	my $rs = Baseliner->model('Baseliner::BaliConfig')->search({ key=>$p{key}, ns=>$ns, bl=>$bl });
	if( ref $rs ) {
		while( my $r = $rs->next ) {
			$r->delete;
		}
	} 
	my $row = Baseliner->model('Baseliner::BaliConfig')->create({ key=>$p{key}, value=>$p{value}, ns=>$ns, bl=>$bl });
	$row->update;
	return $row;
}
1;
