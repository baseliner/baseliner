package Baseliner::Core::Registry;

use Moose;
use MooseX::ClassAttribute;
use Moose::Exporter;
use Try::Tiny;
use Carp;
use YAML;
use Baseliner::Utils;

Moose::Exporter->setup_import_methods();

class_has 'registrar' =>
	( is      => 'rw',
	  isa     => 'HashRef',
	  default => sub { {} },
	);

class_has 'classes' =>
	( is      => 'rw',
	  isa     => 'HashRef',
	  default => sub { {} },
	);

class_has 'keys_enabled' => ( is=>'rw', isa=>'HashRef', default=>sub{{}} );
class_has '_registrar_enabled' => ( is=>'rw', isa=>'HashRef', );

{
	package Baseliner::Core::RegistryNode;
	use Moose;

	has 'key'=> (is=>'rw', isa=>'Str', required=>1 );
	has 'id'=> (is=>'rw', isa=>'Str', required=>1 );
	has 'module' => (is=>'rw', isa=>'Str', required=>1 );
	has 'version' => (is=>'rw', isa=>'Str', default=>'1.0');
	has 'init_rc' => (is=>'rw', isa=>'Int', default=> 5 );
	has 'param' => (is=>'rw', isa=>'HashRef', default=>sub{{}} );
	has 'instance'=> (is=>'rw', isa=>'Object' );
    has 'actions' => (is=>'rw', isa=>'ArrayRef' );
	
}	

sub _registrar {
    my $self = shift;
    #return $self->_registrar_enabled if ref $self->_registrar_enabled;
    #$self->_registrar_enabled({});
    my @disabled_keys = 
        grep { ! $self->is_enabled($_) }
        keys %{ $self->_registrar };
    for my $key ( @disabled_keys ) {
       delete $self->_registrar->{$key} 
        if defined $self->_registrar->{$key};
    }
    return $self->_registrar;
    #return $self->_registrar;
}

# the 'register' command
sub add {
	my ($self, $pkg, $key, $param)=@_;
	my $reg = $self->registrar;
    if( ref $param eq 'HASH' ) {
        $param->{key}=$key unless($param->{key});
        $param->{short_name} = $key; 
        $param->{short_name} =~ s{^.*\.(.+?)$}{$1}g if( $key =~ /\./ );
        $param->{id}= $param->{id} || $param->{short_name};
        $param->{module}=$pkg unless($param->{module});
	
        my $node = Baseliner::Core::RegistryNode->new( $param );
        $node->param( $param );
        $node->param->{registry_node} = $node;
        $reg->{$key} = $node;
    } else {
        #TODO register 'a.b.c' => 'BaselinerX::Service::MyService'
        die "Error registering '$pkg->$key': not a hashref. Not supported yet.";
    }
}

sub add_class {
	my ($self, $pkg, $key, $class)=@_;
	my $reg = $self->classes();
	$reg->{$key} = $class;
}

# everything starts here, called from Baseliner.pm
sub setup {
	my $self= shift; 
    $self->load_enabled_list;
    $self->initialize( @_ );
}

## blesses all registered objects into their registrable classes (new Service, new Config, etc.)
sub initialize {
	my $self= shift; 

	my %init_rc = ();
	my @namespaces = ( @_ ? @_ : keys %{ $self->registrar || {} } );

	## order by init_rc
	for my $key ( @namespaces ) {
		my $node = $self->registrar->{$key};
		next if( ref $node->instance );  ## already initialized
		push @{ $init_rc{ $node->init_rc } } , [ $key, $node ];
	}

	## now, startup ordered based on init_rc
        ##TODO solve dependencies with a graph
	for my $rc ( sort keys %init_rc ) {
		for my $rc_node ( sort @{ $init_rc{$rc} } ) {
			my ($key, $node) = @{  $rc_node };
			## search for my class backwards	
			$self->instantiate( $node );
		}
	}
    $self->initialize(@_) if keys %init_rc;  # recurse in case there is more to do
}

## bless an object instance with the provided params
sub instantiate {
	my ($self,$node,$class)=@_;	
	$class ||= $self->_find_class( $node->key );
	$node->{instance} = $class->new( $node->param );
}

## find the corresponding class for a component
sub _find_class {
	my ($self,$key)=@_;
	my $class = $key;
	my $node = $self->get_node($key);
	my @domain = split /\./, $key;
	for( my $i=$#domain; $i>=0; $i-- ) {
		$class = join '.',@domain[ 0..$i ];
		last if( $self->classes->{$class} ) ;
	}
	my $class_module = $self->classes->{$class} || $node->module; ## if no class found, bless onto itself
		#'BaselinerX::Type::Generic';  ## if no class found, assign it to generic
	#$ENV{CATALYST_DEBUG} && print STDERR "\t\t*** CLASS: $class ($class_module) FOR $key\n";
	return $class_module;
}

=head2 get_node

Return the key registration object (node)

=cut
sub get_node {
	my ($self,$key)=@_;
	$key || croak "Missing parameter \$key";
	return ( $self->registrar->{$key} 
		or $self->search_for_node( id=>$key ) 
        or $self->get_partial($key) );
}

## return a registered object
sub get { return $_[0]->get_instance($_[1]); }

sub get_instance {
	my ($self,$key)=@_;
	my $node = $self->get_node($key) || die "Could not find key '$key' in the registry";
	my $obj = $node->instance;
	return ( ref $obj ? $obj : $self->instantiate( $node ) );
}

sub get_partial {
	my ($self,$key)=@_;
    my @found = map { $self->registrar->{$_} } grep /$key$/, keys %{ $self->registrar || {} };
    return wantarray ? @found : $found[0];
}

sub dir {
	my ($self,$key)=@_;
	return keys %{ $self->registrar || {} }
}

sub dump_yaml {
	use YAML;
	Dump( shift->registrar );
}

sub load_enabled_list {
    my ( $self ) = @_;
    my $rs = Baseliner->model('Baseliner::BaliConfig')->search({ ns=>'/', bl=>'*', key=>{ -like => '%.enabled' } });
    while( my $row = $rs->next ) {
        my $key = $row->key;
        my $enabled = $row->value;
        $self->keys_enabled->{ $key } = $enabled;
    }
}

## check the db if its key=>enabled|disabled
sub is_enabled {
    my ($self, $key) = @_;
    my $state = 1;
    try {
        if( defined $self->keys_enabled->{ $key } ) {
            $state = $self->keys_enabled->{ $key };
        }
    } catch {
        my $e = shift;
        _log "is_enabled: error while checking '$key': $e";
    };
    return $state;
}

=head2 search_for_node

Search for registered objs with matching attributes

=cut
sub search_for_node {
	my ($self,%query)=@_;
	my @found = ();

    # query parameters
    my $check_enabled = delete $query{check_enabled};
    my $has_attribute = delete $query{has_attribute};
	my $key_prefix = delete $query{key} || '';
	my $q_depth = delete $query{depth};
	my $allowed_actions = delete $query{allowed_actions};

    # loop thru services
	$q_depth||= 99; 
	OUTER: for my $key ( $self->starts_with( $key_prefix ) ) {
		my $depth = ( my @ss = split /\./,$key ) -1 ;
		next if( $depth gt $q_depth );
        if( $allowed_actions && ref $self->registrar->{$key}->actions) {
            warn "..............ref ($key): " . join ',', @{ $self->registrar->{$key}->actions || [] } ;
            warn "..............all ($key): " . join ',', @{ $allowed_actions || [] } ;
            warn ".............GREP ($key): " . grep { my $a=$_; grep /^$a$/,@{$allowed_actions||[]} } @{ $self->registrar->{$key}->actions || [] };
        }

        # skip nodes that the user has no access to
        next if( $allowed_actions
            && ref $self->registrar->{$key}->actions
            && !grep { my $a=$_; grep /^$a/,@{$allowed_actions||[]} } @{ $self->registrar->{$key}->actions || []} );

        # query for attribute existence
		next if( $has_attribute && !defined $self->registrar->{$key}->{$has_attribute} );

        # query for attribute value
		foreach my $attr( keys %query ) {
			my $val = $query{$attr};	
            if( defined $val ) {
                if( defined $self->registrar->{$key}->{$attr} ) {
                    next OUTER unless( $self->registrar->{$key}->{$attr} eq $val);
                }
                elsif( defined $self->registrar->{$key}->{param}->{$attr} ) {
                    #warn "..........CHECK: $val, $key, $attr = " .  $self->registrar->{$key}->{param}->{$attr};
                    next OUTER unless( $self->registrar->{$key}->{param}->{$attr} eq $val);
                }
                else {
                    next OUTER;
                }
            }
		}
		push(@found,$self->registrar->{$key});
	}
	return wantarray ? @found : $found[0];
}

sub search_for {
	my $self=shift;
	my @found_nodes = $self->search_for_node( @_ );
	return map { $_->instance } @found_nodes;
}

sub starts_with {
	my ($self, $key_prefix )=@_;
	my @keys;
	for my $key ( keys %{ $self->registrar || {} } ) {
		push @keys, $key if( $key =~ /^$key_prefix/ );
	}
	return @keys;
}

sub get_all {
	my ($self, $key_prefix )=@_;
	my @ret;
	#warn "GETALL=$key_prefix";
	for( keys %{ $self->registrar || {} } ) {
		push @ret, $self->get($_) if( /^\Q$key_prefix/ );
	}
	return @ret;
}

sub print_table {
    my $self = shift;

    my $table = <<"";
Registry:
.----------------------------------------+-----------------------------------------------.
| Key                                    | Package                                       |
+----------------------------------------+-----------------------------------------------+

	for( sort keys %{ $self->registrar || {} } ) {
        my $node = $self->registrar->{$_};
        $table .= sprintf("| %-38s ", $node->key );
        #$table .= sprintf("| %-22s ", $_->module );
        ( my $module = $node->module ) =~ s/BaselinerX/BX/g;
        $module =~ s/Baseliner/BL/g;
        $table .= sprintf("| %-45s |\n", $module );
    }

    $table .= <<"";
.----------------------------------------------------------------------------------------.

    print STDERR $table . "\n" if Baseliner->app->debug;
}
1;
