package Baseliner::Schema::Harvest::Result::Hardemoteproc;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("hardemoteproc");
__PACKAGE__->add_columns(
  "processobjid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "processname",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 128,
  },
  "stateobjid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "tostateid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "demotechgs",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 1 },
  "carrychgs",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 1 },
  "creationtime",
  { data_type => "DATE", default_value => undef, is_nullable => 0, size => 19 },
  "creatorid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "modifiedtime",
  { data_type => "DATE", default_value => undef, is_nullable => 0, size => 19 },
  "modifierid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "note",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2000,
  },
  "enforcebind",
  { data_type => "CHAR", default_value => "'N' ", is_nullable => 0, size => 1 },
  "checkdependencies",
  { data_type => "CHAR", default_value => "'N' ", is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("processobjid");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-13 22:19:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MTnQH3RQauM8bl36Iq/hfA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
