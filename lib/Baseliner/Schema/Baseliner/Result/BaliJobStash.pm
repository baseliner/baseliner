package Baseliner::Schema::Baseliner::Result::BaliJobStash;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_job_stash");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "stash",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "id_job",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "id_job",
  "Baseliner::Schema::Baseliner::Result::BaliJob",
  { id => "id_job" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-08 11:43:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OqaNzKhR8h3sa+EWcnxwEw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
