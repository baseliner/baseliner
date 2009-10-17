package Baseliner::Schema::Baseliner::Result::BaliChainedService;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_chained_service");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "chain_id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "seq",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "key",
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
    size => 2000,
  },
  "step",
  {
    data_type => "VARCHAR2",
    default_value => "'RUN'",
    is_nullable => 1,
    size => 50,
  },
  "active",
  { data_type => "NUMBER", default_value => 1, is_nullable => 1, size => 126 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-22 17:33:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:54I0TkLg2V5peSG1mYp9uQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
