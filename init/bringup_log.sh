#!/vendor/bin/sh
# BRING-UP ONLY (findings.md D15t/D15u): USB-independent boot logging into the `logks` partition.
# v2: streams /dev/kmsg from the start (the ring buffer rolls over under the SELinux audit flood),
# uses absolute /system/bin/logcat, and copies tombstones/ANRs once /data is up.
# v3: write under /metadata (mounted by first-stage init, never touched by fs_mgr's late fsck — the
# logks partition is mounted+fscked by fstab.qcom and lost the v2 captures). Keep the newest 4 boots.
M=/metadata/bringup
i=0; while [ ! -d /metadata/bootstat ] && [ ! -d /metadata/vold ] && [ $i -lt 30 ]; do sleep 1; i=$((i+1)); done
mkdir -p $M
rm -rf $M/bringup-* 2>/dev/null   # v4: /metadata is 62 MB; keep only this boot
D=$M/bringup-$(cut -c1-8 /proc/sys/kernel/random/boot_id 2>/dev/null || echo x)
mkdir -p $D
echo "started $(cat /proc/uptime)" > $D/started
# v5: snapshot pstore (previous boot's panic/console records, if the bootloader preserved the ramoops region)
mkdir -p $D/pstore; cp -f /sys/fs/pstore/* $D/pstore/ 2>/dev/null; ls -la /sys/fs/pstore > $D/pstore/ls.txt 2>&1
cat /proc/sys/kernel/hung_task_timeout_secs /proc/sys/kernel/hung_task_panic /proc/sys/kernel/panic /proc/sys/kernel/panic_on_oops > $D/panic_knobs.txt 2>&1
( cat /dev/kmsg > $D/kmsg.txt 2>$D/kmsg.err ) &
while true; do
    /system/bin/logcat -d -b crash -v threadtime > $D/logcat-crash.txt 2>$D/logcat.err
    getprop > $D/getprop.txt 2>&1
    cat /proc/uptime > $D/uptime
    ps -A > $D/ps.txt 2>&1
    mount > $D/mounts.txt 2>&1
    sync
    sleep 3
done
