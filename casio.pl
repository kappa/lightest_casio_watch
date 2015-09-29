#! /usr/bin/perl
use strict;
use warnings;

use Encode;
use Web::Scraper;
use LWP::UserAgent;
use HTTP::Request::Common;
use Encode;
use Data::Dump;
use uni::perl;

my $DEBUG = 1;

sub get_page {
    my $req = shift;
    my $delay = 1;
    our $ua;
    unless (defined $ua) {
        $ua = LWP::UserAgent->new();
        $ua->show_progress(1) if $DEBUG;
    }

    my ($resp, $data);
    until (($resp = $ua->request($req))->is_success
        && ($data = $resp->content)) {

        warn "error fetching [@{[$req->uri]}], delaying for $delay\n";
        sleep($delay *= 2);
    }

    return $data;
}

my $url = 'http://www.casio-europe.com/euro/watch/collection/';

my $list_scraper = scraper {
    process '//a[starts-with(@href, "/euro/watch/collection/"', 'a[]' => sub { $_->attr('href') },
};

$|++;

my @a = @{$list_scraper->scrape(get_page(GET $url))->{a}};

my @watches;

foreach my $watch_url (@a) {
    my ($model) = map uc, ($watch_url =~ m{/([a-z0-9-]+)/$});

    my $page = get_page(GET "http://www.casio-europe.com$watch_url");    

    my $w = 999;
    if ($page =~ m{Weight</b>\D+(\d+)}) {
    	$w = $1;
    }

    push @watches, [ $model, "http://www.casio-europe.com$watch_url", "http://www.casio-europe.com/resource/images/watch/$model.jpg", $w ];
}

print <<'EOHTML';
<!DOCTYPE html>
<html> 
<head> 
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Лёгкие часы</title> 
</head> 
<body>
<table>
EOHTML

foreach my $watch (sort { $a->[3] <=> $b->[3] } @watches) {
    print <<"EOHTML";
        <tr>
        <td><a href="$watch->[1]"><img src="$watch->[2]"></a></td>
        <td><b>$watch->[3]&nbsp;г</b></td>
        <td><a href="http://market.yandex.ru/search.xml?text=casio+$watch->[0]">маркет</a></td>
        </tr>
EOHTML
}

print <<'EOHTML';
</table>
</body>
</html>
EOHTML
