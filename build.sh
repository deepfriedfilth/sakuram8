#!/bin/bash

# for tethered downgrade

# iPhone5,2 iOS 6.1.4 [10B350] ivkey
ibss_iv="b213c5e7ea60235bf85cc555d3ca9b9c"
ibss_key="a7863aee09a20bbfd2829afd2d2967271e4b28db73a8da68e7ed396cd37624a4"
ibec_iv="3bc6c9a06b39dd9c84a571a4eddf2594"
ibec_key="92291a2c5623b0b3656fec02375e73cb607b28ab508fc18417b7b66e73fff137"
rdsk_iv="10e7926c1cce7bbdfb0ec956ef4c1768"
rdsk_key="a31d81fdcdb6645edea8b5152702bdf92b5df273a1b377e62c9b3273f43d8cb9"
# file path
ipsw_build="iPhone5,2_6.1.4_10B350"
ipsw_name=""$ipsw_build"_Restore.ipsw"
ipsw_output=""$ipsw_build"_Custom.ipsw"
restore="048-2930-001.dmg"

# unzip ipsw
mkdir tmp
mkdir tmp/fw
unzip $ipsw_name -d tmp/fw

# decrypt firmware
xpwntool tmp/fw/Firmware/dfu/iBSS.n42ap.RELEASE.dfu tmp/ibss.dec -iv $ibss_iv -k $ibss_key #ibss
xpwntool tmp/fw/Firmware/dfu/iBEC.n42ap.RELEASE.dfu tmp/ibec.dec -iv $ibec_iv -k $ibec_iv #ibec
xpwntool tmp/fw/$restore tmp/ramdisk.dmg -iv $rdsk_iv -k $rdsk_key #restore ramdisk

# patching firmware
bspatch tmp/ibss.dec tmp/pwnedibss.dec FirmwareBundles/"$ipsw_build".bundle/iBSS.n42ap.RELEASE.patch
bspatch tmp/ibec.dec tmp/pwnedibec.dec FirmwareBundles/"$ipsw_build".bundle/iBEC.n42ap.RELEASE.patch

# patching asr and inject flashnor=false
hfsplus tmp/ramdisk.dmg extract usr/local/share/restore/options.n42.plist tmp/options.n42.plist
/usr/libexec/PlistBuddy -c "add FlashNOR bool false" tmp/options.n42.plist
hfsplus tmp/ramdisk.dmg add tmp/options.n42.plist usr/local/share/restore/options.n42.plist

hfsplus tmp/ramdisk.dmg extract usr/sbin/asr tmp/asr
bspatch tmp/asr tmp/asr_patched FirmwareBundles/"$ipsw_build".bundle/asr.patch
hfsplus tmp/ramdisk.dmg add tmp/asr_patched usr/sbin/asr
hfsplus tmp/ramdisk.dmg chmod 755 usr/sbin/asr

# packing firmware
xpwntool tmp/pwnedibss.dec tmp/pwnedibss.img3 -t tmp/fw/Firmware/dfu/iBSS.n42ap.RELEASE.dfu -iv $ibss_iv -k $ibss_key #ibss
xpwntool tmp/pwnedibec.dec tmp/pwnedibec.img3 -t tmp/fw/Firmware/dfu/iBEC.n42ap.RELEASE.dfu -iv $ibec_iv -k $ibec_iv #ibec
xpwntool tmp/ramdisk.dmg tmp/$restore -t tmp/fw/$restore -iv $rdsk_iv -k $rdsk_key #restore ramdisk

rm tmp/fw/Firmware/dfu/iBSS.n42ap.RELEASE.dfu
rm tmp/fw/Firmware/dfu/iBEC.n42ap.RELEASE.dfu
rm tmp/fw/$restore
cp tmp/pwnedibss.img3 tmp/fw/Firmware/dfu/iBSS.n42ap.RELEASE.dfu
cp tmp/pwnedibec.img3 tmp/fw/Firmware/dfu/iBEC.n42ap.RELEASE.dfu
cp tmp/$restore tmp/fw/$restore

cd tmp/fw
zip ../../$ipsw_output -r0 *

cd ../..

rm -r tmp
