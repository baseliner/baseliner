package Baseliner::Schema::Baseliner::Result::BaliMessageQueue;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_message_queue");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "id_message",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "username",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "destination",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "sent",
  {
    data_type => "DATE",
    default_value => "SYSDATE",
    is_nullable => 1,
    size => 19,
  },
  "received",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "active",
  {
    data_type => "NUMBER",
    default_value => 1
        ,
    is_nullable => 1,
    size => 126,
  },
  "carrier",
  {
    data_type => "VARCHAR2",
    default_value => "'instant'",
    is_nullable => 1,
    size => 50,
  },
  "carrier_param",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "result",
  {
    data_type => "CLOB",
    default_value => undef,
    is_nullable => 1,
    size => 2147483647,
  },
  "attempts",
  { data_type => "NUMBER", default_value => 0, is_nullable => 1, size => 126 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "id_message",
  "Baseliner::Schema::Baseliner::Result::BaliMessage",
  { id => "id_message" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-17 12:24:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RaTyh04edbRNSU2TslffTQ

use Baseliner::Utils;

sub deliver_now {
    my $self = shift;
    my $now = DateTime->now(time_zone=>_tz);
    if( is_oracle ) {
        my $ora_now =  $now->strftime('%Y-%m-%d %T');
        $self->received( $ora_now );
    } else {
        $self->received( $now );
    }
    $self->active(0);
    $self->update;
}
1;
