#!/usr/bin/perl

# Run the test suite

use common::sense;
use FindBin::libs;
use FindBin;
use Test::More;

database();
puzzles();
done_testing();

sub database {
    print "\nDatabase tests\n===========\n";
    require_ok("Database");
    require SQL::Interp;

    my ($db1, $db2);
    ok (($db1 = Database->connect(1)) && $db1->query("SHOW TABLES")->flat &&
	($db2 = Database->connect(1)) && $db2->query("SHOW TABLES")->flat, "Connect to database");

    # Test locks
    $Database::db = $db1;
    ok (Database->release_solve_lock == undef, "Can't release Lock('solve')");
    ok ( eval { Database->get_solve_lock(1) == 1 }, "Lock('solve') & hold");

    $Database::db = $db2;
    ok !eval { Database->get_solve_lock(0.01) }, "Lock('solve') already locked";
    ok (Database->get_lock('test',0.01) == 1, "Lock('test') & hold");
    ok (Database->release_solve_lock == 0, "Can't release Lock('solve')");

    $Database::db = $db1;
    ok (Database->release_solve_lock == 1, "Release Lock('solve')");
    ok !eval { Database->get_lock('test', 0.01) }, "Lock('test') already locked";
    ok (Database->release_lock('test') == undef, "Can't release Lock('test')");

    $Database::db = $db2;
    ok (Database->release_lock('test') == 1, "Release Lock('test')");
    ok (Database->release_lock('test') == undef, "Re-release Lock('test')");
    ok (Database->get_solve_lock(0.01) == 1, "Acquire Lock('solve')");

    $Database::db = $db1;
    ok eval { Database->get_lock('test', 1) == 1}, "Acquire Lock('test')";

    ok((SQL::Interp::sql_interp(Database->sql("NOW()")))[0] eq "NOW()", "Database->sql");
    ok((SQL::Interp::sql_interp(Database->now))[0] eq "NOW()", "Database->now");

    $Database::db = undef;
}

sub puzzles {
    print "\nPuzzle tests\n===========\n";
    my $test_key_file = "$FindBin::Bin/test.keys.secure";

    require_ok("Puzzles");

    # Load keys.secure
    ok $Puzzles::key_file &&
	($Puzzles::key_file = $test_key_file) &&
	($Puzzles::puzzles_dir = $FindBin::Bin) &&
	$Puzzles::puzzles_dir eq $FindBin::Bin &&
	$Puzzles::key_file eq $test_key_file, "Load test keys.secure";

    # Puzzles->all
    my %expect = (
	BL100 => { category => "BL", level => 100, name => "Downloadze", points => 100, first_solver_points => undef, key => '"a3ee5e6bda390709bfef4b0dafd8956032551890","1234"', puzzle => "BL100-Downloadze", keys => [qw/a3ee5e6bda390709bfef4b0dafd8956032551890 1234/] },
	PT200 => { category => "PT", level => 200, name => "Downloadsx", points => 200, first_solver_points => 10, key => "/Its(the)?oneyou(donot|don't)seethatcounts?.?/", puzzle => "PT200-Downloadsx", key_re => qr/Its(the)?oneyou(donot|don't)seethatcounts?.?/i },
	CM300 => { category => "CM", level => 300, name => "Downloadcc", points => 300, first_solver_points => 10, key => "[TheDvorakCryptoIsNotRealCrypto]", puzzle => "CM300-Downloadcc" },
    );
    my %puzzles = Puzzles->all;
    is_deeply(\%puzzles, {
	"PRE-IDidAPresentation" => { category => "PRE", name => "IDidAPresentation", points => 300, first_solver_points => 0, key => 'ThisIsAllIGot', puzzle => "PRE-IDidAPresentation" },
	"BL100-Downloadze" => $expect{BL100},
	"PT200-Downloadsx" => $expect{PT200},
	"CM300-Downloadcc" => $expect{CM300},
	"CM300-DownloadccEXTRA" => { category => "CM", level => 300, name => "Downloadcc", points => 300, first_solver_points => undef, key => "ExtraKey", extra => 1, puzzle => "CM300-DownloadccEXTRA" },
	"BL" => { 100 => $expect{BL100} },
	"PT" => { 200 => $expect{PT200} },
	"CM" => { 300 => $expect{CM300} },
    }, "Puzzles->all");

    # Puzzles->find_key_match
    is_deeply(Puzzles->find_key_match("Itsoneyoudon'tseethatcount"), $expect{PT200}, "Puzzles->find_key_match");

    # Puzzles->categories, Puzzles->levels
    my @categories = Puzzles->categories;
    is_deeply (\@categories, \@Puzzles::categories, "Puzzles->categories");
    my @levels = Puzzles->levels;
    is_deeply (\@levels, \@Puzzles::levels, "Puzzles->levels");

    # Puzzles->scores
    is_deeply(Puzzles->scores, Database->connect->iquery("SELECT name, email, SUM(points) points",
							 "FROM hacker h INNER JOIN solve s ON h.uuid = s.uuid",
							 "GROUP BY h.uuid ORDER BY points DESC")->hashes, "Puzzles->scores");
    is_deeply(Puzzles->scores(-array=>1),
	      Database->connect->iquery("SELECT name, email, SUM(points) points",
					"FROM hacker h INNER JOIN solve s ON h.uuid = s.uuid",
					"GROUP BY h.uuid ORDER BY points DESC")->arrays, "Puzzles->scores(-array=>1)");

    # Puzzles->zip_full
    ok (Puzzles->zip_full("BL100-Downloadze") eq "$FindBin::Bin/BL100-Downloadze.zip", "Puzzles->zip_full");
}
