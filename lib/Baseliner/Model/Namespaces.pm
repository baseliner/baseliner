package Baseliner::Model::Namespaces;
use Moose;
extends qw/Catalyst::Model/;
no Moose;
use Baseliner::Utils;

=head2 namespaces

List all namespaces. 

Be careful, this is not cached. If you want a cached list, use the /namespace/list controller.

=cut
use YAML;
use Baseliner::Core::Registry;
sub namespaces {
    my $self = shift;
    my $p = {};
    if( ref $_[0] ) {
        $p = $_[0];
    } else {
        $p = { @_ };
    }
	my @ns_list;
	my @ns_prov_list = Baseliner::Core::Registry->starts_with('namespace');
	for my $ns_prov ( @ns_prov_list ) {
		my $prov = Baseliner::Core::Registry->get( $ns_prov );
		next if( $p->{can_job} && !$prov->can_job );
		next if( $p->{class} && !( $prov->root =~ /$p->{class}/ ) );  #TODO root rename to class or something
        eval {
            my $prov_list = $prov->handler->($prov, Baseliner->app, $p);
            push @ns_list, @{  $prov_list || [] };
        };
        if( my $error = $@ ) {
            _log $error 
        }
	}
	return sort {
        return -1 if $a->ns eq '/';
        ( $a->ns_type . $a->ns ) cmp ( $b->ns_type . $b->ns )
    } @ns_list;
}

# returns a reverse sorted list of ns from more specific to most general (root)
sub sort_ns {
    my $self = shift;
    my $opts = ref($_[0]) ? shift : {};
    my @ns = @_;
    push @ns, '/' unless $opts->{no_root} ;
    #TODO graph analyze @ns against relationships
    return sort { 
            $opts->{asc}
            ?  length($a) <=> length($b) 
            :  length($b) <=> length($a) 
        } _unique @ns;  ## long to short - temp hack
}

sub namespaces_hash {
	my $self = shift; 
	my @ns_list = $self->namespaces;
	my %h;
	for( @ns_list ) {
		$h{ $_->ns } = $_;
	}
	return %h;
}

=head2 find_text 

Finds a descriptive representation for the Namespace. Heavly used, heavly memoized.

=cut
our %ns_text_cache;
sub find_text {
	my $self = shift; 
	my $ns = shift; 
    return $ns_text_cache{$ns} if defined $ns_text_cache{$ns};
	my %h = $self->namespaces_hash;
	my $p = $h{ $ns };
	if( $p ) {
		return $ns_text_cache{$ns} = $p->ns_text;
	} else {
		return  $ns_text_cache{$ns} = _loc('Namespace') . " $ns";	
	}
}

sub does {
	my ($self, $role ) = @_;
    $role = "Baseliner::Role::$role" unless $role =~ m/^Baseliner/g;
    return grep { $_->does($role) } $self->namespaces;
}

# get is a factory, turns a namespace into its object
sub get {
	my $self = shift; 
    return $self->_get( ns=>[ @_ ], one=>1 );
}
sub _first {
	my $self = shift; 
    return $self->_get( ns=>[ @_ ], one=>1 );
}
sub _get {
    my ( $self, %p ) = @_;

    foreach my $ns ( @{ $p{ns} } ) {
        my ( $domain, $item ) = ns_split( $ns );
        if( $domain && !$item ) {   # just domain
            my @providers = $self->find_providers_for( domain=>$domain ); 

            my @namespaces;
            for my $provider ( @providers ) {
                push @namespaces, @{ $provider->handler->( $provider, Baseliner->app, {} ) || [] };
            }
            return ( $p{one} || scalar(@namespaces) eq 1 )
                ? $namespaces[0]
                : wantarray ? @namespaces : [ @namespaces ];
        }
        elsif( $domain && $item ) {   # normal 
            my @providers = $self->find_providers_for( domain=>$domain ); 

            my @namespaces;
            # first, try to get it straight from the exact domain matches
            for my $provider ( grep { $_->{root} eq $domain } @providers ) {
                my $ns_obj = $provider->get( $item ); 
                push @namespaces, $ns_obj if ref $ns_obj;
            }
            # now, the rest, so they stay behind the array
            for my $provider ( grep { $_->{root} ne $domain } @providers ) {
                my $ns_obj = $provider->get( $item ); 
                push @namespaces, $ns_obj if ref $ns_obj;
            }

            return ( $p{one} || scalar(@namespaces) eq 1 )
                ? $namespaces[0]
                : wantarray ? @namespaces : [ @namespaces ];
            
        }
        elsif( !$domain && $item ) {   # just item
            for my $namespace ( $self->namespaces ) {
                my ( $domain, $item ) = ns_split( $namespace->ns );
                return $namespace if $item eq $item; 
            }
        }
        else {
            my $provider = Baseliner::Core::Registry->get('namespace.root'); 
            my $list = $provider->handler->();
            return $list->[0] if ref $list eq 'ARRAY';
        }
    }
}

# gimme a domain and I'll find you providers
sub find_providers_for {
    my ( $self, %p ) = @_;

    my $domain = $p{domain};

	my @providers;
	my @all = Baseliner::Core::Registry->starts_with('namespace');
	for my $provider_name ( @all ) {
		my $provider = Baseliner::Core::Registry->get( $provider_name );
        if( $p{exact} ) {
            push( @providers, $provider )
                if( $provider->{root} eq $domain );         #TODO root should be domain
        } else {
            push( @providers, $provider )
                if( domain_match( $provider->{root}, $domain ) );  
        }
	}
	return @providers;
}

1;
