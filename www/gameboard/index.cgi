#!/usr/bin/perl -T

use common::sense;
use CGI;
use FindBin::libs;
use Data::Dumper;
use Puzzles;
use Template;

my $db = Puzzles->db;

my $cg = CGI->new;

my %puzzles = Puzzles->all;
my @categories = Puzzles->categories;

my %solved;
for my $puzzle ($db->iquery('SELECT DISTINCT(puzzle) FROM solve WHERE', 'puzzle NOT LIKE "%EXTRA" ORDER BY puzzle')->flat) {
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

my @board = ([map { {image => "$_.png"} } @categories]);    # First row headers

my @levels = Puzzles->levels;
for my $level (@levels) {
    my @row;
    for my $cat (@categories) {
	my $puzzle = $puzzles{$cat}->{$level}->{puzzle};
	my $zip_file = $puzzle ? Puzzles->zip_file($puzzle) : undef;

	my $download_enabled = $level <= $solved{$cat} + 100 && $puzzles{$cat}{$level} && $zip_file;

	if ($zip_file) {
	    push @row,
	    { $download_enabled ? (image => "$level.png", file => $puzzle)
		  : ( image => "d$level.png") };
	} else {
	    push @row, {};
	}
    }
    push @board, \@row;
}

print $cg->header;

# Create an object from the template
my $tt = Template->new({
        'INCLUDE_PATH' => 'templates',
        'PRE_CHOMP'    => 1,
    });
$tt->process('gameboard.tt2', {board => \@board}) || die $tt->error;
