package BaselinerX::CA::Harvest;
use Baseliner::Plug;
use Baseliner::Utils;
use File::Find::Rule;
extends 'BaselinerX::Type::Service';
use YAML::Syck;

#my $dbh = Baseliner->model('Harvest')->storage->dbh;
#if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
	#$dbh->do("alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss'");
#}

register 'config.harvest.db' => {
    name => 'Harvest DB Connection Data',
	metadata => [
		{ id=>'connection', label=>'Connection String', type=>'text' },
		{ id=>'username', label=>'User', type=>'text' },
		{ id=>'password', label=>'Password', type=>'text' },
	]
};

register 'config.ca.harvest.map' => {
    name => 'Harvest View, State and Baseline relationships',
    metadata => [
        { id=>'view_to_baseline', label=>'From View to Baseline', type=>'hash' },
    ]
};

register 'config.ca.harvest.cli' => {
    name => 'Harvest Client Connection Data',
    metadata => [
        { id=>'broker', type=>'text' },
        { id=>'login', type=>'text' },
        { id=>'permissions', label=>'Checkout File Permissions', type=>'text' },
    ]
};

register 'service.harvest.env_for_item' => {
	name => 'List Environments for Items',
	handler => \&envs_for_item,
};

my %ei_cache;
sub envs_for_item {
	my $iid = shift;
	return () unless $iid;
    return @{ $ei_cache{$iid} || []} if defined $ei_cache{$iid};
	my $item  = Baseliner->model('Harvest::Haritems')->search({ itemobjid=>$iid }, { cache=>1 })->first;
	my $rid = $item->repositobjid;
	my $rep  = Baseliner->model('Harvest::Harrepository')->search({ repositobjid=>$rid }, { cache=>1 })->first;
	my $rv = $rep->harrepinviews;
	my %envs;
	while( my $v = $rv->next ) {
		my $env = { $v->viewobjid->envobjid->get_columns };
		next if $env->{envobjid} eq 0;
		next if $envs{ $env->{envobjid} };
		$envs{ $env->{envobjid} } = $env;
	}
    $ei_cache{$iid} = [ values %envs ];
	return values %envs;
}

register 'config.harvest.subapl' => {
	metadata => [
		{ id=>'position', label=>_loc('Subapplication position within view path'), default=>3 },
	],
};

register 'config.harvest.nature' => {
	metadata => [
		{ id=>'position', label=>_loc('Nature position within view path'), default=>2 },
	],
};

#TODO provider or namespace? 
register 'provider.harvest.users' => {
	name	=>'Harvest Users',
	config	=> 'config.harvest.db',
	list	=> sub {
		my ($self,$b)=@_;
		
		my $conn = $b->stash->{'config.harvest.db.connection'};
		my $username = $b->stash->{'config.harvest.db.connection.username'};
		my $password = $b->stash->{'config.harvest.db.connection.password'};
		
		$b->log->debug('Providing the user list');
	},
};

register 'config.harvest.db.grid.package' => {
	metadata => [
		{ id=>'packagename', label=>'Package', type=>'text' },
		{ id=>'environmentname', label=>'Project', type=>'text' },
		{ id=>'statename', label=>'State', type=>'text' },
		{ id=>'viewname', label=>'View', type=>'text' },
		{ id=>'username', label=>'Asigned to', type=>'text' },
		{ id=>'formdata', label=>'Form', type=>'text' },
	]
};
BEGIN {  extends 'Catalyst::Controller' }

#__PACKAGE__->config->{namespace} = '/ca/harvest';
sub packages_json : Path('/ca/harvest/packages_json') {
	my ($self,$c) = @_;
	my $rs = $c->model('Harvest::Harpackage')->search({ packageobjid => { '>', '0' } });
	my @data;
	while( my $row = $rs->next ) {
		my $rs_af = $row->harassocpkgs;
		while( my $af = $rs_af->next ) {
			my $aa = $af->formobjid;
		}
		push @data, { 
			packageobjid => $row->packageobjid,
			packagename => $row->packagename,
		};
	}
	$c->stash->{json} = { data=> @data };
	$c->forward('View::JSON');
}

1;
