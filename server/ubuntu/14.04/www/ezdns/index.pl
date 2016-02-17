#!/usr/bin/perl

use Apache2::RequestRec;
use Apache2::RequestUtil;
use BerkeleyDB;

my $r = Apache2::RequestUtil->request;

my ($res, $sent_pw) = $r->get_basic_auth_pw;
return $res if $res != Apache2::Const::OK;

# response
$r->content_type('text/plain');

my $res_OK = "OK";
my $res_Error = "Error";

my $err_update_failed = "update failed";

# get remote client's IP addresses
my $remote_ip = $ENV{"REMOTE_ADDR"};

my $remote_ip_ver = 0;
my @array_ipv4 = split(/\./, $remote_ip);
if (@array_ipv4 == 4) {
    $remote_ip_ver = 4;
}
else {
    $remote_ip_ver = 6;
}

# get domain name info
my $dns_name = "";
my $dns_zone = "";
my $dns_type = "";
my @array_dns = split(/\./,$r->user);
my $array_size = @array_dns;

if ($array_size > 0) {
    $dns_name = @array_dns[0];
}

if ($array_size > 1) {
    $dns_zone = join(".", @array_dns[1..$array_size-1]);
}

# retrieve dns info from db
my $db_file = "/var/cache/bind/dlz/dnsdata.db";
my $db_flags =  DB_CREATE;

my $dns_data = new BerkeleyDB::Hash
    -Filename  => $db_file,
    -Flags     => $db_flags,
    -Property  => DB_DUP | DB_DUPSORT,
    -Subname   => "dns_data"
    ||    die "Cannot create dns_data: $BerkeleyDB::Error";


my $db_cursor = $dns_data->db_cursor();

my $db_key = "$dns_zone $dns_name";
my $db_value = "";
my $orig_ip = "";
$db_flags =  DB_SET;
while ($db_cursor->c_get($db_key, $db_value, $db_flags) == 0) {
    @array_dns = split(/ /,$db_value);
    if (@array_dns > 4) {
        $dns_type = @array_dns[3];
        if (($remote_ip_ver == 4) && ($dns_type eq "A")) {
            if (@array_dns[4] ne $remote_ip) {
                $orig_ip = @array_dns[4];
                @array_dns[4] = $remote_ip;
                $db_value = join(" ", @array_dns);
                $r->print("key:".$db_key."\n");
                $r->print("value:".$db_value."\n");
                if ($dns_data->db_put($db_key, $db_value) == 0) {
                    $r->print($res_OK."\n");
                    $r->print("IPv4 ".$orig_ip."=>".$remote_ip."\n");
                }
                else {
                    $r->print($res_Error."\n");
                    $r->print("IPv4 ".$remote_ip." ".$err_update_failed."\n");
                }
            }
            else {
                $r->print($res_OK."\n");
                $r->print("IPv4 ".$remote_ip." not changed\n");
            }
            last;
        }
        elsif (($remote_ip_ver == 6) && ($dns_type eq "AAAA")) {
            if (@array_dns[4] ne $remote_ip) {
                $orig_ip = @array_dns[4];
                @array_dns[4] = $remote_ip;
                $db_value = join(" ", @array_dns);
                $r->print("key:".$db_key."\n");
                $r->print("value:".$db_value."\n");
                if ($dns_data->db_put($db_key, $db_value) == 0) {
                    $r->print($res_OK."\n");
                    $r->print("IPv6 ".$orig_ip."=>".$remote_ip."\n");
                }
                else {
		    $r->print($res_Error."\n");
                    $r->print("IPv6 ".$remote_ip." ".$err_update_failed."\n");
                }
            }
            else {
		$r->print($res_OK."\n");
                $r->print("IPv6 ".$remote_ip." not changed\n");
            }
            last;
        }
    }
    $db_flags = DB_NEXT_DUP;
}

$db_cursor->c_close();
$dns_data->db_close();

1;
