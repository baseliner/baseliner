package Baseliner::Schema::Baseliner::Result::BaliWiki;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_wiki");
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
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "username",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "modified_on",
  {
    data_type => "DATE",
    default_value => "SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "content_type",
  {
    data_type => "VARCHAR2",
    default_value => "'text/plain'\n",
    is_nullable => 1,
    size => 255,
  },
  "id_wiki",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-22 18:47:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:k4O0wdEJHIvleSCPkfzzsA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
