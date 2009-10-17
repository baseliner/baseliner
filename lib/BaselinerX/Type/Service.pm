package BaselinerX::Type::Service;
use Baseliner::Plug;
use Baseliner::Utils;
with 'Baseliner::Core::Registrable';
use BaselinerX::Type::Service::Logger;

register_class 'service' => __PACKAGE__;

has 'id'=> (is=>'rw', isa=>'Str', default=>'');
has 'name' => ( is=> 'rw', isa=> 'Str' );
has 'desc' => ( is=> 'rw', isa=> 'Str' );
has 'handler' => ( is=> 'rw', isa=> 'CodeRef' );
has 'config' => ( is=> 'rw', isa=> 'Str' );

has 'frequency' => ( is=> 'rw', isa=> 'Int' );  # frequency value in seconds
has 'frequency_key' => ( is=> 'rw', isa=> 'Str' );  # frequency config key
has 'scheduled' => ( is=> 'rw', isa=> 'Bool' );  # true for a scheduled job

has 'log' => ( is=> 'rw', isa=> 'Object' );
has 'show_in_menu' => ( is=> 'rw', isa=> 'Bool' );

has 'type' => (is=>'rw', isa=>'Str', default=>'std');
has 'alias' => ( 
	is=> 'rw', isa=> 'Str',
	trigger=> sub {
		my ($self,$alias,$meta)=@_;
		my $alias_key = 'alias.'.$alias;
		register $alias_key => { link => $self->id };
		Baseliner::Plug->registry->initialize($alias_key);
	}
);

sub BUILD {
	my ($self, $params) = @_;
	## handler should always point to some code
	unless( $self->handler ) {
		$self->handler( \&{ $self->module().'::'.$self->id } );
	}
    ## add service to admin menu
    if( $self->show_in_menu ) {
        register 'menu.admin.service.'.$self->id => { label=>$self->name || $self->key, url=>'/'.$self->key, title=>$self->name || $self->key }; 
        #register 'menu.admin.dfldfj' => { init_rc=>9999, label=>'asdfd', url=>'/ldkfjd', title=>'asdfasdf' }; 
    }
}

register 'menu.admin.service' => { label=>_loc('Services'), title=>_loc('Services') }; 

sub dispatch {
	my ($self, %p )=@_;
	my $c = $p{app};
	my $config;
	my $config_data;
	if( $self->config ) {
		$config = Baseliner::Core::Registry->get( $self->config ) or die "Could not find config '$self->{config}' for service '$self->{name}'";
	} else {
		warn "Missing config for service '$self->{name}'";
		## service will have to deal with @ARGV by itself
	}

	if( $p{'-cli'} ) {
		## the command line is an overwrite of the usual stash system
		$config_data = $config->getopt;
		#$config_data->{argv} = \@argv_noservice;
		use YAML;
		print "===Config $self->{config}===\n",YAML::Dump($config_data),"\n";
	} 
	elsif( $p{'-ns'} ) {
		$config_data = $config->load_from_ns($p{'-ns'} );
	}
	else {
		$config_data = $config->load_from_ns('/');
	}

	$self->run($c, $config_data);
}

=head2 run

Run module services subs ( service->code or sub module::service ). $self is an instance of the package where the service is located.

=cut
sub run {
	my $self= shift;  # 
	my $c = shift;
	my $service = $self->id;
	my $key = $self->key;
	my $version = $self->registry_node->version;
	my $handler = $self->handler;
	my $module = $self->module;
    $self->log( BaselinerX::Type::Service::Logger->new() );  #TODO allow different classes to log

	print "\n===Starting service: $key | $version | $service | $module ===\n";

	my $instance = $module->new( log=>BaselinerX::Type::Service::Logger->new );
	#my $instance = bless($self, $module);

	if( ref($handler) eq 'CODE' ) {
		$handler->( $instance, $c, @_ );
        _log $self->log->msg;
        return {
            rc => $self->log->rc,
            msg=> $self->log->msg, 
        };
	} 
	elsif( $handler && $module ) {
		$module->$handler( $instance, $c, @_);	
        _log $self->log->msg;
        return {
            rc => $self->log->rc,
            msg=> $self->log->msg, 
        };
	}
	else {
		die "Can't find sub $service {...} nor a handler directive for the service '$service'";
	}
}


1;
