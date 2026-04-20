#!/usr/bin/perl -w

# Example hook script for vzdump (--script option)
# This can also be added as a line in /etc/vzdump.conf
# e.g. 'script: /usr/local/bin/vzdump-hook-script.pl'

use strict;

print "HOOK: " . join(' ', @ARGV) . "\n";

my $phase = shift;

if (
    $phase eq 'job-init'
    || $phase eq 'job-start'
    || $phase eq 'job-end'
    || $phase eq 'job-abort'
) {

    # 不处理
    1;

}
elsif (
    $phase eq 'backup-start'
    || $phase eq 'backup-end'
    || $phase eq 'backup-abort'
    || $phase eq 'log-end'
    || $phase eq 'pre-stop'
    || $phase eq 'pre-restart'
    || $phase eq 'post-restart'
) {

    my $mode = shift;
    my $vmid = shift;

    my $vmtype = $ENV{VMTYPE};

    print "HOOK-ENV: vmtype=$vmtype; vmid=$vmid;\n";

    # =========================
    # 仅处理 LXC 106
    # =========================
    if (defined($vmid) && $vmid == 106) {

        # -------------------------
        # 备份开始前
        # -------------------------
        if ($phase eq 'backup-start') {

            print "backup-start: stopping clouddrive2...\n";

            system("/usr/sbin/pct exec 106 -- docker stop clouddrive2") == 0
                or die "FAILED to stop clouddrive2 -> ABORTING BACKUP";

            system("/usr/sbin/pct exec 106 -- rm -f /dev/fuse") == 0
                or die "FAILED to remove /dev/fuse -> ABORTING BACKUP";

        }

        # -------------------------
        # 备份结束后
        # -------------------------
        if ($phase eq 'backup-end') {

            print "backup-end: restoring fuse and starting clouddrive2...\n";

            system("/usr/sbin/pct exec 106 -- mknod -m 666 /dev/fuse c 10 229") == 0
                or warn "Failed to mknod /dev/fuse";

            system("/usr/sbin/pct exec 106 -- docker start clouddrive2") == 0
                or warn "Failed to start clouddrive2";

        }

    }

}
else {
    die "got unknown phase '$phase'";
}

exit(0);
