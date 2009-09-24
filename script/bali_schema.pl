BEGIN { $ENV{CATALYST_DEBUG} = 0 }
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Config::JFDI;
use Baseliner::Utils;

my $jfdi = Config::JFDI->new(name => "Baseliner");
my $config = $jfdi->get;
my $dsn = $config->{'Model::Baseliner'}->{'connect_info'};
my $version = '1.0';

require Baseliner::Schema::Baseliner;
my $schema = Baseliner::Schema::Baseliner->connect($dsn);
my $dir = './etc/db/';
$schema->create_ddl_dir(['Oracle', 'MySQL', 'SQLite', 'PostgreSQL'], $version, $dir );
oracle_adjust("$dir/Baseliner-Schema-Baseliner-$version-Oracle.sql" );
sqlite_adjust("$dir/Baseliner-Schema-Baseliner-$version-SQLite.sql" );
exit 0;

sub slurp {
    my $filename = shift;
    open my $f, '<', $filename or die $!;
    chomp( my @sql = <$f> );
    close $f;
    return @sql;
}

sub spit {
    my $filename = shift; 
    open my $f, '>', $filename;
    print $f join("\n", @_);
    close $f;
}

sub default_value {
    my $skip;
    my @out;
    for( @_ ) {
        # clean up DEFAULT value
        if( /DEFAULT/i ) {
            s{''(\S*)'\s*'}{'$1'}g;
            s{'(SYSDATE.*)'}{$1}g;
            s{'1\s*'}{1}g;
            s{'(TO_DATE.*)'$}{$1}g;
            s{'(TO_DATE)}{$1}g;
            s{DEFAULT ''}{DEFAULT '}g;
            s/'SYSDATE$/SYSDATE/g;
        }
        push @out,$_ unless m/^',$/;
    }
    return @out;
}

# sqlite default value correction
sub sqlite_adjust {
    my $filename = shift; 
    my @sql = slurp( $filename );
    @sql = default_value( @sql );
    spit( $filename, @sql ); 
}

# oracle cleanup, triggers and sequences
sub oracle_adjust {
    my $filename = shift; 
    my @sql = slurp( $filename );

    my @tables = _unique map { m/CREATE TABLE (\w+) /; "$1" } grep { /CREATE TABLE/ } @sql;
    print   "\nTABLES\n----------\n" . join ',',@tables;
    print "\n\nEXPORT\n----------\nexp tables=" . join ',',@tables;

    @sql = default_value( @sql );

    for my $table ( @tables ) {
        my $TAB = uc $table;
        push @sql, qq!
    DROP SEQUENCE ${TAB}_SEQ;

    CREATE SEQUENCE ${TAB}_SEQ
      START WITH 1
      MAXVALUE 999999999999999999999999999
      MINVALUE 1
      NOCYCLE
      CACHE 20
      NOORDER;

    CREATE OR REPLACE TRIGGER ${TAB}_TRG
        BEFORE INSERT ON ${TAB}
        REFERENCING NEW AS NEW OLD AS OLD
        FOR EACH ROW
        BEGIN
           SELECT ${TAB}_SEQ.NEXTVAL INTO :NEW.ID FROM dual;
        END;

        !;
    }

}

