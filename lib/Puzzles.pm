package Puzzles;

# ========================
# Configuration Settings
# ========================
our $puzzles_dir = "/opt/hacrep/challenges";
our $key_file = "$puzzles_dir/keys.secure";
our @categories = qw/BL PT CM WD NF GB/;
our @levels = qw/100 200 300 400 500/;
# ========================

use common::sense;
use Text::CSV;
use Database;

our %puzzles;

sub categories {
    return @categories;
}

sub levels {
    return @levels;
}

sub db {
    return Database->connect;
}

sub get_solve_lock {
    return Database->get_solve_lock;
}

sub release_solve_lock {
    return Database->release_solve_lock;
}

sub scores {
    shift if $_[0] eq __PACKAGE__;
    my %args = (-array => 0, # Return as array of arrays (otherwise returns as array of hashes)
		@_);

    my $res = db->iquery("SELECT name, email, SUM(points) points",
			 "FROM hacker h INNER JOIN solve s ON h.uuid = s.uuid",
			 "GROUP BY h.uuid ORDER BY points DESC");
    return $args{-array} ? $res->arrays : $res->hashes;
}

sub find_key_match {
    shift if $_[0] eq __PACKAGE__;
    my $match = uc(shift);
    $match =~ s/\s+//go;

    return unless $match;

    my %puzzles = all();

    for my $puzzle (values %puzzles) {
	if ($puzzle->{key_re}) {
	    return $puzzle if $match =~ /$puzzle->{key_re}/;
	} elsif ($puzzle->{keys}) {
	    return $puzzle if grep { uc($_) eq $match } @{$puzzle->{keys}};
	} elsif (uc($puzzle->{key}) eq $match) {
	    return $puzzle;
	}
    }
}

sub all {
  return %puzzles if %puzzles;

  open my $keys, $key_file or die "ERROR: Cannot open key file '$key_file'";
  while (<$keys>) {
    next if /^\s*\#/ || /^\s*$/;
    if (/^\s*(\S+)\s+(-?\d+)\s+(\S+)(?:\s+(-?\d+)?)/) {
      my ($puzzle, $points, $key, $first_solver_points) = ($1, $2, $3, $4);
      $puzzles{$puzzle} = {
			   puzzle => $puzzle,
			   points => $points,
			   first_solver_points => $first_solver_points,
			   key => $key,
			  };

      # Parse CSV key
      if ($key =~ m|^/([^/]+)/$|o) {
	  $puzzles{$puzzle}{key_re} = qr/$1/i;
      } elsif ($key =~ /[",]/o) {
	  my $csv = Text::CSV->new;
	  $csv->parse($key);
	  if ($csv->status) {
	      my @keys = $csv->fields;
	      $puzzles{$puzzle}{keys} = \@keys;
	  }
      }

      my ($cat_level, $name) = split('-', $puzzle);
      if ($cat_level) {
	my ($cat, $level);
	if (($level) = $cat_level =~ /^\S{2}(\d+)$/) {
	  $puzzles{$puzzle}->{level} = $level;
	  $cat = substr($cat_level,0,2);
	  $puzzles{$cat}->{$level} = $puzzles{$puzzle} if $puzzle !~ /EXTRA$/;
	} else {
	  $cat = $cat_level;
	}
	$puzzles{$puzzle}->{category} = $cat;

	if ($name =~ /^(.+)EXTRA$/o) {
	  $puzzles{$puzzle}->{extra} = 1;
	  $name = $1;
	}
	$puzzles{$puzzle}->{name} = $name;
      }
    }
  }

  return %puzzles;
}

sub zip_file {
    shift if $_[0] eq __PACKAGE__;
    my $puzzle = shift;

    return "$puzzle.zip" if $puzzle && -r "$puzzles_dir/$puzzle.zip";
}

sub zip_full {
    my $zip_file = zip_file(@_);
    return $zip_file ? "$puzzles_dir/$zip_file" : undef;
}

1;
