package BaselinerX::CA::Harvest::Namespace::Package;
use Moose;
use Baseliner::Utils;
use Try::Tiny;
use Catalyst::Exception;
use BaselinerX::CA::Harvest::Project;

with 'Baseliner::Role::Namespace::Package';
with 'Baseliner::Role::JobItem';

has 'ns_type' => ( is=>'ro', isa=>'Str', default=>_loc('Harvest Package') );

sub BUILDARGS {
    my $class = shift;

    if( defined ( my $row = $_[0]->{row} ) ) {
        my @related;
        push @related, 'application/'.$row->envobjid->environmentname;
        my $info = _loc('State').': '.$row->state->statename."<br>" . _loc('Project').': '.$row->envobjid->environmentname."<br>" ;

        return {
                ns      => 'harvest.package/' . $row->packagename,
                ns_name => $row->get_column('packagename'),
                ns_info => $info,
                user    => $row->modifier->username,
                date    => $row->get_column('modifiedtime'),
                icon    => '/static/images/scm/package.gif',
                service => 'service.harvest.runner.package',
                provider=> 'namespace.harvest.package',
                related => [ @related ],
                ns_id   => $row->packageobjid,
                ns_data => { $row->get_columns },
        };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub can_job {
    my ( $dest_bl );
    #TODO check the current state
    return 1;    
}

sub map_bl {
    my ($self, $ns, $bl ) = @_;
    my $inf = Baseliner->model('ConfigStore')->get('config.ca.harvest.map');
    my $new_bl = $bl;
    if( $inf ) {
        try {
            $new_bl = $inf->{iew_to_baseline}->{$bl}; 
        } catch {
           Catalyst::Exception->throw("Error while processing map_bl: " . shift );
        };
    }
    return $new_bl;
}

sub bl {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->ns_id },);
    return $pkg ? $self->map_bl( '/', $pkg->state->viewobjid->viewname ) : 'ERROR';  #TODO convert viewname or statename to bl
}

sub created_on {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->ns_id },);
    return $pkg->creationtime;
}

sub created_by {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->ns_id }, { prefetch=>['modifier'] });
    return $pkg ? $pkg->modifier->username : _loc 'Package not found';
}

sub checkout { }
sub promote { }
sub demote { }
sub approve { }
sub reject { }
sub is_approved { }
sub is_rejected { }
sub user_can_approve { }

sub find {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->ns_id }, { prefetch=>['envobjid'] });
}

sub path {
    my $self = shift;
    my $pkg = $self->find;
    my $env = $pkg->envobjid;
    my $path = $self->compose_path($env->environmentname, $pkg->packagename);
}

sub state {
    my $self = shift;
    my $state = $self->find->state;
    return $state->statename;
}

sub get_row {
    my $self = shift;
    return Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->ns_id }, { prefetch=>['envobjid'] });
}

sub application {
    my $self = shift;
    my $pkg = $self->get_row;
    my $env = $pkg->envobjid->environmentname;
    my $app = BaselinerX::CA::Harvest::Project::get_apl_code( $env );
    return 'application/' . $app;
}

our @parents;
sub parents {
    return @parents if scalar @parents;
    my $self = shift;
    my $pkg = $self->get_row;
    my $env = $pkg->envobjid->environmentname;
    my $app = BaselinerX::CA::Harvest::Project::get_apl_code( $env );
    push @parents, "application/" . $app;
    push @parents, "harvest.project/" . $env;
    push @parents, "/";
    return @parents;
}

1;
