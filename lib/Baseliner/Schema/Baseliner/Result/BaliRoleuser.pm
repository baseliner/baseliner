package Baseliner::Schema::Baseliner::Result::BaliRoleuser;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_roleuser");
__PACKAGE__->add_columns(
  "username",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "id_role",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "ns",
  {
    data_type => "VARCHAR2",
    default_value => "'/'                   ",
    is_nullable => 0,
    size => 100,
  },
);
__PACKAGE__->set_primary_key("username", "id_role");
__PACKAGE__->belongs_to(
  "id_role",
  "Baseliner::Schema::Baseliner::Result::BaliRole",
  { id => "id_role" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-18 02:21:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:THc9iP9N78qcpU8A/OCJCQ


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
  "role",
  "Baseliner::Schema::Baseliner::Result::BaliRole",
  { id => "id_role" },
);

1;
