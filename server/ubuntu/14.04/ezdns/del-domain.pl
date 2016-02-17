#!/usr/bin/perl -w
use strict;
use BerkeleyDB;
use Getopt::Long;

my $opt = {};
if (!GetOptions($opt, qw/bdb|b:s domain|d:s help|h/)) {
    usage('GetOptions processing failed.');
    exit 1;
}

if ($opt->{help}) {
    usage();
    exit 0;
}

my $db_file = $opt->{bdb};
if (!defined $db_file || $db_file eq '') {
    usage('Please specify an output BerkeleyDB filename.');
    exit 1;
}

my $del_domain = $opt->{domain};
if (!defined $del_domain || $del_domain eq '') {
    usage('Please specify a domain to be deleted.');
    exit 1;
}

my ($k, $v) = ("", "") ;
my @array_dns;

my $flags =  DB_CREATE;

my $dns_data = new BerkeleyDB::Hash
    -Filename  => $db_file,
    -Flags     => $flags,
    -Property  => DB_DUP | DB_DUPSORT,
    -Subname   => "dns_data"
    ||    die "Cannot create dns_data: $BerkeleyDB::Error";

print "dns_data===========\n";
my $cursor = $dns_data->db_cursor() ;
while ($cursor->c_get($k, $v, DB_NEXT) == 0) {
    print "k[".$k."] v[".$v."]\n";
    @array_dns = split(/ /,$k);
    if (@array_dns[0] eq $del_domain) {
        print "delete k[".$k."]\n";
        $dns_data->db_del($k);
    }
}

$cursor->c_close();
$dns_data->db_close();


my $dns_xfr = new BerkeleyDB::Hash
    -Filename  => $db_file,
    -Flags     => $flags,
    -Property  => DB_DUP | DB_DUPSORT,
    -Subname   => "dns_xfr"
    or die "Cannot create dns_xfr: $BerkeleyDB::Error";

print "dns_xfr===========\n";
$cursor = $dns_xfr->db_cursor() ;
while ($cursor->c_get($k, $v, DB_NEXT) == 0) {
    print "k[".$k."] v[".$v."]\n";
    if ($k eq $del_domain) {
        print "delete k[".$k."]\n";
        $dns_xfr->db_del($k);
    }
}

$cursor->c_close();
$dns_xfr->db_close();


my $dns_client = new BerkeleyDB::Hash
    -Filename  => $db_file,
    -Flags     => $flags,
    -Property  => DB_DUP | DB_DUPSORT,
    -Subname   => "dns_client"
    or die "Cannot create dns_client: $BerkeleyDB::Error";

print "dns_client===========\n";
$cursor = $dns_client->db_cursor() ;
while ($cursor->c_get($k, $v, DB_NEXT) == 0) {
    print "k[".$k."] v[".$v."]\n";
    if ($k eq $del_domain) {
        print "delete k[".$k."]\n";
        $dns_client->db_del($k);
    }
}

$cursor->c_close();
$dns_client->db_close();


my $reversed_zone = reverse($del_domain);
my $dns_zone = new BerkeleyDB::Btree
    -Filename  => $db_file,
    -Flags     => $flags,
    -Property  => 0,
    -Subname   => "dns_zone"
    or die "Cannot create dns_zone: $BerkeleyDB::Error";

print "dns_zone===========\n";
$cursor = $dns_zone->db_cursor() ;
while ($cursor->c_get($k, $v, DB_NEXT) == 0) {
    print "k[".$k."] v[".$v."]\n";
    if ($k eq $reversed_zone) {
        print "delete k[".$k."]\n";
        $dns_zone->db_del($k);
    }
}

$cursor->c_close();
$dns_zone->db_close();

exit 0;

sub usage {
    my ($message) = @_;
    if (defined $message && $message ne '') {
        print STDERR $message . "\n\n";
    }

    print STDERR "usage: $0 --bdb=<bdb-file> --domain=<delete-domain>\n";
    print STDERR "\tbdb-file: The BerkeleyDB file you wish to sort and use with bdbhpt-dynamic\n\n";
    print STDERR "\tdelete-domain: The domain you wish to delete\n\n";
}

