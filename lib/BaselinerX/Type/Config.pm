package BaselinerX::Type::Config;
use Baseliner::Plug;
use Baseliner::Utils;
use YAML::Syck;
use JavaScript::Dumper;
use Try::Tiny;
with 'Baseliner::Role::Registrable';

register_class 'config' => __PACKAGE__;

has name 	=> ( is=> 'rw', isa=> 'Str' );
has desc 	=> ( is=> 'rw', isa=> 'Str' );
has metadata => ( is=> 'rw', isa=> 'ArrayRef' );  ##TODO this shall be a Moose subtype someday, an array of ConfigColumn
has formfu 	=> ( is=> 'rw', isa=> 'ArrayRef', default=> sub { [] } );
has 'plugin' => (is=>'rw', isa=>'Str', default=>'');
has 'id' => (is=>'rw', isa=>'Str', default=>'');
has 'preference' => (is=>'rw', isa=>'Bool', default=>0 );

# load config from the namespace tree
sub load_from_ns {
	my $self = shift;
}

# Setup the Config Infraestructure Globals
sub setup_inf {
	my $c=shift;
	
}

sub column_order {
	my $self=shift;
	my @cols = ();
	push @cols, $_->{id} for( @{$self->metadata} );
	return @cols;
}

# returns a subset limited to a set of keys
sub metadata_filter {
    my ($self, @keys) = @_;
    my %key; 
    @key{ @keys } = ();
    my @metadata;
    foreach my $mk ( @{ $self->metadata || [] } ) {
       my $mk_key = join '.', $self->key, $mk->{id};
       push @metadata, $mk if( exists $key{$mk_key} ); 
    }
    return @metadata;
}

sub best_match {
    my ($ns,$bl,@values) = @_;
    my $val;
    for( @values ) {
        $val = $_->{value} if( ($_->{bl} eq $bl) && ($_->{ns} eq $ns) );
    }
    unless( defined $val || ($ns eq '/' && $bl eq '*') ) {
        if( $bl ne '*' ) {
            return best_match( $ns, '*', @values );
        }
        else {
            if( $ns ne '/' ) {
                my @ns2 = split /\//, $ns;
                $ns = join "/", @ns2[ 0..(scalar(@ns2)-2) ]; 
                #Para evitar un bucle infinito...
                $ns = "/" if($ns eq "");
                return best_match( $ns, '*', @values );
            } else {
                return best_match( '/', '*', @values );
            }
        }
    }
    return $val;
}

# the best best_match
our %parents_cache;
sub best_match_on_viagra {
    my ($ns,$bl,@values) = @_;
    my @ret;
    for( @values ) {
        push @ret, $_->{value}
            if( ($_->{bl} eq $bl) && ($_->{ns} eq $ns) );
    }
    unless( @ret || ($ns eq '/' && $bl eq '*') ) {
        if( $bl ne '*' ) {
            return best_match_on_viagra( $ns, '*', @values );
        }
        else {
            if( $ns ne '/' ) {
                try {
                    my $ns_obj = Baseliner->app->model('Namespaces')->get( $ns );
                    return unless defined $ns_obj;
                    my @parents;
                    if( ref $parents_cache{$ns} eq 'ARRAY' ) {
                        @parents = @{ $parents_cache{ $ns } };
                    } else {
                        @parents = $ns_obj->parents;
                        $parents_cache{ $ns } = [ @parents ];
                    }
                    foreach my $parent ( @parents ) {
                        @ret = best_match_on_viagra( $parent, '*', @values );
                        return @ret if @ret;
                    }
                } catch {
                     die shift;
                };
            } else {
                return best_match_on_viagra( '/', '*', @values );
            }
        }
    }
    return wantarray ? @ret : $ret[0];
}

sub expand_keys {
    my ( $key, $data ) =@_;
    return {
        map { $key.'.'.$_ => $data->{$_} } keys %{ $data || {} }
    };
}

=head2 factory

Creates a config data object, mixing param + table + default

	$config_data = $config->factory( $c, ns=>$ns, bl=>$bl, getopt=>1, data=>{ some_key => 'S' } );

1) Getopt if getopt=>1
2) data=>{ } hash value
3) config table
4) metadata field default
5) default_data=>{ } hash value

=cut
sub factory {
	my ($self, $c, %p ) = @_;
	$p{ns} ||= '/';
	$p{bl} ||= '*';
	my $data = $p{data} || {};
    my $long_key = $p{long_key};
	my $default_data = $p{default_data} || {};
	for( @{$self->metadata} ) {
		next if defined $data->{ $_->{id} }; 
		## load missing from table
			my $rs = Baseliner->model('Baseliner::BaliConfig')->search({ key=>$self->key.'.'.$_->{id} }) or die $!;
	        my @values;
			while( my $r = $rs->next ) {
	            push @values, { ns=>$r->ns, bl=>$r->bl, value=>$r->value };
	            if( ($r->bl eq $p{bl}) ) {
	            }
			}
	        if( defined ( my $value = best_match( $p{ns}, $p{bl}, @values ) ) ) {
	            $data->{ $_->{id} } = $value
	        } elsif( defined $default_data->{ $_->{id} } ) {
	        	$data->{ $_->{id} } = $default_data->{ $_->{id} };
	        } else {
                $data->{ $_->{id} } = $_->{default};
            }
	}
	$data = $self->getopt( $data ) if $p{getopt};
    $data = expand_keys($self->key, $data) if $long_key;
	return $data;
}


=head2 data( [ns=>$ns, bl=>$bl, data=>{} ] );

Simple data object creation for config objects.

=cut
sub data {
	my ($self, %p ) = @_;
	$p{ns} ||= '/';
	$p{bl} ||= '*';
	my $data = $p{data} || {};
	for( @{$self->metadata} ) {
		next if defined $data->{ $_->{id} };  ## data=> params have priority
		my $rs = Baseliner->model('Baseliner::BaliConfig')->search({ ns=>$p{ns}, bl=>$p{bl}, key=>$self->key.'.'.$_->{id} })
			or die $!;			
		while( my $r = $rs->next ) {
			$data->{ $_->{id} } = $r->value;
		}
		unless( defined $data->{ $_->{id} } ) {  ## get default value
			$data->{ $_->{id} } = $_->{default};
		}
	}
	return $data;
}

##Este metodo se apoya en store solo que envia como parametro del formulario el namespace y el baseline
sub factory_from_metadata{
	my($self,$c,%p) = @_;
	$p{ns} ||= '/';
	$p{bl} ||= '*';
	my $data = $p{data} || {};
	
	for( @{$self->metadata} ) {
		next unless defined $data->{ $_->{id} };
		if($_->{id} eq 'ns'){
			$p{ns} = $data->{ $_->{id} };
		}elsif($_->{id} eq 'bl'){
			$p{bl} = $data->{ $_->{id} };			
		}
	}		
	
	$p{ns} ||= '/';
	$p{bl} ||= '*';

	for( @{$self->metadata} ) {
		next if defined $data->{ $_->{id} }; 
		## load missing from table
		if($_->{id} ne 'ns' && $_->{id} ne 'bl' ){		
			my $rs = $c->model('Baseliner::BaliConfig')->search({ key=>$self->key.'.'.$_->{id} }) or die $!;
	        my @values;
			while( my $r = $rs->next ) {
	            push @values, { ns=>$r->ns, bl=>$r->bl, value=>$r->value };
	            if( ($r->bl eq $p{bl}) ) {
	            	$data->{ $_->{id} } = $r->value;	            	
	            }
			}
	        if( my $value = best_match( $p{ns}, $p{bl}, @values ) ) {
	            $data->{ $_->{id} } = $value
	        }
		}
	}
	$data = $self->getopt( $data ) if $p{getopt};
	return $data;		
}

=head2 store

Parameters:
    long_key=>1  - takes long keys like config.something.field instead of just "field"

=cut 
sub store {
	my ($self, $c, %p ) = @_;
	my $data = $p{data};
	$p{ns} ||= '/';
	$p{bl} ||= '*';
	for( @{$self->metadata} ) {
		next unless defined $data->{ $_->{id} };
		if($_->{id} ne 'ns' && $_->{id} ne 'bl' ){
            my $key = $p{long_key} ? $_->{id} : $self->key.'.'.$_->{id} ;
			my $rs = $c->model('Baseliner::BaliConfig')->search({ ns=>$p{ns}, bl=>$p{bl}, key=>$key })
				or die $!;	
			my $exist = 0;		
			while( my $r = $rs->next ) {
				$r->value( $data->{ $_->{id} } );
				$r->update;
				$exist = 1;
			}		
			# Modificado para que en caso de que no exista la clave la cree
			if($exist eq 0){
				my $r = $c->model('Baseliner::BaliConfig')->create(
					{
						ns => $p{ns},
						bl => $p{bl},
						key => $key,
						value => $data->{ $_->{id}},					
						
					}
				);
			
				$r->update;
			}
		}
	}
	return 1;
}


##Este metodo se apoya en store solo que envia como parametro del formulario el namespace y el baseline
sub store_from_metadata{
	my($self,$c,%p) = @_;
	my $data = $p{data};
	
	for( @{$self->metadata} ) {
		next unless defined $data->{ $_->{id} };
		if($_->{id} eq 'ns'){
			$p{ns} = $data->{ $_->{id} };
		}elsif($_->{id} eq 'bl'){
			$p{bl} = $data->{ $_->{id} };			
		}
	}
	
	return store($self,$c,%p);		
}

sub grid_columns { 
	my $self=shift;
	my @cols;
    ## {header: "Modificado", width:80, dataIndex: 'modificado', sortable: true, hidden: true },
	for( @{$self->metadata || [] } ) {
        push @cols,
          {
            header    => $_->{label},
            width     => ( $_->{width} || 80 ),
            dataIndex => $_->{id},
            sortable  => ( $_->{sortable} || \1 ),
            hidden    => ( $_->{hidden} || \0 )
          }
	}
	return \@cols;
}

sub grid_fields { 
	my $self=shift;
	my @data;
	for( @{$self->metadata || [] } ) {
		push @data, { name=> $_->{id} };
	}
	return \@data;
}

# Returns the full key list generated from the config's metadata
sub get_keys {
	my $self=shift;
	my $config = $self->key;
	my @keys;
	push @keys, "$config.$_->{id}" for( @{$self->metadata} ); 
	return @keys;
}

sub rows {
	my ($self,%p) = @_;
	my $config_set = $self->key;
	## order_by is not effective in this query
	my $rs = Baseliner->model('Baseliner::BaliConfig')->search({ key=>{-in=> [ $self->get_keys ] } }, { order_by => [qw/ns/] });
	my $last_ns = '';
	my @rows=();
	my @packed_data=();
	my $data;
	while( my $r = $rs->next ) {
		if( $r->ns ne $last_ns ) {
			if( $data ) {
				$data->{packed_data} = join '|',@packed_data;
				@packed_data = ();
				push @rows, $data;
			}
			$last_ns = $r->ns;
			$data = {};
		}
		my $short = $self->short_from_key( $r->key );
		$data->{$short} = $r->value;
		push @packed_data, $r->value;
	}	
	push @rows, $data if( $data );
	## now order by
	if( $p{sort_field} ) {
		my %r;
		my $i = 0;
		for(@rows) {
			my $val = $_->{ $p{sort_field} };
			next if( $p{query} && ( $_->{packed_data} !~/$p{query}/ ) );
			$r{ $val . "-$i" } = $_;	
			$i++;
		}
		my @sorted = sort keys %r;
		@rows = map { $r{$_} } ( $p{dir} eq 'ASC' ? reverse @sorted : @sorted );
	}
	return @rows;
}

sub load_inf {  #TODO deprecated
	my ($self,$c, $config_set) = @_;
	my $data = {};
	my $rs = $c->model('Baseliner::BaliConfig')->search({ ns=>'/', bl=>'*', key=>{-like=>"$config_set.%" } });
	while( my $r = $rs->next  ) {
		(my $var = $r->key) =~ s{^(.*)\.(.*?)$}{$2}g;
		$data->{$var} = $r->value;
	}	
	return $data;
}

# Loads key aliases straight into the stash for fast/lazy access 
sub load_stash {
	my $c = shift;
	my @config_list = ref $_[0] ? @{ $_[0] } : @_;
	for my $config_set ( @config_list ) {
		my $config = $c->registry->get( $config_set );
		## read config from the table
		my $rs = $c->model('Baseliner::BaliConfig')->search({ ns=>'/', bl=>'*', key=>{-like=>"$config_set.%" } });
		while( my $r = $rs->next  ) {
			(my $var = $r->key) =~ s{^(.*)\.(.*?)$}{$2}g;
			$c->stash->{$var} = $r->value;
		}
		## read config from the command-line arguments
		my $data = $config->getopt;
		for( keys %{ $data || {} } ) {
			$c->stash->{$_} = $data->{$_} if defined $data->{$_};
		}
		#print "====BaliConfig====\n" . YAML::Dump( );
	}
}

# get command-line options for a configset
sub getopt {
	my $self=shift;
	my $defaults = shift;
	use Getopt::Lucid qw( :all );
	my %to_lucid = ( 'bool'=> 'switch', 'num'=> 'counter') ; ## map config meta to Lucid types
	my @opts;
	no warnings;
	for( @{$self->metadata} ) {
		my %opt = ();
		$opt{name} = $_->{opt} || $_->{id};
		$opt{type} = defined $_->{opt_type} ? $_->{opt_type} : $to_lucid{$_->{type}} || 'parameter';
		for my $verb ( qw/default required needs anycase valid/ ) {
			$opt{$verb} = $_->{$verb} if( defined $_->{$verb} );
		}
		push @opts, bless(\%opt,'Getopt::Lucid::Spec');
	} ;
	use warnings;
	my $opt = Getopt::Lucid->getopt( \@opts );
	$opt->merge_defaults( $defaults ) if ref $defaults;
	return { $opt->options };
}

# creates a config object
sub config_store {
	my $self = shift;
	my $config_name = shift;
	my $config = $self->ConfigSets->{ $config_name };
	my %data = map { 
				my $opt = $_->{opt} || $_->{id};
				$opt => \$_->{value} 
			} @{$config->metadata};
	return \%data;
}

## obtener valor por la clave directamente
sub getRowValueById {
	my ($self, $c, $id, $ns, $bl ) = @_;
	$ns ||= '/';
	$bl ||= '*';

	my $rs = $c->model('Baseliner::BaliConfig')->search({ ns=>$ns, bl=>$bl, key=>$self->key.'.'.$id })
		or die $!;			
	while( my $r = $rs->next ) {
		return $r->value
	}
	return;
}


1;
