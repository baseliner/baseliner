package BaselinerX::Comm::Email;
use Baseliner::Plug;
use Baseliner::Utils;
use Text::Template;
use MIME::Lite;
use Net::SMTP;
use Try::Tiny;
use Compress::Zlib;

with 'Baseliner::Role::Service';

register 'config.comm.email' => {
    name => 'Email configuration',
    metadata => [
        { id=>'frequency', name=>'Email daemon frequency', default=>10 },
        { id=>'server', name=>'Email server', default=>'CLUSTEREXCH01.gbp.corp.com' },
        { id=>'from', name=>'Email default sender', default=>'SCM <harvest@harvestpro>' },
        { id=>'domain', name=>'Email domain', default=>'exchange.local' },
        { id=>'max_attempts', name=>'Max attempts', default=>10 },
    ]
};

register 'service.daemon.email' => {
    name => 'Email Daemon',
    config => 'config.comm.email',
    handler => \&daemon,
};

sub daemon {
    my ( $self, $c, $config ) = @_;

    my $frequency = $config->{frequency};
    while( 1 ) {
        $self->process_queue( $c, $config );
        sleep $frequency;
    }
}
    
sub process_queue {
    my ( $self, $c, $config ) = @_;
    
    my $rs_queue = Baseliner->model('Baseliner::BaliMessageQueue')->search({ carrier=>'email', active=>1 });

    my %email;
    while( my $item = $rs_queue->next ) {
        my $message = $item->id_message;
        my $id = $message->id ;
        $email{ $id } = {};

        my $address = $item->destination || $self->resolve_address( $item->username );

        my $tocc = $item->carrier_param || 'to';
        push @{ $email{ $id }->{ $tocc } }, $address; 
        push @{ $email{ $id }->{ id_list } }, $item->id;

        $email{ $id }->{from} ||= $config->{from}; # from should be always from the same address
        $email{ $id }->{subject} ||= $message->subject;
        $email{ $id }->{body} ||= $message->body;
        $email{ $id }->{attach} ||= {
            data         => $message->attach,
            content_type => $message->attach_content_type,
            filename     => $message->attach_filename
        };
    }

    # first group by message
    for my $msg_id ( keys %email ) {
        my $em = $email{ $msg_id }; 
        _debug "Sending email '$em->{subject}' (id=$msg_id) to " . join ',',
          _array( $em->{to} ) . " and cc " . join ',', _array( $em->{cc} );

        my $result;
        try {
            $result = $self->send(
                server=>$config->{server},
                to => $em->{to},
                cc => $em->{cc},
                body => $em->{body},
                subject => $em->{subject},
                from => $em->{from},
                attach => [ $em->{attach} ],
            );
            # need to deactivate the message before sending it
            for my $id ( _array $em->{id_list} ) {
                Baseliner->model('Messaging')->delivered( id=>$id, result=>$result );
            }

        } catch {
            my $error = shift;
            for my $id ( _array $em->{id_list} ) {
                Baseliner->model('Messaging')->failed( id=>$id, result=>$error, max_attempts=>$config->{max_attempts} );
            }
        };
    }
}

sub resolve_address {
    my ( $self, $username ) = @_;
    my $config = Baseliner->model('ConfigStore')->get( 'config.comm.email' );
    my $domain = $config->{domain};
    return "$username\@$domain";
}

sub send {
    my ( $self, %p ) = @_;

	my $from = $p{from};
	my $subject = $p{subject};
	my @to = _array $p{to} ;
	my @cc = _array $p{cc} ;
	my $body = $p{body};
	my $content_type = $p{content_type};
    my @attach = _array $p{attach};

    # take out accents
    #use Text::Unaccent::PurePerl qw/unac_string/;
    #$subject = unac_string( $subject );
    $subject = '=?ISO-8859-1?Q?' . MIME::Lite::encode_qp( $subject ) ; # Building fa=?ISO-8859-1?Q?=E7ade?=
    $subject = substr( $subject, 0, length( $subject ) -2 ) . '?=';
	
	my $server=$p{server} || "localhost";
	
	Net::SMTP->new($server) or _throw "Error al intentar conectarse al servidor SMTP '$server': $!\n";	

	MIME::Lite->send('smtp', $server, Timeout=>60);  ## a veces hay que comentar esta línea

    if( !(@to>0 or @cc>0) ) { ### nadie va a recibir este correo
		_throw "No he podido enviar el correo '$subject'. No hay recipientes en la lista TO o CC.\n";
    }

	_debug " - Enviando correo (server=$server) '$subject'\nFROM: $p{from}\nTO: @to\nCC: @cc\n";

    my $msg = MIME::Lite->new(
        To        => "@to",
        Cc        => "@cc",
        From      => $from,
        Subject   => $subject,
        Datestamp => 0,
        Type      => 'multipart/mixed'
    );
	
    $msg->attach(
        Data     => $body,
        Type     => 'text/html',
        Encoding => 'base64'
    );

    foreach my $attach (@attach) {
        _throw "Error: attachment is not a hash but a $attach" unless ref $attach eq 'HASH';
        next unless length($attach->{data}) > 0;
        unless( $attach->{content_type} ) {
            $attach->{content_type} = 'application/x-gzip';
            $attach->{data} = compress( $attach->{data} );
        }
        $msg->attach(
            Data     => $attach->{data},
            Type     => $attach->{content_type},
            Filename => $attach->{filename},
            Encoding => 'base64'
        );
    }
	
    $msg->send('smtp');  ##si no pones smtp, lo manda por sendmail
}	

1;

