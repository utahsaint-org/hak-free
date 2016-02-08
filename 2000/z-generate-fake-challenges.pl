#!/usr/bin/perl

my @CAT=("BL", "PT", "PM", "PP", "CM", "GB", "3D", "NF");
my @VAL=("100", "200", "300", "400", "500", "600", "700");

	open (SCORES, "> keys.secure");

	print SCORES '##'; print SCORES "\n";
	print SCORES '## ==================================================='; print SCORES "\n";
	print SCORES '##'; print SCORES "\n";

foreach (@CAT) {
	my $CAT=$_;
	foreach (@VAL) {
		my $FILE="$CAT" . "$_" . "-Download$_.txt";
		my $DATA="$CAT" . "$_" . "-Download$_.zip";
		open (DROP, "> $FILE");
		print DROP "DUMMY DATA FOR ZIP FILE";
		close DROP;
		system ("zip $DATA $FILE");
		unlink $FILE;
		close VIP;
		print SCORES "$CAT" . "$_-Download$_\t$_\t$CAT" . "TEST$_\t10\n";
		}
	print SCORES '##'; print SCORES "\n";
	print SCORES '## ==================================================='; print SCORES "\n";
	print SCORES '##'; print SCORES "\n";
	}

close SCORES;
