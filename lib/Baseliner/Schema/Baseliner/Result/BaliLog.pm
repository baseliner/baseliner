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
  "timestamp",
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
  "data",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "data_name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "data_length",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 126 },
  "module",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-25 16:08:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YNQC7dlQmXAUsAvADXXOvw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "job",
  "Baseliner::Schema::Baseliner::Result::BaliJob",
  { id => "id_job" },
);

1;

