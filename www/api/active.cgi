#!/usr/bin/perl -T

use common::sense;
use CGI;
use Template;
use FindBin::libs;
use Puzzles;

my $db = Puzzles->db;

my $cg = CGI->new;
my $query = $cg->param('puzzle');

my %puzzles = Puzzles->all;

my @categories = Puzzles->categories;

my %solved;
for my $puzzle ($db->iquery('SELECT DISTINCT(puzzle) FROM solve WHERE', { puzzle => $query }, 'AND puzzle NOT LIKE "%EXTRA" ORDER BY puzzle')->flat) {
    my ($cat, $level) = $puzzle =~ /^(\S{2})(\d+)/;
    next unless $cat && $level;
    $solved{$cat} = $level if $level > $solved{$cat};
}

# Close all or open all levels
my ($level_setting) = $db->iquery('SELECT v from kv WHERE',
				  { k => 'levels'})->flat;
if ($level_setting eq 'none') {
    $solved{$_} = -1000 for @categories;
} elsif ($level_setting eq 'all') {
    $solved{$_} = 10000 for @categories;
}

print $cg->header;

my ($qcat, $qlevel) = $query =~ /^(\S{2})(\d+)/;
if ($qlevel == 100 || $solved{$qlevel - 100} && $puzzles{$qcat}{$qlevel}) {
    print "GO";
} else {
    print "STOP";
}

