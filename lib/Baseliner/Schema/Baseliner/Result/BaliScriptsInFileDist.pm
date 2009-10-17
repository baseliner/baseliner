package Baseliner::Schema::Baseliner::Result::BaliScriptsInFileDist;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_scripts_in_file_dist");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "file_dist_id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "script_id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "script_id",
  "Baseliner::Schema::Baseliner::Result::BaliSshScript",
  { id => "script_id" },
);
__PACKAGE__->belongs_to(
  "file_dist_id",
  "Baseliner::Schema::Baseliner::Result::BaliFileDist",
  { id => "file_dist_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-07-06 09:25:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Wwpd7YKNyai4MT5zqbvynA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
