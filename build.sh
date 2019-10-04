#!/bin/bash

# for tethered downgrade

# iPhone5,2 iOS 7.1.2 [11D257] ivkey
ibss_iv="d279e5c309be7ac035fd313958a178be"
ibss_key="617f7e2d5d8e2940a325758cd42055b83e2e3d243f068d5a9015b0fe67bed815"
ibec_iv="1d45b6ca42dafd5d711e3d23e5fa0fc7"
ibec_key="459912ddeeeb9d4a1c66068c8c1d8f46d8dd72e3e7dfa3ff0326f1ab6bb59c28"
rdsk_iv="13b6456bec67fa74faada14e1c3607aa"
rdsk_key="4e0bcc542aefc750cd463f6d0ed4710f15fb0ec0d2a11d4e213b6f58c1e20e87"
# file path
ipsw_build="iPhone5,2_7.1.2_11D257"
ipsw_name=""$ipsw_build"_Restore.ipsw"
ipsw_output=""$ipsw_build"_Custom.ipsw"
restore="058-4357-009.dmg"

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
