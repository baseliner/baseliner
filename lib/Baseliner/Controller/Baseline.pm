package Baseliner::Controller::Baseline;
use Baseliner::Plug;
BEGIN {  extends 'Catalyst::Controller' }

use Baseliner::Utils;
use YAML;
use Baseliner::Core::Baseline;

register 'menu.admin.core.bl' => { label => _loc('List all Baselines'), url=>'/core/baselines', title=>_loc('Baselines')  };
register 'menu.admin.baseline' => { label => _loc('Baselines'), url_comp=>'/baseline/grid', title=>_loc('Baselines')  };

sub load_baselines : Private {
	my ($self,$c)=@_;
	my @bl_arr = ();
	my @bl_list = Baseliner::Core::Baseline->baselines();
	foreach my $n ( @bl_list ) {
		my $arr = [ $n->{bl}, $n->{name} ];
		push @bl_arr, $arr;
	}
	$c->stash->{baselines} = \@bl_arr;
}

sub load_baselines_no_root : Private {
	my ($self,$c)=@_;
	my @bl_arr = ();
	my @bl_list = Baseliner::Core::Baseline->baselines_no_root();
	foreach my $n ( @bl_list ) {
		my $arr = [ $n->{bl}, $n->{name} ];
		push @bl_arr, $arr;
	}
	$c->stash->{baselines} = \@bl_arr;
}

sub bl_list : Path('/core/baselines') {
	my ($self,$c)=@_;
	my @bl_list = Baseliner::Core::Baseline->baselines();
	my $res='<pre>';
	for my $n ( @bl_list ) {
		$res.= Dump $n
	}
	$c->res->body($res);
}

sub grid : Local {
	my ($self,$c)=@_;
	$c->stash->{template} = '/comp/baseline_grid.mas';
}

sub list : Local {
	my ($self,$c)=@_;
    my @bl_list =
      map { { name => $_, description => $_, id => $_, active => 1 } }
      Baseliner::Core::Baseline->baselines();
	$c->stash->{json} = [ @bl_list ];
	$c->forward('View::JSON');
}
1;


