package Baseliner;

use strict;
use warnings;

#use Catalyst::Runtime 5.80;
use Catalyst::Runtime 5.70;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use parent qw/Catalyst/;
our @modules;
BEGIN {

    if( $ENV{BALI_PLUGINS} ) {
        @modules = split /,/, $ENV{BALI_PLUGINS};
    }
    elsif( $ENV{BALI_FAST} ) {
        @modules = qw/
            StackTrace
            +CatalystX::Features
            +CatalystX::Features::Lib
            +CatalystX::Features::Plugin::ConfigLoader
            Authentication
            Email
            Cache
            Session		Session::Store::File	Session::State::Cookie
            +CatalystX::Features::Plugin::I18N
            +CatalystX::Features::Plugin::Static::Simple/;
    } else {
        @modules = qw/
            StackTrace
            +CatalystX::Features
            +CatalystX::Features::Lib
            +CatalystX::Features::Plugin::ConfigLoader
            +Baseliner::Plugin::CommandLine
            Authentication
			Unicode 
            Email
            Cache
            Session		Session::Store::File	Session::State::Cookie
            Singleton           
            +CatalystX::Features::Plugin::I18N
            +CatalystX::Features::Plugin::Static::Simple/;
    }
}
use Catalyst @modules;
our $VERSION = '0.01';
__PACKAGE__->config( name => 'Baseliner', default_view => 'Baseliner::View::Mason' );
__PACKAGE__->config( setup_components => { search_extra => [ 'BaselinerX' ] } );
__PACKAGE__->config( xmlrpc => { xml_encoding => 'utf-8' } );

__PACKAGE__->config->{static}->{dirs} = [
        'static',
        qr/images/,
    ];
__PACKAGE__->config->{static}->{ignore_extensions} 
        = [ qw/mas html js json css/ ];    

__PACKAGE__->config( {
        'View::JSON' => {
            expose_stash => 'json',
            encoding     => 'utf-8',
        },
    });

if( $ENV{BALI_CMD} ) {
	# only load the root controller, for capturing $c
	__PACKAGE__->config->{ setup_components }->{except} = qr/Controller(?!\:\:Root)|View/;
}


use Cache::FastMmap;
{
	no warnings;
	no strict;
	sub Cache::FastMmap::CLONE {} ## to avoid the no threads die 
}
#__PACKAGE__->config->{cache}->{storage} = 'bali_cache';
#__PACKAGE__->config->{cache}->{expires} = 60;  ## 60 seconds
#__PACKAGE__->config->{authentication}{dbic} = {
#    user_class     => 'Bali::BaliUser',
#    user_field     => 'username',
#    password_field => 'password'
#};

use FindBin '$Bin';
#$c->languages( ['es'] );
__PACKAGE__->config(
	'Plugin::I18N' => {
		maketext_options => {
			Style => 'gettext',
			Path => $Bin.'/../lib/Baseliner/I18N',
			Decode => 0,
		}
	}
);

## Authentication
    __PACKAGE__->config(
        'authentication' => {
            realms => {
                ldap => {
                    store => {
                        class               => "LDAP",
                        user_class          => "Baseliner::Core::User::LDAP",
                        entry_class         => "Baseliner::LDAP::Entry",
                        user_results_filter => sub { return shift->pop_entry },
                    },
                },
            },
        },
    );
    __PACKAGE__->config(
        'authentication' => {
            realms => {
                ldap_no_pw =>
                  \%{ __PACKAGE__->config->{authentication}->{realms}->{ldap} },
            },
        },
    );

# Start the application
__PACKAGE__->setup();

#Class::C3::initialize();

# Setup date formating for Oracle
my $dbh = __PACKAGE__->model('Baseliner')->storage->dbh;
if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
	$dbh->do("alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss'");
    $dbh->{LongReadLen} = __PACKAGE__->config->{LongReadLen} || 100000000; #64 * 1024;
    $dbh->{LongTruncOk} = __PACKAGE__->config->{LongTruncOk}; # do not accept truncated LOBs	
    # set sequences for oracle tables - avoid checking triggers for content
    Baseliner::Schema::Baseliner::Result::BaliBaseline->sequence('bali_baseline_seq');
    Baseliner::Schema::Baseliner::Result::BaliCalendar->sequence('bali_calendar_seq');
    Baseliner::Schema::Baseliner::Result::BaliCalendarWindow->sequence('bali_calendar_window_seq');
    Baseliner::Schema::Baseliner::Result::BaliChainedService->sequence('bali_chained_service_seq');
    Baseliner::Schema::Baseliner::Result::BaliChain->sequence('bali_chain_seq');
    Baseliner::Schema::Baseliner::Result::BaliConfig->sequence('bali_config_seq');
    Baseliner::Schema::Baseliner::Result::BaliJobItems->sequence('bali_job_items_seq');
    Baseliner::Schema::Baseliner::Result::BaliJob->sequence('bali_job_seq');
    Baseliner::Schema::Baseliner::Result::BaliJobStash->sequence('bali_job_stash_seq');
    Baseliner::Schema::Baseliner::Result::BaliLog->sequence('bali_log_seq');
    Baseliner::Schema::Baseliner::Result::BaliMessage->sequence('bali_message_seq');
    Baseliner::Schema::Baseliner::Result::BaliMessageQueue->sequence('bali_message_queue_seq');
    Baseliner::Schema::Baseliner::Result::BaliNamespace->sequence('bali_namespace_seq');
    Baseliner::Schema::Baseliner::Result::BaliReleaseItems->sequence('bali_release_items_seq');
    Baseliner::Schema::Baseliner::Result::BaliRelease->sequence('bali_release_seq');
    Baseliner::Schema::Baseliner::Result::BaliRequest->sequence('bali_request_seq');
    Baseliner::Schema::Baseliner::Result::BaliRole->sequence('bali_role_seq');
    Baseliner::Schema::Baseliner::Result::BaliWiki->sequence('bali_wiki_seq');
}

	
	# Inversion of Control
	require Baseliner::Core::Registry;
	Baseliner::Core::Registry->setup;
	Baseliner::Core::Registry->print_table;
    
    # Beep
    $ENV{CATALYST_DEBUG} && print "\7";

	# Make registry easily available to contexts
	sub registry {
		my $c = shift;
		return 'Baseliner::Core::Registry';
	}

	sub c {
		__PACKAGE__->commandline;
	}
	
	sub launch {
        my $c = shift;
        $c->model('Services')->launch(@_);
	}

	our $global_app;
	sub app {
		my $class = shift;
		my $c = shift;
		return $global_app = $c if ref $c;
		return $global_app if ref $global_app;

		#my $c;
		#my $meta = Class::MOP::get_metaclass_by_name('Baseliner');
		#$meta->make_mutable;
        #$meta->add_after_method_modifier( "dispatch", sub {
            #$c = shift;
        #});
		#$meta->make_immutable( replace_constructor => 1 );
		#Class::C3::reinitialize();
		#return $c;	
		bless {}, 'Baseliner';

	}

    #TODO move this to a model
	sub inf {
		my $c = shift;
		my %p = @_;
		$p{ns} ||= '/';
		$p{bl} ||= '*';
		if( $p{domain} ) {
			$p{domain} =~ s{\.$}{}g;
			$p{key}={ -like => "$p{domain}.%" };
		}
		print "KEY==$p{domain}\n";
		my %data;
		my $rs = $c->model('Baseliner::BaliConfig')->search({ ns=>$p{ns}, bl=>$p{bl}, key=>$p{key} });
		while( my $r = $rs->next  ) {
			(my $var = $r->key) =~ s{^(.*)\.(.*?)$}{$2}g;
			$c->stash->{$var} = $r->value;
			$data{$var} = $r->value;
		}
		return \%data;
	}

    #TODO deprecated:
                sub inf_bl {
                    my $c=shift;
                    $c->stash->{bl};
                }
                sub inf_search {
                    my ($c, %p ) = @_;
                    $p{ns} ||= '%';
                    $p{bl} ||= '%';
                    $p{key} ||= '%';
                    my $bl = $p{bl} eq '*' ? '%' : $p{bl};
                    my $ns = $p{ns} ? $p{ns}.'/%' : '%';
                    $ns =~ s{//}{/}g;
                    warn "------------SEARCH: $ns,$bl,$p{key}"; 
                    return $c->model('Baseliner::Bigtable')->search({ ns=>{ -like => $ns },bl=>{ -like =>$bl },key=>{ -like =>$p{key} }}); 
                }
                sub inf_write {
                    my ($c,%p) = @_;
                    $p{ns} ||= '/';
                    $p{bl} ||= '*';
                    $c->model('Baseliner::Bigtable')->create({ ns=>$p{ns},bl=>$p{bl}, key=>$p{key}, value=>$p{value} }); 
                }

# user shortcut
use Try::Tiny;
sub username {
	my $c = shift;
	try { return $c->session->{user}->username };
	try { return $c->user->username };
	try { return $c->user->id
	} catch {
		return undef;	
	};
}

# Utils
sub uri_for_static {
    my ( $self, $asset ) = @_;
    return ( $self->config->{static_path} || '/static/' ) . $asset;
}

# mokeypatching for 5.8
sub _comp_names_search_prefixes {
    my ( $c, $name, @prefixes ) = @_;
    my $appclass = ref $c || $c;
    my $filter   = "^\\w+(::\\w+)*::(" . join( '|', @prefixes ) . ')::';
    $filter = qr/$filter/; # Compile regex now rather than once per loop

    # map the original component name to the sub part that we will search against
    my %eligible = map { my $n = $_; $n =~ s{^.+::Model::}{}; $_ => $n; }
        grep { /$filter/ } keys %{ $c->components };

    # undef for a name will return all
    return keys %eligible if !defined $name;

    my $query  = ref $name ? $name : qr/^$name$/i;
    my @result = grep { $eligible{$_} =~ m{$query} } keys %eligible;

    return @result if @result;

    # if we were given a regexp to search against, we're done.
    return if ref $name;

    # regexp fallback
    $query  = qr/$name/i;
    @result = grep { $eligible{ $_ } =~ m{$query} } keys %eligible;

    # no results? try against full names
    if( !@result ) {
        @result = grep { m{$query} } keys %eligible;
    }

    # don't warn if we didn't find any results, it just might not exist
    if( @result ) {
        # Disgusting hack to work out correct method name
        my $warn_for = lc $prefixes[0];
        my $msg = "Used regexp fallback for \$c->${warn_for}('${name}'), which found '" .
           (join '", "', @result) . "'. Relying on regexp fallback behavior for " .
           "component resolution is unreliable and unsafe.";
        my $short = $result[0];
        $short =~ s/.*?Model:://;
        my $shortmess = Carp::shortmess('');
        if ($shortmess =~ m#Catalyst/Plugin#) {
           $msg .= " You probably need to set '$short' instead of '${name}' in this " .
              "plugin's config";
        } elsif ($shortmess =~ m#Catalyst/lib/(View|Controller)#) {
           $msg .= " You probably need to set '$short' instead of '${name}' in this " .
              "component's config";
        } else {
           $msg .= " You probably meant \$c->${warn_for}('$short') instead of \$c->${warn_for}({'${name}'}), " .
              "but if you really wanted to search, pass in a regexp as the argument " .
              "like so: \$c->${warn_for}(qr/${name}/)";
        }
        $c->log->warn( "${msg}$shortmess" );
    }

    return @result;
}


=head1 NAME

Baseliner - Catalyst based application

=head1 SYNOPSIS

    script/baseliner_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Baseliner::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
