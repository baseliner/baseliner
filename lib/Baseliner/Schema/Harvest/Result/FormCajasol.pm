package Baseliner::Schema::Harvest::Result::FormCajasol;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("form_cajasol");
__PACKAGE__->add_columns(
  "formobjid",
  { data_type => "NUMBER", default_value => undef, is_nullable => 0, size => 38 },
  "observaciones",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2048,
  },
);
__PACKAGE__->set_primary_key("formobjid");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-16 02:05:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:p4MRJOODl59GgqDZWwcK9g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
