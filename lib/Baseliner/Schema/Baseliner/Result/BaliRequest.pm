package Baseliner::Schema::Baseliner::Result::BaliRequest;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_request");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => "'*'",
    is_nullable => 1,
    size => 50,
  },
  "requested_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "finished_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "status",
  {
    data_type => "VARCHAR2",
    default_value => "'pending'",
    is_nullable => 1,
    size => 50,
  },
  "finished_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "requested_by",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "action",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "id_parent",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "key",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "type",
  {
    data_type => "VARCHAR2",
    default_value => "'approval'",
    is_nullable => 1,
    size => 100,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-19 13:29:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OzfivJ18yhiXB/fk+7UhSw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
