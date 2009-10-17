package BaselinerX::Job::Element;
use Moose::Role;

has 'path' => ( is=>'rw', isa=>'Str', trigger=>sub { my ($self,$val)=@_; $val=~s{\\}{\/}g; warn "....VAL ($val)";  $self->{path} = $val; }  );
has 'mask' => ( is=>'rw', isa=>'Str' );

sub path_parts {
    my $self = shift;
    my @mask = grep /.+/, split /\//, $self->mask;
    my @path = grep /.+/, split /\//, $self->path;
    my %parts;
    foreach my $m ( @mask ) {
        next unless $m;
        $parts{ $m } = shift @path;
    }
    return %parts;
}

sub path_part {
    my ($self,$part) = @_;
    my %parts = $self->path_parts;
    return $parts{$part};
}

1;
