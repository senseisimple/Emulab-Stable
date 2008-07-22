insert into temp_images set creator='elabman',default_osid='282',part4_osid=NULL,loadpart='1',shared='0',load_address='',imagename='FBSD410-IPFW2',pid='emulab-ops',ezid='0',updated=NULL,loadlength='1',imageid='869',magic=NULL,global='1',part1_osid='282',path='/usr/testbed/images/FBSD410-IPFW2.ndz',mbr_version='1',frisbee_pid='0',description='FreeBSD 4.10 with built-in IPFW2 support',load_busy='0',part3_osid=NULL,created='2008-07-22 17:34:07',access_key=NULL,old_imageid='emulab-ops-FBSD410-IPFW2',gid='emulab-ops',part2_osid=NULL;
insert into temp_images set creator='elabman',default_osid='285',part4_osid=NULL,loadpart='1',shared='0',load_address='',imagename='FBSD410-STD',pid='emulab-ops',ezid='1',updated=NULL,loadlength='1',imageid='285',magic=NULL,global='1',part1_osid='285',path='/usr/testbed/images/FBSD410-STD.ndz',mbr_version='1',frisbee_pid='0',description='Testbed version of FreeBSD 4.10',load_busy='0',part3_osid=NULL,created='2008-07-22 17:34:07',access_key=NULL,old_imageid='emulab-ops-FBSD410-STD',gid='emulab-ops',part2_osid=NULL;
insert into temp_images set creator='elabman',default_osid='940',part4_osid=NULL,loadpart='0',shared='0',load_address='',imagename='FBSD62+FC6-STD',pid='emulab-ops',ezid='0',updated=NULL,loadlength='4',imageid='947',magic=NULL,global='1',part1_osid='303',path='/usr/testbed/images/FBSD62+FC6-STD.ndz',mbr_version='1',frisbee_pid='0',description='FreeBSD 6.2 and Fedora Core 6 combo image',load_busy='0',part3_osid=NULL,created='2008-07-22 17:34:07',access_key='0f58499aa4e7280e7f95bf281b147a7c',old_imageid='',gid='emulab-ops',part2_osid='940';
insert into temp_images set creator='elabman',default_osid='303',part4_osid=NULL,loadpart='1',shared='0',load_address='',imagename='FBSD62-STD',pid='emulab-ops',ezid='1',updated=NULL,loadlength='1',imageid='303',magic=NULL,global='1',part1_osid='303',path='/usr/testbed/images/FBSD62-STD.ndz',mbr_version='1',frisbee_pid='0',description='FreeBSD 6.2 pre-release',load_busy='0',part3_osid=NULL,created='2008-07-22 17:34:07',access_key=NULL,old_imageid='emulab-ops-FBSD62-STD',gid='emulab-ops',part2_osid=NULL;
insert into temp_images set creator='elabman',default_osid='940',part4_osid=NULL,loadpart='2',shared='0',load_address='',imagename='FC6-STD',pid='emulab-ops',ezid='1',updated=NULL,loadlength='1',imageid='940',magic=NULL,global='1',part1_osid=NULL,path='/usr/testbed/images/FC6-STD.ndz',mbr_version='1',frisbee_pid='0',description='Emulab Standard Fedora Core 6 image.',load_busy='0',part3_osid=NULL,created='2008-07-22 17:34:07',access_key=NULL,old_imageid='',gid='emulab-ops',part2_osid='940';
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='278',reboot_waittime='90',mustclean='0',shared='1',pid='emulab-ops',ezid='0',osname='FBSD-JAIL',old_osid='emulab-ops-FBSD-JAIL',OS='FreeBSD',magic='',old_nextosid='FBSD-STD',version='4.X',machinetype='',path=NULL,osfeatures='ping,ssh,isup,linktest',description='Generic OSID for jailed nodes',op_mode='PCVM',created='2008-07-22 17:34:08',nextosid='362';
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='362',reboot_waittime='150',mustclean='1',shared='1',pid='emulab-ops',ezid='0',osname='FBSD-STD',old_osid='FBSD-STD',OS='FreeBSD',magic='FreeBSD',old_nextosid='MAP:osid_map',version='',machinetype='pc600',path=NULL,osfeatures='ping,ssh,ipod,isup,veths,mlinks,linktest,linkdelays',description='Any Version of FreeBSD',op_mode='NORMAL',created='2008-07-22 17:34:08',nextosid='303';
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='282',reboot_waittime='150',mustclean='1',shared='1',pid='emulab-ops',ezid='1',osname='FBSD410-IPFW2',old_osid='emulab-ops-FBSD410-IPFW2',OS='FreeBSD',magic=NULL,old_nextosid='',version='4.10',machinetype='',path=NULL,osfeatures='ping,ssh,ipod,isup,veths,mlinks,linktest',description='FreeBSD 4.10 with IPFW2',op_mode='NORMALv2',created='2008-07-22 17:34:08',nextosid=NULL;
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='285',reboot_waittime='150',mustclean='1',shared='1',pid='emulab-ops',ezid='1',osname='FBSD410-STD',old_osid='emulab-ops-FBSD410-STD',OS='FreeBSD',magic=NULL,old_nextosid='',version='4.10',machinetype='',path=NULL,osfeatures='ping,ssh,ipod,isup,veths,mlinks,linktest,linkdelays',description='Testbed version of FreeBSD 4.10',op_mode='NORMALv2',created='2008-07-22 17:34:08',nextosid=NULL;
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='303',reboot_waittime='120',mustclean='1',shared='1',pid='emulab-ops',ezid='1',osname='FBSD62-STD',old_osid='emulab-ops-FBSD62-STD',OS='FreeBSD',magic=NULL,old_nextosid='',version='6.2',machinetype='',path=NULL,osfeatures='ping,ssh,ipod,isup,mlinks,linktest,linkdelays',description='FreeBSD 6.2 pre-release',op_mode='NORMALv2',created='2008-07-22 17:34:08',nextosid=NULL;
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='940',reboot_waittime='120',mustclean='1',shared='1',pid='emulab-ops',ezid='1',osname='FC6-STD',old_osid='',OS='Fedora',magic=NULL,old_nextosid='',version='6',machinetype='',path=NULL,osfeatures='ping,ssh,ipod,isup,linktest',description='Emulab Standard Fedora Core 6 image.',op_mode='NORMALv2',created='2008-07-22 17:34:08',nextosid=NULL;
insert into temp_os_info set mfs='1',creator='elabman',max_concurrent=NULL,osid='399',reboot_waittime='150',mustclean='0',shared='1',pid='emulab-ops',ezid='0',osname='FREEBSD-MFS',old_osid='FREEBSD-MFS',OS='FreeBSD',magic=NULL,old_nextosid='',version='6.2',machinetype='',path='/tftpboot/freebsd',osfeatures='ping,ssh,ipod,isup',description='FreeBSD in an MFS',op_mode='PXEFBSD',created='2008-07-22 17:34:08',nextosid=NULL;
insert into temp_os_info set mfs='1',creator='elabman',max_concurrent=NULL,osid='403',reboot_waittime='150',mustclean='0',shared='1',pid='emulab-ops',ezid='0',osname='FRISBEE-MFS',old_osid='FRISBEE-MFS',OS='FreeBSD',magic=NULL,old_nextosid='',version='6.2',machinetype='',path='/tftpboot/frisbee',osfeatures='ping,ssh,ipod,isup',description='Frisbee (FreeBSD) in an MFS',op_mode='RELOAD',created='2008-07-22 17:34:08',nextosid=NULL;
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='406',reboot_waittime='150',mustclean='1',shared='1',pid='emulab-ops',ezid='0',osname='FW-IPFW',old_osid='FW-IPFW',OS='FreeBSD',magic='FreeBSD',old_nextosid='emulab-ops-FBSD410-STD',version='',machinetype='',path=NULL,osfeatures='ping,ssh,ipod,isup,veths,mlinks',description='IPFW Firewall',op_mode='NORMAL',created='2008-07-22 17:34:08',nextosid='285';
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='407',reboot_waittime='150',mustclean='1',shared='1',pid='emulab-ops',ezid='0',osname='FW-IPFW2',old_osid='FW-IPFW2',OS='FreeBSD',magic='FreeBSD',old_nextosid='emulab-ops-FBSD410-IPFW2',version='',machinetype='',path=NULL,osfeatures='ping,ssh,ipod,isup,veths,mlinks',description='IPFW2 Firewall',op_mode='NORMAL',created='2008-07-22 17:34:08',nextosid='282';
insert into temp_os_info set mfs='1',creator='elabman',max_concurrent=NULL,osid='467',reboot_waittime='150',mustclean='0',shared='1',pid='emulab-ops',ezid='0',osname='NEWNODE-MFS',old_osid='NEWNODE-MFS',OS='FreeBSD',magic=NULL,old_nextosid='',version='6.2',machinetype='',path='/tftpboot/freebsd.newnode',osfeatures='ping,ssh,ipod,isup',description='NewNode (FreeBSD) in an MFS',op_mode='PXEFBSD',created='2008-07-22 17:34:08',nextosid=NULL;
insert into temp_os_info set mfs='1',creator='elabman',max_concurrent=NULL,osid='470',reboot_waittime='150',mustclean='0',shared='1',pid='emulab-ops',ezid='0',osname='OPSNODE-BSD',old_osid='OPSNODE-BSD',OS='FreeBSD',magic=NULL,old_nextosid='',version='4.X',machinetype='',path='',osfeatures='ping,ssh,ipod,isup',description='FreeBSD on the Operations Node',op_mode='OPSNODEBSD',created='2008-07-22 17:34:08',nextosid=NULL;
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='324',reboot_waittime='60',mustclean='1',shared='0',pid='emulab-ops',ezid='0',osname='POWER-CONTROLLER',old_osid='emulab-ops-POWER-CONTROLLER',OS='Other',magic='',old_nextosid='',version='0.00',machinetype='',path=NULL,osfeatures='',description='Stub descriptor for power controllers of any kind',op_mode='ALWAYSUP',created='2008-07-22 17:34:08',nextosid=NULL;
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='526',reboot_waittime='150',mustclean='1',shared='1',pid='emulab-ops',ezid='0',osname='RHL-STD',old_osid='RHL-STD',OS='Linux',magic='Linux',old_nextosid='MAP:osid_map',version='',machinetype='pc600',path=NULL,osfeatures='ping,ssh,ipod,isup,linktest,linkdelays',description='Any of RedHat Linux',op_mode='NORMAL',created='2008-07-22 17:34:08',nextosid='940';
