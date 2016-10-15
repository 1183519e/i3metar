#!/usr/bin/env perl
# vim:ts=4:sw=4:expandtab

use strict;
use warnings;
use JSON;
use XML::LibXML;
use WWW::Curl::Easy;
use IO::Async::Timer::Periodic;
use IO::Async::Loop;
use IO::Async::Stream;
use constant URL => 'https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&hoursBeforeNow=3&mostRecent=true&stationString=EDDN';
use constant XPATH => '/response/data/METAR/raw_text';

my $metar = "";
my $metar_curl;
my $metar_time = "";

my $loop  = IO::Async::Loop->new();
my $timer = IO::Async::Timer::Periodic->new(
    first_interval  => 0,
    interval        => 60,
    on_tick         => sub { get_metar() },
);
$timer->start();
$loop->add($timer);
my $stream = IO::Async::Stream->new(
    read_handle     => \*STDIN,
    write_handle    => \*STDOUT,
    on_read => sub {
        my ($self, $buffref, $eof) = @_;
        while ($$buffref =~ s/^,?(.*\n)//){
            my $statusline = $1;
            # Decode the JSON-encoded line.
            my @blocks = @{decode_json($statusline)};
            # Prefix our own information (you could also suffix or insert in the
            # middle).
            @blocks = ({
                full_text => $metar,
                name => 'metar',
                color => '#505050'
            }, @blocks);

            # Output the line as JSON.
            print encode_json(\@blocks) . ",\n";
        }
    }
);
$loop->add($stream);


# Don’t buffer any output.
$| = 1;

# Skip the first line which contains the version header.
print scalar <STDIN>;

# The second line contains the start of the infinite array.
print scalar <STDIN>;

$loop->run();

sub get_metar {
    my $curl = WWW::Curl::Easy->new;
    my $metar_curl;
    $curl->setopt(CURLOPT_URL, URL);
    $curl->setopt(CURLOPT_WRITEDATA,\$metar_curl);
    my $retcode = $curl->perform;
    if($retcode == 0){
        my $doc = XML::LibXML->new->parse_string($metar_curl);
        ($metar) = $doc->findvalue(XPATH);
    } else {
        $metar = "Error " . $curl->strerror($retcode);
        $metar = $curl->strerror($retcode);
    }
}

