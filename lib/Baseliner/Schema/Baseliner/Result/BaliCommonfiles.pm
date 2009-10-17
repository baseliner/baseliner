package Baseliner::Schema::Baseliner::Result::BaliCommonfiles;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_commonfiles");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "nombre",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 64,
  },
  "tipo",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 1 },
  "descripcion",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 4000,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => "'/'                   ",
    is_nullable => 0,
    size => 100,
  },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => "'*'                   ",
    is_nullable => 0,
    size => 100,
  },
  "f_alta",
  {
    data_type => "DATE",
    default_value => "SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "f_baja",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "bali_commonfiles_values",
  "Baseliner::Schema::Baseliner::Result::BaliCommonfilesValues",
  { "foreign.fileid" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-06-23 17:45:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ygfJGbzLBqUM34Bp+MV9sQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
