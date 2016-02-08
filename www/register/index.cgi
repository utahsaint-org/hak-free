#!/usr/bin/perl -T

use common::sense;
use CGI;
use Template;
use Data::UUID;
use FindBin::libs;
use Puzzles;

my $db = Puzzles->db;

my $cg = CGI->new;

# Form is submitted
my $uuid;
my %errors;
my ($cg_name, $cg_email) = (trim($cg->param('Name')), trim($cg->param('Email')));
if ($cg->param('Submit')) {

    if ($cg_email) {
        my $name;
        ($uuid, $name) = $db->iquery('SELECT uuid, name FROM hacker WHERE', {'UPPER(email)' => uc($cg_email)})->flat;
        $cg_name = $name if $uuid;
    }

    unless ($uuid) {
        $errors{name}  = 1 unless $cg_name;
        $errors{email} = 1 unless $cg_email;

        unless (%errors) {
            $uuid = Data::UUID->new->create_str;
            $uuid =~ s/\-//g;
            $db->iquery(
                'INSERT INTO hacker',
                {   name  => $cg_name,
                    email => $cg_email,
                    uuid  => $uuid
                });
        }
    }
}

print $cg->header;

# Create an object from the template
my $tt = Template->new({
        'INCLUDE_PATH' => 'templates',
        'PRE_CHOMP'    => 1,
    });
$tt->process(
    'register.tt2',
    {   name  => $cg_name,
        email => $cg_email,
        uuid  => $uuid,
        error => \%errors,
    },
) || die $tt->error;

sub trim {
    my $val = shift;

    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    $val =~ s/\s+/ /g;

    return $val;
}
