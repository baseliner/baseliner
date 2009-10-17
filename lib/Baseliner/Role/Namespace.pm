package Baseliner::Role::Namespace;
use Moose::Role;

has 'ns' => ( is=>'rw', isa=>'Str', required=>1 ); ## the namespace path
has 'ns_name' => ( is=>'rw', isa=>'Str', required=>1 ); ## the namespace name token
has 'ns_type' => ( is=>'rw', isa=>'Str', required=>1 ); ## a text that represents the namespace
has 'ns_id' => ( is=>'rw', isa=>'Any' );  ## the namespace provider's internal id
has 'ns_info' => ( is=>'rw', isa=>'Any' );  ## array of info to present the user
has 'ns_data' => ( is=>'rw', isa=>'Any' );  ## free data store for the provider
has 'ns_parent' => ( is=>'rw', isa=>'Any' );  ## parent ns
has 'icon' => ( is=>'rw', isa=>'Str' );  ## icon path or css to represent ns
has 'user' => ( is=>'rw', isa=>'Str', default=>'-' ); 
has 'service' => ( is=>'rw', isa=>'Str' );  ## who to call in a job
has 'provider' => ( is=>'rw', isa=>'Str' ); ## who generated this
has 'related' => ( is=>'rw', isa=>'ArrayRef', default=>sub{[]} ); 
has 'date' => ( is=>'rw', isa=>'Str', );  ## object last modified date

#has 'can_job' => ( is=>'rw', isa=>'Bool', default=>0 );  ## can it be included in a job?
has 'why_not' => ( is=>'rw', isa=>'Str', );  ## if it cannot be included, why not? 

#TODO requires 'name'; - name resolution in class

sub parents {   #TODO this should be a require, but for now just override in classes
	my $self = shift;
    my @parents = ('/');
    return @parents;
}

sub compose_path {
	my $self = shift;
    return '/' . join '/', @_;
}

sub ns_text {
	my $self = shift;
	return $self->ns_type if( $self->ns eq '/');
	return $self->ns_name . " (" . $self->ns_type . ")";
}


1;
