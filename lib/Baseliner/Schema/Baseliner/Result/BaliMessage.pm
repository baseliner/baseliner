package Baseliner::Schema::Baseliner::Result::BaliMessage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_message");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "subject",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "body",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "created",
  {
    data_type => "DATE",
    default_value => "SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "active",
  {
    data_type => "NUMBER",
    default_value => 1
        ,
    is_nullable => 1,
    size => 126,
  },
  "attach",
  {
    data_type => "BLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "sender",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "content_type",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "attach_content_type",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "attach_filename",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "bali_message_queues",
  "Baseliner::Schema::Baseliner::Result::BaliMessageQueue",
  { "foreign.id_message" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-17 12:24:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+RuGBYOhhRh+hqhIJXiNpw


sub from {  # from is a sql reserved word
    my $self = shift;
    return $self->sender( @_ );
}

1;
