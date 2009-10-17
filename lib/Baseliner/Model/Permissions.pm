package Baseliner::Model::Permissions;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;

register 'action.admin.root' => { name=>'Root action - can do anything' };

sub create_role {
    my ($self, $name, $description ) = @_;

    $description ||= _loc( 'The %1 role', $name );

    my $role = Baseliner->model('Baseliner::BaliRole')->find_or_create({ role=>$name });
    $role->description( $description );
    $role->update;
    return $role;
}

# ( action, role_name )
sub add_action {
    my ($self, $action, $role_name, %p ) = @_;
	my $bl = $p{bl} || '*';
    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$role_name })->first;
    if( ref $role ) {
        my $actions = $role->bali_roleactions->search({ action=>$action })->first;
        if( ref $actions ) {
            die _loc( 'Action %1 already belongs to role %2', $action, $role_name );
        } else {
            return $role->bali_roleactions->create({ action => $action, bl=>$bl });
        }
    } else {
        die _loc( 'Role %1 not found', $role_name );
    }
}

# delete by id=>Int or role=>Str
sub delete_role {
    my ( $self, %p ) = @_;
    
    if( $p{id} ) {
        my $role = Baseliner->model('Baseliner::BaliRole')->find({ id=>$p{id} });

        die _loc( 'Role with id "%1" not found', $p{id} ) unless ref $role;

        my $role_name = $role->role;
        $role->delete;
        return $role_name;
    } else {
        my @role_names;
        my $roles = Baseliner->model('Baseliner::BaliRole')->search({ role=>$p{role} });
        unless( ref $roles ) {
            die _loc( 'Role with id "%1" or name "%2" not found', $p{id}, $p{role} );
        } else {
            while( my $role = $roles->next ) {
                push @role_names, $role->role;
                $role->delete;
            }
        }
        return @role_names;
    }
}

#  username=>Str, role=>Str, [ ns=>Str, bl=>Str ]
sub grant_role {
    my ($self, %p ) = @_;

    $p{ns} ||= '/';
    $p{bl} ||= '*';

    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$p{role} })->first;
    unless( ref $role ) {
        $role = $self->create_role( $p{role} )
          or die "Could not create role '$p{role}'";
    } 

    my $grant = Baseliner->model('Baseliner::BaliRoleuser')->find_or_create({
        username => $p{username},
        ns => $p{ns},
        id_role => $role->id,
    });
    return 1 if ref $grant;
}

#  username=>Str, role=>Str, [ ns=>Str, bl=>Str ]
sub deny_role {
    my ($self, %p ) = @_;

    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$p{role} })->first;

    die _loc( 'Role %1 not found', $p{role} ) unless ref $role;

    my $deniable = Baseliner->model('Baseliner::BaliRoleuser')->search({
        username => $p{username},
        id_role => $role->id,
    });

    die _loc( 'User %1 does not have role %2', $p{username}, $p{role} ) unless ref $role;

    my $denied;
    while( my $row = $deniable->next ) {
        if( $p{ns} && !$p{bl} ) {
            $row->delete if ns_match( $row->ns, $p{ns} );
            $denied++; 
        }
        elsif( ! $p{ns} && $p{bl} ) {
            $row->delete if $row->bl eq $p{bl};
            $denied++; 
        }
        elsif( $p{ns} && $p{bl} ) {
            $row->delete
                if ( $row->bl eq $p{bl} && ns_match( $row->ns, $p{ns} ) );
            $denied++; 
        }
        else {
            $row->delete;
            $denied++; 
        }
    }
    return $denied;
}

sub user_has_action {
    my ($self, $username, $action, %p ) = @_;

    my @root_users = $self->list( action=> 'action.admin.root' );
    return 1 if grep /$username/, @root_users;

    my @users = $self->list( action=> $action, ns=>$p{ns}, bl=>$p{bl} );

    return grep /$username/, @users;
}

# list users that have an action
#    username=>Str, [ bl=>Str ]
#  or actions that a user has
#      action=>Str, [ ns=>Str, bl=>Str ]
sub list {
    my ( $self, %p ) = @_;

    my $ns = defined $p{ns} ? $p{ns} : '/';
    my $bl = $p{bl} || 'any';

    $p{recurse} = defined $p{recurse} ? $p{recurse} : 1;
    $p{action} or $p{username} or die _loc( 'No action or username specified' );

    return Baseliner->model('Actions')->all_actions
      if $p{username} && $self->is_root( $p{username} );

    my $query = $p{action}
        ? { -or => [ action=> $p{action}, action => { -like => "$p{action}.%" } ] }
        : { username=>$p{username} };
	
	$query->{bl} = $bl
		unless $bl eq 'any';

    my $roles = Baseliner->model('Baseliner::BaliRole')->search(
        $query,
        { join     => ['bali_roleusers', 'bali_roleactions'], }
    );

    my @list;
    while( my $role = $roles->next ) {
        my $data= $p{action} ? $role->bali_roleusers : $role->bali_roleactions;
        push @list,
            map { $p{action} ? $_->username : $_->action }
            grep { $p{username} ? 1 : $ns eq 'any' ? 1 : ns_match( $_->ns, $ns) }
            $data->all;
    }

    # recurse list on parents
    if( $p{recurse} ) {
        my $item = Baseliner->model('Namespaces')->get( $ns );
        _throw "No he podido encontrar el item '$ns'" unless ref $item;
        for my $parent ( $item->parents ) {
            push @list, $self->list( ns=>$parent, bl=>$bl, recurse=>0, ( $p{action} ? (action=>$p{action}) : (username=>$p{username}) ) );
        }
    }

    return _unique @list;
}

sub is_root {
    my ( $self, $username ) = @_;
    $username or die _loc('Missing username');
    my $rs =
      Baseliner->model('Baseliner::BaliRoleuser')->search( { username => $username },
         );

    while( my $r = $rs->next ) {
        my $role = $r->id_role;
        my $actions = $role->bali_roleactions;
        while( my $action = $actions->next ) {
            return 1 if $action->action eq 'action.admin.root';   
        }
    }
    return 0;
}

1;
