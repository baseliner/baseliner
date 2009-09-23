package Baseliner::Schema::Baseliner::Result::BaliSshScript;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_ssh_script");
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
    default_value => "'/'                 ",
    is_nullable => 0,
    size => 1000,
  },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => "'*'                 ",
    is_nullable => 0,
    size => 100,
  },
  "script",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "params",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1000,
  },
  "ssh_host",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "xorder",
  {
    data_type => "NUMBER",
    default_value => 1
        ,
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->sequence("bali_ssh_script_seq");
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "bali_scripts_in_file_dists",
  "Baseliner::Schema::Baseliner::Result::BaliScriptsInFileDist",
  { "foreign.script_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-07-06 09:25:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xxZl2Iy2nrB+1o9amXAJXQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
