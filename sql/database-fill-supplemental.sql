-- 
-- database-create-supplemental.sql - Various things that need to go into new
-- sites' databases, but don't really fit into database-fill.sql, which is
-- auto-generated. Also, unlike the contents of database-fill.sql, inserting
-- these is not idempotent, since a site may have changed them for some reason.
--

INSERT INTO os_info VALUES ('FREEBSD-MFS','emulab-ops','FREEBSD-MFS','root',NULL,'FreeBSD in an MFS','FreeBSD','4.5','boss:/tftpboot/freebsd',NULL,'','ping,ssh,ipod,isup',0,1,0,'PXEFBSD',NULL,NULL,1);
INSERT INTO os_info VALUES ('FRISBEE-MFS','emulab-ops','FRISBEE-MFS','root',NULL,'Frisbee (FreeBSD) in an MFS','FreeBSD','4.5','boss:/tftpboot/frisbee',NULL,'','ping,ssh,ipod,isup',0,1,0,'RELOAD',NULL,NULL,1);
INSERT INTO os_info VALUES ('NEWNODE-MFS','emulab-ops','NEWNODE-MFS','root',NULL,'NewNode (FreeBSD) in an MFS','FreeBSD','4.5','boss:/tftpboot/freebsd.newnode',NULL,'','ping,ssh,ipod,isup',0,1,0,'PXEFBSD',NULL,NULL,1);
