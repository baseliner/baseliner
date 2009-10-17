package Baseliner::Schema::Baseliner::Result::BaliCommonfilesValues;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_commonfiles_values");
__PACKAGE__->add_columns(
  "fileid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "clave",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 256,
  },
  "valor",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 4000,
  },
  "secordesc",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
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
  {
    data_type => "DATE",
    default_value => "TO_DATE('99991231','yyyymmdd') \n",
    is_nullable => 1,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("fileid", "id");
__PACKAGE__->belongs_to(
  "fileid",
  "Baseliner::Schema::Baseliner::Result::BaliCommonfiles",
  { id => "fileid" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-06-23 17:45:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:T8tIVuA9uQzCGzQ/79HMEQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
