package Database;

use common::sense;
use DBIx::Simple;
use SQL::Interp;

our $db;
sub connect {
    shift if $_[0] eq __PACKAGE__;
    my $new = shift;
    if ($new || !$db) {
	$db = DBIx::Simple->connect("DBI:mysql:database=puzzle","game","gamepasswd");
	die "Can't connect to database" unless $db;
    }
    return $db;
}

sub now {
    return sql("NOW()");
}

sub sql {
    shift if $_[0] eq __PACKAGE__;
    return SQL::Interp::sql(@_);
}

sub get_lock {
    shift if $_[0] eq __PACKAGE__;
    my $lock = shift or die "ERROR: Lock name must be specified";
    my $delay = shift || 5;

    my $count;
    my $res;
    $res = (Database->connect->query("SELECT GET_LOCK(?,?)", $lock, $delay)->flat)[0];
    die "Couldn't GET_LOCK('$lock')\n" if !$res;
    return $res;
}

sub release_lock {
    shift if $_[0] eq __PACKAGE__;
    my $lock = shift or die "ERROR: Lock name must be specified";
    return (Database->connect->query("SELECT RELEASE_LOCK(?)", $lock)->flat)[0];
}

sub get_solve_lock {
    shift if $_[0] eq __PACKAGE__;
    my $delay = shift;
    return Database->get_lock('solve', $delay);
}

sub release_solve_lock {
    return Database->release_lock('solve');
}

1;
