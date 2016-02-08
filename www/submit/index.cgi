#!/usr/bin/perl -T

use common::sense;
use CGI;
use Template;
use Net::Twitter::Lite::WithAPIv1_1;
use FindBin::libs;
use Puzzles;

my $db = Puzzles->db;

my $cg = CGI->new;

# Form is submitted
my %status;
my $pname;

my ($cg_user, $cg_captured) = (uc(remove_spaces($cg->param('UserKey'))), uc(remove_spaces($cg->param('CaptureKey'))));
if ($cg->param('Submit') && $cg_user && $cg_captured) {
    my ($valid_user) = $db->iquery('SELECT COUNT(*) FROM hacker WHERE', {uuid => $cg_user})->flat;
    if (!$valid_user) {
	$status{invalid_user} = 1;
    } else {
	my %puzzles = Puzzles->all;
	if (my $puzzle_h = Puzzles->find_key_match($cg_captured)) {
	    my ($puzzle, $points, $first_solver_points) = ($puzzle_h->{puzzle}, $puzzle_h->{points}, $puzzle_h->{first_solver_points});
	    $status{solved} = 1;

	    Puzzles->get_solve_lock;
	    my ($already_solved) = $db->iquery(
		'SELECT COUNT(*) FROM solve WHERE',
		{   uuid   => $cg_user,
		    puzzle => $puzzle
		})->flat;
	    unless ($already_solved) {
		my ($not_first_solver) = $db->iquery('SELECT COUNT(*) FROM solve WHERE',
						     { puzzle => $puzzle })->flat;
		$points += $first_solver_points unless $not_first_solver;
		tweetit($puzzle) unless $not_first_solver || index($puzzle, "BADGE-") == 0;

		$db->iquery(
		    'INSERT INTO solve',
		    {   uuid      => $cg_user,
			puzzle    => $puzzle,
			points    => $points,
			solvetime => Database->now});
	    }
	    ($status{score}) = $db->iquery('SELECT SUM(points) FROM solve WHERE', {uuid => $cg_user})->flat;

	    Puzzles->release_solve_lock;
	} else {
	    ($status{score}) = $db->iquery('SELECT SUM(points) FROM solve WHERE', {uuid => $cg_user})->flat;

	    $status{error} = 1;
	    $db->iquery(
		'INSERT INTO attempt',
		{   uuid        => $cg_user,
		    capture_key => $cg_captured,
		    time        => Database->now});
	}
    }
} else {
    $status{invalid_user} = 1 unless $cg_user;
    $status{invalid_key}  = 1 unless $cg_captured;
}

print $cg->header;

# Create an object from the template
my $tt = Template->new({
        'INCLUDE_PATH' => 'templates',
        'PRE_CHOMP'    => 1,
    });
$tt->process(
    'solve.tt2',
    {   user_key    => $cg_user,
        capture_key => $cg_captured,
        status      => \%status,
    }) || die $tt->error;

sub remove_spaces {
    my $val = shift;

    $val =~ s/\s+//g;

    return $val;
}

sub tweetit {
    my $puzzle = shift;
    my $tweet = Net::Twitter::Lite::WithAPIv1_1->new(
	consumer_key => 'eZ1jv0c8cfgAz92WB7OGyQ',
	consumer_secret => 'fXVWn7ZuX4aJl1KfZvopSPcqilYQnRJXquCKJFeM10',
	access_token => '1730324137-1uq832fIrvpKlRasfdUeZLsYRMTqSon3gIgS0KM',
	access_token_secret => '2MNQHC5eFcmDRrCFMX3gfM9f4BzhXx8CHrBXT2zQVs');

    return $tweet->update({ status=> "HACKERS CHALLENGE:\n$puzzle Solved."});
}
