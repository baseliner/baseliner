package Baseliner::Schema::Baseliner::Result::BaliRoleaction;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_roleaction");
__PACKAGE__->add_columns(
  "id_role",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "action",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => "'*'",
    is_nullable => 0,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("action", "id_role", "bl");
__PACKAGE__->belongs_to(
  "id_role",
  "Baseliner::Schema::Baseliner::Result::BaliRole",
  { id => "id_role" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-18 02:21:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lnUhf9fe0E4Uhgsq58BTjQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
