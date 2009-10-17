package Baseliner::Controller::Role;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Baseline;

BEGIN {  extends 'Catalyst::Controller' }

register 'action.admin.role' => { name=>'Admin Roles' };
register 'menu.admin.role' => { label => _loc('Roles'), url_comp=>'/role/grid', actions=>['action.admin.role'], title=>_loc('Roles') };

sub role_detail_json : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my $id = $p->{id};
    if( defined $id ) {
        my $r = $c->model('Baseliner::BaliRole')->search({ id=>$id })->first;
        if( $r ) {
            my @actions;
            my $rs_actions = $r->bali_roleactions;
            while( my $ra = $rs_actions->next ) {
                my $desc = $ra->action;
                eval { # it may fail for keys that are not in the registry
                    my $action = $c->model('Registry')->get( $ra->action );
                    $desc = $action->name;
                }; 
                push @actions,{ action=>$ra->action, description=>$desc, bl=>$ra->bl };
            }
            $c->stash->{json} = { data=>[{  id=>$r->id, name=>$r->role, description=>$r->description, actions=>[ @actions ] }]  };
            $c->forward('View::JSON');
        }
    }
}

sub json : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'role';
    $dir ||= 'asc';
	my $rs = $c->model('Baseliner::BaliRole')->search(undef, { order_by => $sort ? "$sort $dir" : undef });
	my @rows;
	while( my $r = $rs->next ) {
        # related actions
        my $rs_actions = $r->bali_roleactions;
        my @actions;
        while( my $ra = $rs_actions->next ) {
            eval {
                my $action = $c->model('Registry')->get( $ra->action );
                push @actions, $action->name . " (" . $ra->action . ")";
            };
            if( $@ ) {
                push @actions, $ra->action;
            }
        }
        my $actions_txt = @actions ? '<li>'.join('<li>',@actions) : '-';
        # related users
        my $rs_users = $r->bali_roleusers;
        my @users;
        while( my $ru = $rs_users->next ) {
            push @users, $ru->username;
        }
        my $users_txt = @users ? join(', ',@users) : '-';
        # produce the grid
        next if( $query && !query_array($query, $r->role, $r->description, $actions_txt, $users_txt ));
        push @rows,
          {
            id          => $r->id,
            role        => $r->role,
            actions     => $actions_txt,
            users       => $users_txt,
            description => $r->description,
          } if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
	$c->stash->{json} = { data => \@rows };		
	$c->forward('View::JSON');
}

sub action_tree : Local {
    my ( $self, $c ) = @_;
    my @actions = $c->model('Actions')->list;
    my %tree;
    foreach my $a ( @actions ) {
        my $key = $a->{key};
        ( my $folder = $key ) =~ s{^(\w+\.\w+)\..*$}{$1}g;
        push @{ $tree{ $folder } }, { id=>$a->{key}, text=>$a->name, leaf=>\1 }; 
    }
    $c->stash->{json} = [ map { { id=>$_, text=>$_, leaf=>\0, children=>$tree{$_} } } sort keys %tree ];
    $c->forward("View::JSON");
}

use JSON::XS;
sub update : Local {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
	eval {
        my $role_actions = decode_json $p->{role_actions};
        my $role = $c->model('Baseliner::BaliRole')->find_or_create({ id=>$p->{id}>=0 ? $p->{id} : undef, role=>$p->{name}, description=>$p->{description} });
        $role->role( $p->{name} );
        $role->description( $p->{description} );
        $role->bali_roleactions->delete_all;
        foreach my $action ( @{ $role_actions || [] } ) {
            $role->bali_roleactions->find_or_create({ action=> $action->{action}, bl=>'*' });  #TODO bl from action list
        }
        $role->update();
    };
	if( $@ ) {
        warn $@;
		$c->stash->{json} = { success => \0, msg => _loc("Error modifying the role ").$@  };
	} else { 
		$c->stash->{json} = { success => \1, msg => _loc("Role '%1' modified", $p->{name} ) };
	}
	$c->forward('View::JSON');	
}

sub delete : Local {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
	eval {
        my $rs = $c->model('Baseliner::BaliRole')->search({ id=>$p->{id_role} });
        while ( my $r = $rs->next ) { $r->delete }
    };
	if( $@ ) {
        warn $@;
		$c->stash->{json} = { success => \0, msg => _loc("Error deleting the role ").$@  };
	} else { 
		$c->stash->{json} = { success => \1, msg => _loc("Role '%1' modified", $p->{name} ) };
	}
	$c->forward('View::JSON');	
}

sub duplicate : Local {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
	eval {
        my $r = $c->model('Baseliner::BaliRole')->find({ id=>$p->{id_role} });
        if( $r ) {
            my %orig =$r->get_columns; 
            delete $orig{id};
            my $role = $c->model('Baseliner::BaliRole')->create({ %orig });
            $role->role( $role->role . "-" . $role->id );
            $role->update;
            my $rs_actions = $r->bali_roleactions;
            while( my $ra = $rs_actions->next ) {
                $role->bali_roleactions->find_or_create({ action=>$ra->action });
            }
            $role->update;
        }
    };
	if( $@ ) {
        warn $@;
		$c->stash->{json} = { success => \0, msg => _loc("Error deleting the role ").$@  };
	} else { 
		$c->stash->{json} = { success => \1, msg => _loc("Role '%1' modified", $p->{name} ) };
	}
	$c->forward('View::JSON');	
}

sub grid : Local {
    my ( $self, $c ) = @_;
	$c->forward('/namespace/load_namespaces');
	$c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/role_grid.mas';
}


1;
