package BaselinerX::Type::Model::Services;
use Moose;
extends qw/Catalyst::Component::ACCEPT_CONTEXT Catalyst::Model/;
use namespace::clean;
use Baseliner::Utils;
use Carp;

sub search_for {
    my ($self, %p) = @_;
    my $c = $self->context;
    my @services = $c->model('Registry')->search_for(key=>'service.', %p );
    return @services;
}

sub launch {
    my ($self, $service_name, %p ) = @_;
    my $c = $self->context;
    my $ns = $p{ns} || '/';
    my $bl = $p{bl} || '*';
    my $data = $p{data} || {};
    my $service = $c->registry->get($service_name) || die "Could not find service '$service_name'";
    my $config = $c->registry->get( $service->config ) if( $service->config );
    my $config_data;
    if( $config ) {
        $config_data = $config->factory( $c, ns=>$ns, bl=>$bl, getopt=>1, data=>$data );
    }
    $service->run( $c, $config_data );
}

# print usage info for all services
sub usage {
	my $self = shift;
	my $RET="";
	foreach my $service ( keys %{ $self->services } ) {
		$RET.= $service."\n";
		if ( ref $self->services->{$service}->{config} ) {
			my $config = $self->services->{$service}->{config};
			my $task = join ' ', map { "-".join '=', split /\|/, $_ } map { $config->{task}{$_}{opt} } keys %{$config->{task}};
			$RET .= "\tbali $service ".$task." ".$config->{cmd}{line}."\n";
			$RET .= "\t".$config->{cmd}{desc}."\n";
		}
		else {
			$RET .= $self->services->{$service}->{usage}."\n";
			$RET .= $self->services->{$service}->{description}."\n";
		}
	}
	$RET =~ s/\n\n/\n/g; ## cleanup
	return $RET;
}


1;
