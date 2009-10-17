package BaselinerX::CA::Harvest::CLI::Version;
use Moose;
use Moose::Util::TypeConstraints;
with 'BaselinerX::Job::Element';

use DateTime;
use DateTime::Format::Strptime;

subtype 'Harvest::CLI::Type::DateTime' => as class_type('DateTime');

coerce 'Harvest::CLI::Type::DateTime'
        => from 'Str'
        => via { 
            my $parser = DateTime::Format::Strptime->new( pattern => '%m-%d-%Y;%H:%M:%S' );
            return $parser->parse_datetime( $_ );
        };
has 'name' => ( is=>'rw', isa=>'Str' );
has 'version' => ( is=>'rw', isa=>'Str' );
has 'tag' => ( is=>'rw', isa=>'Str' );
has 'data_size' => ( is=>'rw', isa=>'Int' );
has 'package' => ( is=>'rw', isa=>'Str' );
has 'creator' => ( is=>'rw', isa=>'Str' );
has 'created_on' => ( is=>'rw', isa=>'Harvest::CLI::Type::DateTime', coerce=>1 );
has 'modifier' => ( is=>'rw', isa=>'Str' );
has 'modified_file' => ( is=>'rw', isa=>'Harvest::CLI::Type::DateTime', coerce=>1 );
has 'modified_on' => ( is=>'rw', isa=>'Harvest::CLI::Type::DateTime', coerce=>1 );

sub item {
    my $self = shift;
    return File::Spec::Unix->catfile( $self->path, $self->name );
}

sub subapplication {
    my $self = shift;
    my $sa = $self->path_part('project');
    if( $sa ne uc($sa) ) { ## ignore uppercase projects
        #$sa =~s{_*[A-Z|_]+$}{};
        $sa =~s{\.\w+$}{};
    }
    return $sa;
}

1;
