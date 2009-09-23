package Baseliner::Schema::Baseliner::Result::BaliLog;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_log");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "text",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2048,
  },
  "lev",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "id_job",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "more",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "data",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "ts",
  {
    data_type => "DATE",
    default_value => "SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => "'/'",
    is_nullable => 1,
    size => 255,
  },
  "provider",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "data_name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-08-21 11:03:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tTIY6fznfd4dNRT+H336mA


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "job",
  "Baseliner::Schema::Baseliner::Result::BaliJob",
  { id => "id_job" },
);

1;

