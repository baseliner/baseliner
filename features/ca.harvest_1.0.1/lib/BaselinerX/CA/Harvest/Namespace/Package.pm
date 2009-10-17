package BaselinerX::CA::Harvest::Namespace::Package;
use Moose;
use Baseliner::Utils;
use Try::Tiny;
use Catalyst::Exception;
use BaselinerX::CA::Harvest::Project;

with 'Baseliner::Role::Namespace::Package';
with 'Baseliner::Role::JobItem';

has 'ns_type' => ( is=>'ro', isa=>'Str', default=>_loc('Harvest Package') );
has 'view_to_baseline' => ( is=>'rw', isa=>'HashRef' );

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

# maps from current state to bl depending on job_type
sub states_for_job {
	my ($self,$job_type) = @_;
	my $bl = $self->bl or die 'Could not determine the package baseliner for ' . $self->ns;
	my $inf = Baseliner->model('ConfigStore')->get('config.ca.harvest.map', ns=>$self->ns, bl=>$bl );
	if( $inf ) {
		my $states = $inf->{states_for_job}->{$job_type}->{$bl}; 
	}
}

sub can_job {
    my ( $self, $bl ) = @_;
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid },);

	return 1 if( $self->bl eq $bl );
	#TODO check approval
    #my $pkg = Baseliner->model('Harvest::Harpackage')->search({ packageobjid=>$self->ns_id },{ join=>['state', 'view'], prefetch=>['state','view'] });
	#my $state_to_bl = $self->state_to_bl;
}

# maps from package view to bl
sub map_bl {
    my ($self, $ns, $bl ) = @_;
	my $new_bl;
	if( ref $self->view_to_baseline eq 'HASH' ) {
		$new_bl = $self->view_to_baseline->{$bl}; 
	} else {
		my $inf = Baseliner->model('ConfigStore')->get('config.ca.harvest.map', ns=>$self->ns );
		if( $inf ) {
			try {
				$self->view_to_baseline( $inf->{view_to_baseline} );
				$new_bl = $inf->{view_to_baseline}->{$bl}; 
			} catch {
				Catalyst::Exception->throw("Error while processing map_bl: " . shift );
			};
		}
	}
    return $new_bl || $bl;
}

sub packageobjid {
    my $self = shift;
	return $self->ns_id;
}

sub bl {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid },);
    return $pkg ? $self->map_bl( '/', $pkg->state->viewobjid->viewname ) : 'ERROR';  #TODO convert viewname or statename to bl
}

sub created_on {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid },);
    return $pkg->creationtime;
}

sub created_by {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid }, { prefetch=>['modifier'] });
    return $pkg ? $pkg->modifier->username : _loc 'Package not found';
}

=head2 viewpaths

	$self->viewpaths();   # /APL/PATH/PATH/PATH
	$self->viewpaths(1);  # /APL
	$self->viewpaths(2);  # /APL/PATH
	$self->viewpaths(3);  # /APL/PATH/PATH

=cut
use Baseliner::Core::DBI;
sub viewpaths {
	my ($self, $level ) = @_;
	my $pid = $self->packageobjid;
    my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
    my @rs = $db->array_hash( qq{
		select pathfullname
		from haritems i,harpathfullname pa,harversions v,harpackage p
		where v.packageobjid=p.packageobjid
		and v.itemobjid=i.itemobjid
		and pa.versionobjid=(SELECT MAX(versionobjid) FROM HARPATHFULLNAME pa2 WHERE pa.itemobjid=pa2.itemobjid)
		and i.parentobjid=pa.itemobjid
		and p.packageobjid=$pid
	});
	my %paths;
	for my $row ( @rs ) {
		my $path = $row->{pathfullname};
		$path =~ s{\\}{/}g;
		if( $level ) {
			my @parts = split /\//, $path;
			$path = '/'.join('/', @parts[1..$level]);
		}
		$paths{$path}=1 unless $paths{$path};
	}
	return keys %paths;
    #my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid }, { prefetch=>['harversions'], });
	#$pkg->harversions->itemobjid->itemname;
}

sub environmentname {
    my $self = shift;
	my $row = $self->find;
    return $row->envobjid->environmentname;
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
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid }, { prefetch=>['envobjid'] });
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
    return Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid }, { prefetch=>['envobjid'] });
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
