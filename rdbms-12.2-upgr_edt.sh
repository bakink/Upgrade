---
---
RDBMS 12.2 UPGRADE

Semih Teke  - Feb 18
---
---

--
--Env--
ORACLE_UNQNAME=OPUSDATA
ORACLE_SID=OPUSDATA1

ORACLE_12BASE=/u01/app/oracle
ORACLE_11HOME=/u01/app/oracle/product/11.2.0.4/dbhome_1
ORACLE_12HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1

RCAT_USER=rcat
RCAT_PASS=rcat
RCAT_DB=RCAT

--Env\--
--

--
--PreRequisites--
Required Task to Preserve Downgrade Capability  :
  Patch 20898997: XMLTYPESUP: QCTOXSNLB SHOULD NOT CHECK AGAINST SNAPSHOT SIZE

JDBC Thin Driver Encoding Problem with CLOB field for TR Characters :
  Patch 26380097: GEORGIAN CHARACTERS DONOT DISPLAYED CORRECTLY FOR CLOB WITH MYCLOB.GETSUBSTRING
--PreRequisites\--
--

--
--PreCheck--
1.  @?/rdbms/admin/utlrp.sql
2.  CREATE TABLE STEKE.OBJECTS AS SELECT * FROM DBA_OBJECTS;
    CREATE TABLE STEKE.NWDEPN AS SELECT * FROM DBA_DEPENDENCIES WHERE REFERENCED_NAME IN ('UTL_TCP','UTL_SMTP','UTL_MAIL','UTL_HTTP','UTL_INADDR','DBMS_LDAP') AND OWNER NOT IN ('SYS','PUBLIC','ORDPLUGINS');
    CREATE TABLE STEKE.ACL_LIST AS SELECT * FROM DBA_NETWORK_ACLS;
    CREATE TABLE STEKE.ACL_PRIV AS SELECT * FROM DBA_NETWORK_ACL_PRIVILEGES;
3.  SELECT O.NAME FROM SYS.OBJ$ O, SYS.USER$ U, SYS.SUM$ S WHERE O.TYPE# = 42 AND BITAND(S.MFLAGS, 8) =8;
4.  SELECT NAME FROM SYS.V$PARAMETER WHERE ISDEFAULT!='TRUE' AND NAME LIKE '\_%' ESCAPE '\'; --Hidden Parameters
5.  SELECT * FROM V$BACKUP WHERE STATUS != 'NOT ACTIVE'; --Active Backups
6.  $ORACLE_12HOME/rdbms/admin/emremove.sql -- EM Repo Drop
7.  $ORACLE_11HOME/olap/admin/catnoamd.sql -- OLAP Drop
8.  exec DBMS_STATS.GATHER_DICTIONARY_STATS;
9.  exec DBMS_STATS.GATHER_FIXED_OBJECTS_STATS;
10. exec DBMS_STATS.PURGE_STATS(DBMS_STATS.PURGE_ALL);
11. truncate table AUD$;
12. purge DBA_RECYCLEBIN;

$ORACLE_12HOME/jdk/bin/java -jar $ORACLE_12HOME/rdbms/admin/preupgrade.jar

invalid_objects_exist     (1)
mv_refresh                (3)
underscore_events         (4)
em_present                (6)
amd_exists                (7)
dictionary_stats          (8)
default_resource_limit    Explicitly set RESOURCE_LIMIT to FALSE in the pfile/spfile to retain the previous behavior.
network_acl_priv          Backup the existing ACLs and their assignments for reference. Use the new DBMS_NETWORK_ACL_ADMIN interfaces and dictionary views to administer network privileges after upgrade.
                          DBA_NETWORK_ACLS,DBA_NETWORK_ACL_PRIVILEGES
exclusive_mode_auth       Perform one of the following:
                          1. Expire user accounts that use only the old 10G password version and follow the procedure recommended in Oracle Database Upgrade Guide under the section entitled, "Checking for Accounts Using Case-Insensitive Password Version".
                          2. Explicitly set SQLNET.ALLOWED_LOGON_VERSION_SERVER in the  SQLNET.ORA to a non-Exclusive Mode value, such as "11". (This is a short term approach and is not recommended because it will retain known security risks associated with the 10G password version.)
trgowner_no_admndbtrg     Directly grant ADMINISTER DATABASE TRIGGER privilege to the owner of the trigger. or drop and re-create the trigger with a user that was granted directly with such.
                          SELECT OWNER, TRIGGER_NAME FROM DBA_TRIGGERS WHERE BASE_OBJECT_TYPE='DATABASE' AND OWNER NOT IN (SELECT GRANTEE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='ADMINISTER DATABASE TRIGGER')
upg_by_std_upgrd          This Warning from Post Upgrade Fixup Script can be safely ignored due to reasons mentioned below: (Doc ID 2380677.1)
--PreCheck\--
--

--
--UpgradeSteps--
SQL> alter system set cluster_database=FALSE scope=spfile;
]$ srvctl stop db -d $ORACLE_UNQNAME -o immediate
SQL> startup mount;
SQL> alter database archivelog;
SQL> alter database open;
SQL> create restore point BEFORE_UPGRADE guarantee flashback database;
SQL> create pfile=$ORACLE_12HOME/dbs/init$ORACLE_SID.ora from spfile;
SQL> shutdown immediate;

export ORACLE_HOME=$ORACLE_12HOME
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_BASE=$ORACLE_12BASE

SQL> startup upgrade;

cd $ORACLE_12HOME/bin
./dbupgrade

SQL> startup
SQL> @$ORACLE_12HOME/rdbms/admin/utlu122s.sql
Verify the upgrade log whether catuppst.sql has been executed or not.  If not, execute it manually from new ORACLE_HOME, located at $ORACLE_HOME/rdbms/admin directory
SQL> @$ORACLE_12HOME/rdbms/admin/catuppst.sql
SQL> @$ORACLE_12HOME/rdbms/admin/utlrp.sql

$ORACLE_12HOME/bin/srvctl upgrade database -db $ORACLE_UNQNAME -o $ORACLE_12HOME
Modify the corresponding entry in the /etc/oratab file to point to the new ORACLE_HOME location.
--UpgradeSteps\--
--

--
--PostUpgrade--
Upgrading Tables Dependent on Oracle-Maintained Types :
COLUMN owner FORMAT A30
COLUMN table_name FORMAT A30
SELECT DISTINCT OWNER, TABLE_NAME FROM DBA_TAB_COLS WHERE DATA_UPGRADED = 'NO' ORDER BY 1, 2;
SET SERVEROUTPUT ON
@utluptabdata.sql

-
-DST-
Upgrade the Time Zone File Version After Upgrading Oracle Database  :
SELECT * FROM V$TIMEZONE_FILE; -->28

RDBMS:
Updating the RDBMS DST version in 12c Release 1 (12.1.0.1 and up) using DBMS_DST (Doc ID 1509653.1) :
@countstatsTSTZ.sql
exec DBMS_SCHEDULER.PURGE_LOG;
@upg_tzv_check.sql
@upg_tzv_apply.sql

OJVM:
24701882  :
>connect as SYS and run script @?/javavm/admin/fixTZa
>Shutdown and restart the database using startup migrate.
>connect as SYS and run script @?/javavm/admin/fixTZb
>restart the database without startup migrate.
-DST\-
-

RMAN> connect catalog $RCAT_USER/$RCAT_PASS@$RCAT_DB
RMAN> upgrade catalog;
RMAN> upgrade catalog;

/u01/app/oracle/cfgtoollogs/$ORACLE_11HOME/preupgrade/postupgrade_fixups.sql

?alter system set compatible='12.2.0' scope=spfile;
--PostUpgrade\--
--

--
--UpgradeErrors--
-
-ORA-01403: no data found ORA-06512: at line 11  :
SCRIPT    = [/u01/app/oracle/product/12.2.0.1/dbhome_1/rdbms/admin/xdbuo112.sql]
ERROR     = [ORA-01403: no data found ORA-06512: at line 11

:

create user anonymous identified by anonymous default tablespace users;

-- Add XS$NULL to XDB schema list

BEGIN
dbms_registry.loading('XDB', 'Oracle XML Database',
  'dbms_regxdb.validateXDB', 'XDB',
  dbms_registry.schema_list_t('ANONYMOUS'));
END;
/

grant create session to anonymous;
alter user anonymous account lock;

-- Add XS$NULL to XDB schema list

BEGIN
 dbms_registry.update_schema_list('XDB',
 dbms_registry.schema_list_t('ANONYMOUS', 'XS$NULL'));
END;
/

@?/rdbms/admin/utlrp.sql
-/-
-

-
-ORA-00600: [krcpasb_bufsz_exceeds_maxsz]  :
DBUA failed with ORA-00600: [krcpasb_bufsz_exceeds_maxsz] when upgrading from 11gR2 to 12c (Doc ID 2376351.1)
The hidden parameter _bct_public_dba_buffer_maxsize, along with this check, is newly added for release 12.1+.

SQL> alter database DISABLE block change tracking;
SQL> alter system set "_bct_public_dba_buffer_maxsize" = _bct_public_dba_buffer_size;
SQL> alter database ENABLE block change tracking;
-/-
-

-
-DST Patch Apply Problem:
CONN / as sysdba
alter session set "_with_subquery"=materialize;
alter session set "_simple_view_merging"=TRUE;
set serveroutput on
VAR numfail number
BEGIN
DBMS_DST.UPGRADE_DATABASE(:numfail,
parallel => TRUE,
log_errors => TRUE,
log_errors_table => 'SYS.DST$ERROR_TABLE',
log_triggers_table => 'SYS.DST$TRIGGER_TABLE',
error_on_overlap_time => FALSE,
error_on_nonexisting_time => FALSE);
DBMS_OUTPUT.PUT_LINE('Failures:'|| :numfail);
END;
/
VAR fail number
BEGIN
DBMS_DST.END_UPGRADE(:fail);
DBMS_OUTPUT.PUT_LINE('Failures:'|| :fail);
END;
/

SELECT PROPERTY_NAME, SUBSTR(property_value, 1, 30) value
FROM DATABASE_PROPERTIES
WHERE PROPERTY_NAME LIKE 'DST_%'
ORDER BY PROPERTY_NAME;
-/-
-

-
-ORA-00600: [ipc_create_que_1] in Exafusion enabled environment like database version 12.2 (Doc ID 2282831.1) :
/etc/security/limits.conf :
oracle    soft     memlock 475348860
oracle    hard     memlock 475348860
-/-
-

-
-ORA-07445 [expCheckExprEquiv()+317] :
/*+ optimizer_features_enable('12.1.0.2') */
-/-
-

-
-ORA-00600: internal error code, arguments: [ipc_recreate_que_2], [1], [0], [], [], [], [], [], [], [], [], [] (Bug ID 27971659)
Workaround : Disable Exafusion
-/-
-

-
-ORA-06544: PL/SQL: internal error, arguments: [1907]
Remote type declarations causes the problem, declaring locally fixing the problem. e.g. :
"M_TO customer.KOC_SMTP_WA_UTIL.'ADDRESSES'@opusdata" ->    "TYPE addresses IS TABLE OF VARCHAR2 (100)   INDEX BY BINARY_INTEGER";
-/-
-

--UpgradeErrors\--
--
