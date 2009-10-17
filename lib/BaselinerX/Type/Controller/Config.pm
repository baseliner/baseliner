package BaselinerX::Type::Controller::Config;
use Baseliner::Plug;
use Baseliner::Utils;
use JavaScript::Dumper;
use YAML;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' };

register 'menu.admin.config' => { label=>_loc('Config'), url_comp=>'/config/main', title=>_loc('Config') };

sub generate_form : Path('/config/generate_form') {
	my ($self,$c, $config_key )=@_;
	
    $c->forward('/namespace/load_namespaces');
	$c->forward('/baseline/load_baselines');

    $config_key ||= $c->stash->{config_key};

	my $config = $c->registry->get( $config_key || 'config.nature.j2ee.build' );
	$c->stash->{metadata} = $config->metadata;
		
	$c->stash->{template} = '/comp/config/config_form.mas';
}

=head2 form

Returns an Ext component for eval - accepts a config key as stash or param

=cut
sub form : Path('/config/form') {
	my ($self,$c)=@_;
    my $config_key = $c->stash->{config_key};
    if( ref $config_key eq 'ARRAY' ) {
       my @meta;
       for( @{ $config_key || [] } ) {
           my $config = $c->model('Registry')->get( $_ );
           push @meta, $config->metadata if ref $config; 
       }
       $c->stash->{config} = \@meta;
    } else {
        $config_key ||= $c->request->parameters->{config_key};
        my $config = $c->model('Registry')->get( $config_key );
        $c->stash->{metadata} = $config->metadata;
    }
    $c->forward('/config/form_render');
}

sub form_render : Private {
	my ($self,$c)=@_;
    $c->forward('/namespace/load_namespaces');
	$c->forward('/baseline/load_baselines');
    $c->stash->{url_submit} = '/config/submit';
    $c->stash->{url_store} = '/config/json';
	$c->stash->{template} = '/comp/config/config_panel.mas';
}

# saves form data
sub submit : Local {
	my ($self,$c)=@_;
    my $p = $c->req->params;
    my $ret;
    try {
        if( $p->{key} ) {
            my $config = $c->registry->get( $p->{key} );
            $config->store_from_metadata( $c, data=>$p, long_key=>1 ) or die _loc('Error storing config data');
        } else {
            my $bl = delete $p->{bl};
            my $ns = delete $p->{ns};
            $c->model('ConfigStore')->store_long(ns=>$ns, bl=>$bl, data=>$p);
        }
        $c->res->body( "true" );
    } catch {
        $c->res->body( "false" );
    };
}

# feeds form with data
sub json : Local {
	my ($self,$c)=@_;
    my $p = $c->request->parameters;
    my $key = $c->request->params->{key};
    my $data;
    if( $key ) {
        my $config = $c->model('Registry')->get($key);
        $data = $config->factory($c,ns=>$p->{ns}, bl=>$p->{bl},default_data=>$p, long_key=>1);
    } else {  # all data for ns/bl
        my $ns = $c->request->params->{ns};
        my $bl = $c->request->params->{bl};
        my @keys = $c->model('ConfigStore')->filter_ns( $ns );  
        foreach my $key ( @keys ) {
            my $inf = $c->model('ConfigStore')->get( $key , ns=>$ns, bl=>$bl, long_key=>1 );
            if( defined $inf ) {
                my %merge = ( %{ $data || {} }, %{ $inf || {} } );
                $data = \%merge;
            }
        }
    }
    $c->stash->{json} = { success=>\1, data => $data };  
    $c->forward("View::JSON");
}

sub config_tree : Path('/config/tree') {
	my ($self,$c)=@_;
    my $list = $c->registry->starts_with( 'config' ) ;
    my @tree;
    foreach my $config_key ( $c->registry->starts_with( 'config' ) ) {
        my $config = Baseliner::Core::Registry->get( $config_key );
        my @children;
        foreach my $m ( @{ $config->{metadata} || [] } ) {
            my $id = $config_key.'.'.$m->{id};
            push @children, { id=>$id, leaf=>\1, attributes=>{ key=>$id }, text=>($m->{label} || $m->{id}) };
        }
        push @tree, { id=>$config_key, leaf=>\0, text=>($config->{name} || $config_key), attributes=>{ key=>$config_key }, children=> \@children };
    }
    $c->stash->{json} = [ sort { $a->{text} cmp $b->{text} } @tree ];
    $c->forward("View::JSON");
}

sub list_services : Local {
	my ($self,$c)=@_;
	use YAML;
	$c->res->body( "<pre>".Dump $c->registry->starts_with( 'service' ) );
}

sub ns_panel : Local {
	my ($self,$c)=@_;
    my $ns = $c->request->parameters->{ns};
    my $filter = $c->request->parameters->{filter};
    my @filter;
    if( defined $filter ) {
        push @filter, $filter;
    } else { 
        push @filter, $c->model('ConfigStore')->filter_ns( $ns );
    }
    $c->stash->{metadata_filter} = [ @filter ];
    $c->stash->{template} = '/comp/config/config_roll.mas';
}

sub field : Local {
	my ($self,$c)=@_;
    my $key = $c->request->parameters->{key};
    for my $config ( $c->model('ConfigStore')->all ) {
        my @metadata = $config->metadata_filter( $key );
        if( scalar @metadata ) {  
            $c->stash->{config_key} = $key;
            my $row = shift @metadata;   # we can only handle one key
            $c->stash->{metadata_row} = $row;
        }
    }
	$c->stash->{single_comp} = 1;
	$c->stash->{template} = '/comp/config/config_selector.mas';
}

sub main : Local {
	my ($self,$c)=@_;
	$c->forward('/baseline/load_baselines');
	$c->stash->{template} = '/comp/config/config_main.mas';
}

1;
