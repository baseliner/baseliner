package Baseliner::Schema::Baseliner::Result::BaliRole;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_role");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "role",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "description",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 2048,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "bali_roleactions",
  "Baseliner::Schema::Baseliner::Result::BaliRoleaction",
  { "foreign.id_role" => "self.id" },
);
__PACKAGE__->has_many(
  "bali_roleusers",
  "Baseliner::Schema::Baseliner::Result::BaliRoleuser",
  { "foreign.id_role" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-18 02:21:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GckB77B88koWahGbR1RXmw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
