package Baseliner::Schema::Baseliner::Result::BaliCalendar;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_calendar");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "name",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 100,
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
  "description",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "bali_calendar_windows",
  "Baseliner::Schema::Baseliner::Result::BaliCalendarWindow",
  { "foreign.id_cal" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-07-20 16:16:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8V2OphnPUcRna0oNlpwRCA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
