#!/usr/bin/perl

use Apache2::RequestRec;
use Apache2::RequestUtil;
use File::Temp qw(tempfile);
use IO::Handle;

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
    $dns_name = $array_dns[0];
}

if ($array_size > 1) {
    $dns_zone = join(".", @array_dns[1..$array_size-1]);
}

if ($dns_zone eq "") {
    $r->print($res_Error."\n");
    $r->print("no zone\n");
    return 1;
}

my ($fh, $filename) = tempfile();

# write nsupdate commands
if ($remote_ip_ver == 4) {
    print $fh "server 127.0.0.1\n";
    print $fh "zone $dns_zone\n";
    print $fh "update delete $dns_name\.$dns_zone\. A\n";
    print $fh "update add $dns_name\.$dns_zone\. 60 A $remote_ip\n";
    print $fh "send\n";
    print $fh "quit\n";
}
elsif ($remote_ip_ver == 6) {
    print $fh "server 127.0.0.1\n";
    print $fh "zone $dns_zone\n";
    print $fh "update delete $dns_name\.$dns_zone\. AAAA\n";
    print $fh "update add $dns_name\.$dns_zone\. 60 AAAA $remote_ip\n";
    print $fh "send\n";
    print $fh "quit\n";
}
else {
    close $fh;
    $r->print($res_Error."\n");
    $r->print("unknown IP version\n");
    return 1;
}

# flush but don't close $fh before launching external command
$fh->flush;
system("nsupdate -v $filename");

close $fh;
# file is erased when $fh goes out of scope

$r->print($res_OK."\n");
$r->print("set ".$r->user." to $remote_ip\n");

1;
