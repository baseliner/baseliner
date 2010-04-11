package BaselinerX::CA::Harvest::Provider::Subapplication;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::CA::Harvest::Namespace::Subapplication;
use BaselinerX::CA::Harvest;

with 'Baseliner::Role::Provider';

register 'namespace.harvest.subapplication' => {
	name	=>_loc('Harvest Subapplication'),
	domain  => domain(),
    can_job => 0,
    finder =>  \&find,
	handler => \&list,
};

sub namespace { 'BaselinerX::CA::Harvest::Namespace::Subapplication' }
sub domain    { 'harvest.subapplication' }

sub find {
    my ($self, $item ) = @_;
    my $row = Baseliner->model('Harvest::Haritems')->search({ itemname=>$item, itemtype=>0 , parentobjid=>{ '<>', 0 } })->first;
    return BaselinerX::CA::Harvest::Namespace::Subapplication->new({ row => $row }) if( ref $row );
}

sub get { find(@_) }

sub list {
    my ($self, $c, $p) = @_;
    my $rs = Baseliner->model('Harvest::Harpathfullname')->search(undef, { join=>['itemobjid'],prefetch =>['itemobjid'] });
    my @ns;
return [];
    my $config = Baseliner->registry->get('config.harvest.subapl')->data;
    my $cnt = $config->{position};
    while( my $r = $rs->next ) {
        my $path = $r->pathfullname;
        my @parts = split /\\/, $path;
        next unless @parts == ($cnt+1); ## the preceding \ counts as the first item
            my $subapl = $parts[$cnt];
        my @envs = BaselinerX::CA::Harvest::envs_for_item( $r->itemobjid->itemobjid );
        for my $env ( @envs ) {
            ( my $env_short =  $env->{environmentname} )=~ s/\s/_/g;
            push @ns, BaselinerX::CA::Harvest::Namespace::Subapplication->new({
                    ns      => 'harvest.subapplication/' . $subapl,
                    ns_name => $subapl,
                    ns_type => _loc('Harvest Subapplication'),
                    ns_id   => $env->{envobjid},
                    ns_parent => 'application/' . $env_short,
                    parent_class => [ 'application' ],
                    ns_data => { $r->get_columns },
                    provider=> 'namespace.harvest.subapplication',
                    });
        }
    }
    return \@ns;
}

1;
