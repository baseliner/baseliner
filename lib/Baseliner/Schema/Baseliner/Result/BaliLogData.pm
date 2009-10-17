package Baseliner::Schema::Baseliner::Result::BaliLogData;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_log_data");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "id_log",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "data",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "timestamp",
  {
    data_type => "DATE",
    default_value => "SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2048,
  },
  "type",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "len",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "id_log",
  "Baseliner::Schema::Baseliner::Result::BaliLog",
  { id => "id_log" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-25 13:50:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Xv/wkvMiSqcN9mHwaKLgeg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
