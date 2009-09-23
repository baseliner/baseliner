package Baseliner::Role::User;
use Moose::Role;
use Baseliner::Utils;

has 'actions' => ( is=>'rw', isa=>'HashRef', default=>sub{{}} );

sub username {
    my $self = shift;
	return $self->id if( $self->id );
	$self->next::method;
}

sub reset_actions {
    my ($self) = @_;
    $self->actions({});
}

sub actions {
    my ($self ) = @_;
    $self->authorize unless ref $self->actions;
    my @actions = keys %{ $self->actions };
    return @actions;
}

1;

