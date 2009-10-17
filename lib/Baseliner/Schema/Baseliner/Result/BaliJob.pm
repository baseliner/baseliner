package Baseliner::Schema::Baseliner::Result::BaliJob;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_job");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 45,
  },
  "starttime",
  {
    data_type => "DATE",
    default_value => "SYSDATE               ",
    is_nullable => 0,
    size => 19,
  },
  "maxstarttime",
  {
    data_type => "DATE",
    default_value => "SYSDATE+1             ",
    is_nullable => 0,
    size => 19,
  },
  "endtime",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "status",
  {
    data_type => "VARCHAR2",
    default_value => "'READY'               ",
    is_nullable => 0,
    size => 45,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => "'/'                   ",
    is_nullable => 0,
    size => 45,
  },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => "'*'                   ",
    is_nullable => 0,
    size => 45,
  },
  "runner",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "pid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "comments",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "type",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "username",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "ts",
  {
    data_type => "DATE",
    default_value => "SYSDATE\n",
    is_nullable => 1,
    size => 19,
  },
  "host",
  {
    data_type => "VARCHAR2",
    default_value => "'localhost'",
    is_nullable => 1,
    size => 255,
  },
  "owner",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "step",
  {
    data_type => "VARCHAR2",
    default_value => "'PRE'",
    is_nullable => 1,
    size => 50,
  },
  "id_stash",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "bali_job_items",
  "Baseliner::Schema::Baseliner::Result::BaliJobItems",
  { "foreign.id_job" => "self.id" },
);
__PACKAGE__->has_many(
  "bali_job_stashes",
  "Baseliner::Schema::Baseliner::Result::BaliJobStash",
  { "foreign.id_job" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-08 11:43:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iDPBwQgmIOLSMygv/MxKdQ


sub is_not_running {
    my $self = shift;
    return $self->status !~ m/RUNNING/ ;
}

__PACKAGE__->might_have(
  "job_stash",
  "Baseliner::Schema::Baseliner::Result::BaliJobStash",
  { "foreign.id" => "self.id_stash" },
);

# this is the best way to avoid having more than one stash per job
#  and still maintain ref integrity 
use Try::Tiny;
sub stash {
    my ( $self, $data ) = @_;

    if( defined $data && $data ) {
        my $stash = $self->bali_job_stashes->find({ id=>$self->id_stash });
        if( ref $stash ) {
            $stash->stash( $data );
        } else {
            $stash = $self->bali_job_stashes->first
              || $self->bali_job_stashes->create( { stash => $data } );
        }
        $stash->update;
        $self->id_stash( $stash->id );
        $self->update;
    } else {
		try {
			my $stash = $self->job_stash;
			return ref $stash ? $stash->stash : undef;
		} catch {
			return undef;
		};
    }
}


1;
