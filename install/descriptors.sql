insert into temp_images set creator='elabman',default_osid='emulab-ops-FBSD410-STD',part4_osid=NULL,loadpart='0',shared='0',load_address='',imagename='FBSD410+RHL90-STD',pid='emulab-ops',ezid='0',updated=NULL,loadlength='4',imageid='emulab-ops-FBSD410+RHL90-STD',magic=NULL,global='1',part1_osid='emulab-ops-FBSD410-STD',path='/usr/testbed/images/FBSD410+RHL90-STD.ndz',frisbee_pid='0',description='FreeBSD 4.10 and RedHat 9.0',load_busy='0',part3_osid=NULL,created='2007-03-07 13:15:07',gid='emulab-ops',part2_osid='emulab-ops-RHL90-STD';
insert into temp_images set creator='elabman',default_osid='emulab-ops-FBSD410-STD',part4_osid=NULL,loadpart='1',shared='0',load_address='',imagename='FBSD410-STD',pid='emulab-ops',ezid='1',updated=NULL,loadlength='1',imageid='emulab-ops-FBSD410-STD',magic=NULL,global='1',part1_osid='emulab-ops-FBSD410-STD',path='/usr/testbed/images/FBSD410-STD.ndz',frisbee_pid='0',description='Testbed version of FreeBSD 4.10',load_busy='0',part3_osid=NULL,created='2007-03-07 13:15:07',gid='emulab-ops',part2_osid=NULL;
insert into temp_images set creator='elabman',default_osid='emulab-ops-RHL90-STD',part4_osid=NULL,loadpart='2',shared='0',load_address='',imagename='RHL90-STD',pid='emulab-ops',ezid='0',updated=NULL,loadlength='1',imageid='emulab-ops-RHL90-STD',magic=NULL,global='1',part1_osid=NULL,path='/usr/testbed/images/RHL90-STD.ndz',frisbee_pid='0',description='Redhat 9.0 slice disk image',load_busy='0',part3_osid=NULL,created='2007-03-07 13:15:07',gid='emulab-ops',part2_osid='emulab-ops-RHL90-STD';
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='emulab-ops-FBSD-JAIL',reboot_waittime='90',mustclean='0',shared='1',pid='emulab-ops',ezid='0',osname='FBSD-JAIL',OS='FreeBSD',magic='',version='4.X',machinetype='',path=NULL,osfeatures='ping,ssh,isup,linktest',description='Generic OSID for jailed nodes',created='2007-03-07 13:15:07',op_mode='PCVM',nextosid='FBSD-STD';
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='emulab-ops-FBSD410-STD',reboot_waittime='150',mustclean='1',shared='1',pid='emulab-ops',ezid='1',osname='FBSD410-STD',OS='FreeBSD',magic=NULL,version='4.10',machinetype='',path=NULL,osfeatures='ping,ssh,ipod,isup,veths,mlinks,linktest,linkdelays',description='Testbed version of FreeBSD 4.10',created='2007-03-07 13:15:07',op_mode='NORMALv2',nextosid=NULL;
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='emulab-ops-RHL90-STD',reboot_waittime='150',mustclean='1',shared='1',pid='emulab-ops',ezid='0',osname='RHL90-STD',OS='Linux',magic='',version='9.0',machinetype='',path=NULL,osfeatures='ping,ssh,ipod,isup,linktest,linkdelays',description='Testbed version of RedHat Linux 9.0',created='2007-03-07 13:15:07',op_mode='NORMALv2',nextosid=NULL;
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='FBSD-STD',reboot_waittime='150',mustclean='1',shared='1',pid='emulab-ops',ezid='0',osname='FBSD-STD',OS='FreeBSD',magic='FreeBSD',version='',machinetype='pc600',path=NULL,osfeatures='ping,ssh,ipod,isup,veths,mlinks,linktest,linkdelays',description='Any Version of FreeBSD',created='2007-03-07 13:15:07',op_mode='NORMAL',nextosid='emulab-ops-FBSD410-STD';
insert into temp_os_info set mfs='1',creator='elabman',max_concurrent=NULL,osid='FREEBSD-MFS',reboot_waittime='150',mustclean='0',shared='1',pid='emulab-ops',ezid='0',osname='FREEBSD-MFS',OS='FreeBSD',magic=NULL,version='4.5',machinetype='',path='/tftpboot/freebsd',osfeatures='ping,ssh,ipod,isup',description='FreeBSD in an MFS',created='2007-03-07 13:15:07',op_mode='PXEFBSD',nextosid=NULL;
insert into temp_os_info set mfs='1',creator='elabman',max_concurrent=NULL,osid='FRISBEE-MFS',reboot_waittime='150',mustclean='0',shared='1',pid='emulab-ops',ezid='0',osname='FRISBEE-MFS',OS='FreeBSD',magic=NULL,version='4.5',machinetype='',path='/tftpboot/frisbee',osfeatures='ping,ssh,ipod,isup',description='Frisbee (FreeBSD) in an MFS',created='2007-03-07 13:15:07',op_mode='RELOAD',nextosid=NULL;
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='FW-IPFW',reboot_waittime='150',mustclean='1',shared='1',pid='emulab-ops',ezid='0',osname='FW-IPFW',OS='FreeBSD',magic='FreeBSD',version='',machinetype='',path=NULL,osfeatures='ping,ssh,ipod,isup,veths,mlinks',description='IPFW Firewall',created='2007-03-07 13:15:07',op_mode='NORMAL',nextosid='emulab-ops-FBSD410-STD';
insert into temp_os_info set mfs='1',creator='elabman',max_concurrent=NULL,osid='NEWNODE-MFS',reboot_waittime='150',mustclean='0',shared='1',pid='emulab-ops',ezid='0',osname='NEWNODE-MFS',OS='FreeBSD',magic=NULL,version='4.5',machinetype='',path='/tftpboot/freebsd.newnode',osfeatures='ping,ssh,ipod,isup',description='NewNode (FreeBSD) in an MFS',created='2007-03-07 13:15:07',op_mode='PXEFBSD',nextosid=NULL;
insert into temp_os_info set mfs='1',creator='elabman',max_concurrent=NULL,osid='OPSNODE-BSD',reboot_waittime='150',mustclean='0',shared='1',pid='emulab-ops',ezid='0',osname='OPSNODE-BSD',OS='FreeBSD',magic=NULL,version='4.X',machinetype='',path='',osfeatures='ping,ssh,ipod,isup',description='FreeBSD on the Operations Node',created='2007-03-07 13:15:07',op_mode='OPSNODEBSD',nextosid=NULL;
insert into temp_os_info set mfs='0',creator='elabman',max_concurrent=NULL,osid='RHL-STD',reboot_waittime='150',mustclean='1',shared='1',pid='emulab-ops',ezid='0',osname='RHL-STD',OS='Linux',magic='Linux',version='',machinetype='pc600',path=NULL,osfeatures='ping,ssh,ipod,isup,linktest,linkdelays',description='Any of RedHat Linux',created='2007-03-07 13:15:07',op_mode='NORMAL',nextosid='emulab-ops-RHL90-STD';
