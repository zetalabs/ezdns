#!/usr/bin/perl -w
use strict;
use BerkeleyDB;
use Getopt::Long;

my $opt = {};
if (!GetOptions($opt, qw/bdb|b:s domain|d:s ip|i:s help|h/)) {
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

my $add_domain = $opt->{domain};
if (!defined $add_domain || $add_domain eq '') {
    usage('Please specify a domain to be deleted.');
    exit 1;
}

my $ip_address = $opt->{ip};
if (!defined $ip_address || $ip_address eq '') {
    usage('Please specify a domain to be deleted.');
    exit 1;
}

my $ip_ver = 0;
my $dns_type = "";
my @array_ipv4 = split(/\./, $ip_address);
if (@array_ipv4 == 4) {
    $ip_ver = 4;
    $dns_type = "A";
}
else {
    $ip_ver = 6;
    $dns_type = "AAAA";
}

# get domain name info
my $dns_name = "";
my $dns_zone = "";
my @array_dns = split(/\./,$add_domain);
my $array_size = @array_dns;

if ($array_size > 0) {
    $dns_name = $array_dns[0];
}

if ($array_size > 1) {
    $dns_zone = join(".", @array_dns[1..$array_size-1]);
}

my $new_k = "$dns_zone $dns_name";
my $need_update = 0;

my ($k, $v) = ("", "") ;
my $old_ip = "";
my @queue = ();

my $flags =  DB_CREATE;

my $dns_data = new BerkeleyDB::Hash
    -Filename  => $db_file,
    -Flags     => $flags,
    -Property  => DB_DUP | DB_DUPSORT,
    -Subname   => "dns_data"
    ||    die "Cannot create dns_data: $BerkeleyDB::Error";

print "dns_data===========\n";
my $cursor = $dns_data->db_cursor() ;
$need_update = 0;
while ($cursor->c_get($k, $v, DB_NEXT) == 0) {
    print "k[".$k."] v[".$v."]\n";
    if ($k eq $new_k) {
        @array_dns = split(/ /,$v);
        $dns_type = $array_dns[3];
        if ($dns_type eq "A") {
            $old_ip = $array_dns[4];
            if (($ip_ver == 4) && ($old_ip ne $ip_address)) {
                # IP address is different, save to update later.
                $array_dns[4] = $ip_address;
                $v = join(" ", @array_dns);
                print "save k[".$k."] v[".$v."]\n";
                push @queue,$v;
            }
            elsif (($ip_ver == 4) && ($old_ip eq $ip_address)) {
                # same IP address, do nothing.
                print "skip k[".$k."] v[".$v."]\n";
                $need_update = 1;
            }
            else {
                # IP address does not match, save to update later.
                push @queue,$v;
            }
        }
        elsif ($dns_type eq "AAAA") {
            $old_ip = $array_dns[4];
            if (($ip_ver == 6) && ($old_ip ne $ip_address)) {
                # IP address is different, save to update later.
                $array_dns[4] = $ip_address;
                $v = join(" ", @array_dns);
                print "save k[".$k."] v[".$v."]\n";
                push @queue,$v;
            }
            elsif (($ip_ver == 6) && ($old_ip eq $ip_address)) {
                # same IP address, do nothing.
                print "skip k[".$k."] v[".$v."]\n";
                $need_update = 1;
            }
            else {
                # IP address does not match, save to update later.
                push @queue,$v;
            }
        }
        else {
            # save to update later.
            push @queue,$v;
        }
    }
}

if ($need_update == 1) {
    print "delete k[".$new_k."]\n";
    $dns_data->db_del($new_k);
    my $count = 0;
    while ($count < @queue) {
        $v = $queue[$count];
        print "update k[".$new_k."] to v[".$v."]\n";
        $dns_data->db_put($new_k, $v);
        $count = $count+1;
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

if (($need_update == 1) && (@queue == 0)) {
    # delete domain
    while ($cursor->c_get($k, $v, DB_NEXT) == 0) {
        print "k[".$k."] v[".$v."]\n";
        if ($k eq $dns_zone) {
            if ($v eq $dns_name) {
                print "skip k[".$k."] v[".$v."]\n";
            }
            else {
                print "save k[".$k."] v[".$v."]\n";
                push @queue,$v;
            }
        }
    }
    print "delete k[".$dns_zone."]\n";
    $dns_xfr->db_del($dns_zone);
    my $count = 0;
    while ($count < @queue) {
        $v = $queue[$count];
        print "add k[".$dns_zone."] v[".$v."]\n";
        $dns_xfr->db_put($dns_zone, $v);
        $count = $count+1;
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
}

$cursor->c_close();
$dns_client->db_close();


my $reversed_zone = reverse($add_domain);
my $dns_zone_db = new BerkeleyDB::Btree
    -Filename  => $db_file,
    -Flags     => $flags,
    -Property  => 0,
    -Subname   => "dns_zone"
    or die "Cannot create dns_zone: $BerkeleyDB::Error";

print "dns_zone===========\n";
$cursor = $dns_zone_db->db_cursor() ;
while ($cursor->c_get($k, $v, DB_NEXT) == 0) {
    print "k[".$k."] v[".$v."]\n";
}

$cursor->c_close();
$dns_zone_db->db_close();

exit 0;

sub usage {
    my ($message) = @_;
    if (defined $message && $message ne '') {
        print STDERR $message . "\n\n";
    }

    print STDERR "usage: $0 --bdb=<bdb-file> --domain=<add-domain> --ip=<ip-address>\n";
    print STDERR "\tbdb-file: The BerkeleyDB file you wish to sort and use with bdbhpt-dynamic\n\n";
    print STDERR "\tadd-domain: The domain you wish to add\n\n";
    print STDERR "\tip-address: The IP address for the domain\n\n";
}

