package BaselinerX::Job::Elements;
use Moose;
use Baseliner::Utils;

has 'elements' => ( is=>'rw', isa=>'ArrayRef', default=>sub{ [] } );

=head2 push_elements [@elements|$element]

Pushes an array or a single element into the collection. 
    
    my $es = new BaselinerX::Job::Elements;
    # either like this:
    $es->push_element(  new BaselinerX::Job::Element(path=>'/xx/yy/ww', mask=>'/app/nat/sub' ) );
    # or this:
    $es->push_elements( @elements );

=cut
sub push_element { push_elements(@_) }

sub push_elements {
    my $self = shift;
    my $e = $self->elements ;
    $self->elements( [ @{ $e || [] } , @_ ] );
}


=head2 list_part

Returns an array of unique path parts based on the part name passed as argument.

    my $es = new BaselinerX::Job::Elements;
    $es->push_element(  new BaselinerX::Job::Element(path=>'/xx/yy/ww', mask=>'/app/nat/sub' ) );
    my @applications = $es->list_part('app');
    my @natures = $es->list_part('nat');

=cut
sub list_part {
    my $self = shift;
    my $part = shift;
    if( $part) {
        my @list;
        for my $e ( @{ $self->elements } ) {
            my %parts = $e->path_parts;
            push @list, $parts{$part} if $parts{$part};
            eval {  ## may die if method $part doesn't exist
                push @list, $e->$part;
            };
        }
        return _unique @list; 
    } else {
        return @{ $self->elements || [] };
    }
}
sub list { list_part(@_) }

=head2 cut_to_subset (part, value)

Returns a new Elements collective reduced to a subset.

    my $elements = new BaselinerX::Job::Elements;
    $elements->cut_to_subset( 'nature', 'J2EE' );
    
=cut
sub cut_to_subset {
    my $self = shift;
    my $part = shift;
    my $value = shift;
    return __PACKAGE__->new( elements=>[ $self->subset( $part, $value ) ] );
}


=head2 subset (part, value)

Returns an array of elements. 

=cut
sub subset {
    my ($self, $part, $value ) = @_;
    my @subset;
    for my $e ( @{ $self->elements } ) {
        my %parts = $e->path_parts;
        if( $parts{$part} eq $value ) {
            push @subset, $e;
        } else {
            eval {  ## may die if method $part doesn't exist
                push @subset, $e if $e->$part eq $value;
            };
        }
    }
    return @subset;
}

1;
