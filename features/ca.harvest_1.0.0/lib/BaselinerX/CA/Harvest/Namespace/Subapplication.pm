package BaselinerX::CA::Harvest::Namespace::Subapplication;
use Moose;
use Baseliner::Utils;
with 'Baseliner::Role::Namespace::Subapplication';

sub checkout { }

sub BUILDARGS {
    my $class = shift;

    if ( defined( my $row = $_[0]->{row} ) ) {
        my @related;
        my $app = $row->repository->repositname;
        push @related, 'application/' . $app;

        return {
            ns           => 'harvest.subapplication/' . $row->itemname,
            ns_name      => $row->itemname,
            ns_type      => _loc('Harvest Subapplication'),
            ns_id        => $row->itemobjid,
            ns_parent    => 'application/' . $app,
            parent_class => ['application'],
            related      => [@related],
            ns_data      => { $row->get_columns },
            provider     => 'namespace.harvest.subapplication',
        };
    }
    else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

our @parents;
sub parents {
    my $self = shift;
    return @parents if scalar @parents;
    my $item = Baseliner->model('Harvest::Haritems')->find({ itemobjid=>$self->ns_data->{itemobjid} });
    push @parents, 'application/' . $item->repository->repositname;
    push @parents, '/';
    return @parents;
}

1;

