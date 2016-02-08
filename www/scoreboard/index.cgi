#!/usr/bin/perl -T

use common::sense;
use CGI;
use Template;
use FindBin::libs;
use Puzzles;

my @scores = Puzzles->scores;

print CGI->new->header;
my $tt = Template->new({
        'INCLUDE_PATH' => 'templates',
        'PRE_CHOMP'    => 1,
    });
$tt->process(
    'scoreboard.tt2',
    { scores => \@scores }
) || die $tt->error;
