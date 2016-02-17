package EzDNS::Authenticate;
use Apache2::Const qw(OK DECLINED AUTH_REQUIRED);
use EzDNS::Utils;
use strict;
sub handler {
    my $r = shift;
    # Let subrequests pass.
    return DECLINED unless $r->is_initial_req;
    # Get the client-supplied credentials.
    my ($status, $password) = $r->get_basic_auth_pw;
    return $status unless $status == OK;
    # Perform some custom user/password validation.
    return OK if authenticate_user($r->user, $password);
    # Whoops, bad credentials.
    $r->note_basic_auth_failure;
    return AUTH_REQUIRED;
}

sub authenticate_user {
    return OK;
}

1;

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
