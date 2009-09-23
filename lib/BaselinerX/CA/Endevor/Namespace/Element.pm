package BaselinerX::CA::Endevor::Namespace::Element;
use Moose;
use Baseliner::Plug;
use Baseliner::Utils;
use YAML;

has 'name'        => ( is => 'rw', isa => 'Str',      required => 1 );
has 'version'     => ( is => 'rw', isa => 'Str',      required => 1 );
has 'modified_by' => ( is => 'rw', isa => 'Str',      required => 1 );
has 'modified_on' => ( is => 'rw', isa => 'DateTime', required => 1 );

with 'Baseliner::Role::Namespace::Version';

sub checkout { }

sub ccid {
    my $self = shift;
    return $self->ns_data->{GENERATE_CCID}; # or LAST_ACT_CCID ?
}


1;
