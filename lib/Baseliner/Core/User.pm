package Baseliner::Core::User;
use Moose;
use Baseliner::Utils;
use Try::Tiny;

#has 'actions' => ( is=>'rw', isa=>'HashRef', default=>sub{{}} );
has 'username' => ( is=>'rw', isa=>'Str',  );
has 'languages' => ( is=>'rw', isa=>'ArrayRef',  );

sub BUILDARGS {
	my $class = shift;
    my %args = @_;
    my $out = {};

	if( ref $args{user} ) {
        my $user = $args{user};
		try { $out->{username} = $user->username };
		try { $out->{username} = $user->id };
	}
    return $class->SUPER::BUILDARGS($out);
}

sub email {
#TODO find the best way to return an email address
}

sub reset_actions {
    my ($self) = @_;
    $self->store->{actions} = {};
}

sub actions {
    my ($self ) = @_;
    $self->authorize unless ref $self->store->{actions};
    my @actions = keys %{ $self->store->{actions} };
    return @actions;
}

sub has_action {
    my ($self, %p) = @_;
    $self->authorize unless ref $self->store->{actions};
    my $actions = $self->store->{actions};
    if( ref $p{action} eq 'ARRAY' ) {
        foreach( @{ $p{action} } ) {
            return $actions->{$_} if defined $actions->{$_};
        }
    } else {
        return $actions->{$p{action}};
    }

    my $has_it;
}

sub add_action {
    my ($self, %p) = @_;
    my $actions = $self->store->{actions} || {} ;
    $actions->{$p{action}} = $p{ns};
    $self->store->{actions} = $actions;
    #my $actions = $self->{actions} || {};
    #$self->actions->{$p{action}} = $p{ns};
    #$self->{actions} = 'aaaaaaa';
}

sub authorize {
    my ( $self ) = @_;
    $self->reset_actions;
    my $username = $self->username;
    my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username=>uc $username });
    my @actions;
    _log ".............USER ROLE: ".$username;
    while( my $r=$rs->next ) {
        my $role = $r->role;
        my $ns = $r->ns;
        my $bl = $r->bl;
        _log ".............FOUND ROLE for $username: ".$role->role;
        my $actions = $role->bali_roleactions;
        while( my $action = $actions->next ) {
            _log ".............FOUND ACTION for $username: ".$action->action;
            push @actions, $action->action;
            $self->add_action( ns=>$ns, bl=>$bl, action=>$action->action );
        }
    }
    #$c->session->{actions} = [ _unique @actions ];
}

1;
