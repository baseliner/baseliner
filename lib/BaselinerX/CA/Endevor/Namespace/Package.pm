package BaselinerX::CA::Endevor::Namespace::Package;
use Moose;
use Baseliner::Plug;
use Baseliner::Utils;
with 'Baseliner::Role::Namespace::Package';
with 'Baseliner::Role::JobItem';

register 'config.ca.endevor.package' => {
    name => 'Endevor Package Parameters',
    metadata => [
        { id=>'app_prefix', label=>'Prefix to prepend to the app name extracted from a package', default=>'GBP.' }, ##TODO put this default in a table
        { id=>'app_from_pkg', label=>'Regex to pull off the application from the package name', default=>'^.(....)' }, 
    ]
};

sub bl {
    my $self = shift;
    my $stg = $self->ns_data->{PROM_TGT_ENV};
    my $bl = $stg eq 'PREP'  #TODO should be baseline->previous('PREP')
        ? 'DESA'
        : 'PREP'   #TODO how about prod? 
        ; 
    return $bl;
}

sub created_by {
    my $self = shift;
    return $self->ns_data->{CREATE_USRID};
}

sub created_on {
    my $self = shift;
    my $create_date = $self->ns_data->{CREATE_DATE};
    my $create_time = $self->ns_data->{CREATE_TIME};
    return parse_dt( '%Y/%m/%d %H:%M', "$create_date $create_time"  );
}

sub checkout { }
sub promote { }
sub demote { }
sub approve { }
sub reject { }
sub is_approved { }
sub is_rejected { }
sub user_can_approve { }

sub path {
    my $self = shift;
    my $inf = Baseliner->model('ConfigStore')->get('config.ca.endevor.package');
    my $app_from_pkg = qr/$inf->{app_from_pkg}/;
    my $app;
    $app = $inf->{app_prefix}.$1 if(  $self->ns_name =~ $app_from_pkg );
    return $self->compose_path( $app, $self->ns_name );
}

sub state { }

sub parents {
    my $self = shift;
    my $inf = Baseliner->model('ConfigStore')->get('config.ca.endevor.package');
    my $app_prefix = $inf->{app_prefix};
    #TODO create a masked config
    return ( $app_prefix . "." . substr( $self->ns_name, 1, 4 ) ); 
}

1;

