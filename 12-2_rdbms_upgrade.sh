---
1. @?/rdbms/admin/utlrp.sql

2. create table steke.objects as select * from dba_objects;

3. /u01/app/oracle/product/12.2.0.1/dbhome_1/jdk/bin/java -jar /u01/app/oracle/product/12.2.0.1/dbhome_1/rdbms/admin/preupgrade.jar

4. SELECT o.name FROM sys.obj$ o, sys.user$ u, sys.sum$ s WHERE o.type# = 42 AND bitand(s.mflags, 8) =8; --Materialized View

5. SELECT name from SYS.V$PARAMETER WHERE isdefault!='TRUE' and name LIKE '\_%' ESCAPE '\';

6. /u01/app/oracle/product/12.2.0.1/dbhome_1/rdbms/admin/emremove.sql
    ACN :  drop trigger DBAUSER.DDL_TRIGGER;
    IRISDB :  drop trigger KSDBA.KSDBA_DDLTRIGGER; (+ anonymous user)

7. set env -> 12c, startup upgrade pfile=, $ORACLE_HOME/bin/dbupgrade.sh

8. startup,  @?/rdbms/admin/utlu122s.sql

9. @?/rdbms/admin/utlrp.sql

10.$ORACLE_HOME/bin/srvctl upgrade database -db $ORACLE_UNQNAME -o $ORACLE_HOME

11./u01/app/oracle/cfgtoollogs/$ORACLE_HOME/preupgrade/postupgrade_fixups.sql

12.alter system set compatible='12.2.0' scope=spfile;
---


*1 : Complete Checklist for Manual Upgrades to Non-CDB Oracle Database 12c Release 2 (12.2) (Doc ID 2173141.1)

************* Preupgrade *****************

- Script to Collect DB Upgrade/Migrate Diagnostic Information (dbupgdiag.sql) (Doc ID 556610.1)

- Clean up database
PURGE DBA_RECYCLEBIN;

                        Empty the recycle bin
                        Check for INVALID objects in SYS and SYSTEM
                        Check for duplicate objects in SYS and SYSTEM
                        Check for INVALID, mandatory, obsolete components

- Check materialized views


SQL> SELECT o.name FROM sys.obj$ o, sys.user$ u, sys.sum$ s WHERE o.type# = 42 AND bitand(s.mflags, 8) =8;

- Dictionary stats ,fixed object stats
                EXECUTE dbms_stats.gather_dictionary_stats;
                execute DBMS_STATS.GATHER_FIXED_OBJECTS_STATS;

- check hidden parameter
- audit

            truncate table aud$;

- Purge old stats

    exec DBMS_STATS.PURGE_STATS(DBMS_STATS.PURGE_ALL) --> Sisteme etkisi olmuyor. Uygun zamanda bütün eski statslari silebilirsiniz.

- check backup mode

SELECT * FROM v$backup WHERE status != 'NOT ACTIVE';

- Manually remove DB control with emremove.sql
Stop/shutdown DB control
emctl stop dbconsole


Login as sysdba
SQL>SET ECHO ON
SQL>SET SERVEROUTPUT ON
SQL>@emremove.sql >> Script located in new 12c ORACLE_HOME/rdbms/admin

- Checking Time zone settings,

            Default time zone for Oracle database 12.2 is V26
            Time zone should less than or equal to target database time zone version. If source is having higher time zone, then apply time zone patch on target ORACLE_HOME to match the source.

   *

- Dependencies on Network Utility Packages

SQL> create table steke.acl as SELECT * FROM DBA_DEPENDENCIES WHERE referenced_name IN ('UTL_TCP','UTL_SMTP','UTL_MAIL','UTL_HTTP','UTL_INADDR','DBMS_LDAP') AND owner NOT IN ('SYS','PUBLIC','ORDPLUGINS');

- dba_objects'in backup'ını al.

- Preupgrade step

Execute Preupgrade script from source home
$Earlier_release_Oracle_home/jdk/bin/java -jar $New_release_Oracle_home/rdbms/admin/preupgrade.jar FILE TEXT DIR output_dir


**************** Upgrade Database to 12.2 ***************

SQL> alter system set cluster_database=FALSE scope=spfile;
srvctl stop db -d KASCVUAT -o immediate
SQL> startup mount;
SQL> alter database archivelog;
SQL> alter database open;
SQL> create restore point before_upgrade guarantee flashback database;
SQL> shutdown immediate;

export ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_BASE=<path to Oracle_Base set during installation>

Start DB in upgrade mode from target ORACLE_HOME
CONNECT / AS SYSDBA
SQL> startup upgrade;
SQL> exit

cd $ORACLE_HOME/bin
./dbupgrade
Execute Post-Upgrade Status Tool, utlu122s.sql and review the upgrade spool log file.  You run the Post-Upgrade Status Tool in the environment of the new release.

$ sqlplus "/as sysdba"
SQL> STARTUP
SQL> @utlu122s.sql

Verify the upgrade log whether catuppst.sql has been executed or not.  If not, execute it manually from new ORACLE_HOME, located at $ORACLE_HOME/rdbms/admin directory
SQL> @catuppst.sql

Run utlrp.sql to recompile any remaining stored PL/SQL and Java code in another session.
SQL> @utlrp.sql

$ORACLE_HOME/bin/srvctl upgrade database -db $ORACLE_UNQNAME -o $ORACLE_HOME



************ Post upgrade *********

- Update oratab entries

Modify the corresponding entry in the /etc/oratab file to point to the new ORACLE_HOME location.

- Upgrading Tables Dependent on Oracle-Maintained Types
COLUMN owner FORMAT A30
COLUMN table_name FORMAT A30
SELECT DISTINCT owner, table_name
FROM dba_tab_cols
WHERE data_upgraded = 'NO'
ORDER BY 1,2;



SET SERVEROUTPUT ON
@utluptabdata.sql

- Upgrade the Time Zone File Version After Upgrading Oracle Database
            Updating the RDBMS DST version in 12c Release 1 (12.1.0.1 and up) using DBMS_DST (Doc ID 1509653.1)
@countstatsTSTZ.sql
exec dbms_scheduler.purge_log;
@upg_tzv_check.sql
@upg_tzv_apply.sql

cd $ORACLE_HOME/sqlpatch/22139245
sqlplus /nolog
SQL> CONNECT / AS SYSDBA
SQL> STARTUP
SQL> alter system set cluster_database=false scope=spfile;
SQL> SHUTDOWN
SQL> STARTUP UPGRADE
SQL> @postinstall.sql
SQL> alter system set cluster_database=true scope=spfile;
SQL> SHUTDOWN
SQL> STARTUP

>connect as SYS and run script @?/javavm/admin/fixTZa
>Shutdown and restart the database using startup migrate.
>connect as SYS and run script @?/javavm/admin/fixTZb
>restart the database without startup migrate.

---

RMAN> connect catalog <user>/<password>@<service>
RMAN> upgrade catalog;
RMAN> upgrade catalog;

---

- Configure Access Control Lists (ACLs) to External Network Services
- Enabling Oracle Database Vault After Upgrading Oracle Database
- Check for the SQLNET.ALLOWED_LOGON_VERSION Parameter Behavior

----

1. /u01/app/oracle/product/12.2.0.1/dbhome_1/jdk/bin/java -jar /u01/app/oracle/product/12.2.0.1/dbhome_1/rdbms/admin/preupgrade.jar
2. emremove.sql catnoamd.sql
3. purge dba_recyclebin;
4. EXECUTE DBMS_STATS.GATHER_DICTIONARY_STATS;
5. utlrp.sql
6. create table steke.object as select * from dba_objects;
7. Patch 20898997: XMLTYPESUP: QCTOXSNLB SHOULD NOT CHECK AGAINST SNAPSHOT SIZE
8. startup - ./dbupgrade  - startup @?/rdbms/admin/utlu122s.sql
9. tz-apply
10.srvctl upgrade database -db name -o ORACLE_HOME

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

---

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

---

DBUA failed with ORA-00600: [krcpasb_bufsz_exceeds_maxsz] when upgrading from 11gR2 to 12c (Doc ID 2376351.1)

The hidden parameter _bct_public_dba_buffer_maxsize, along with this check, is newly added for release 12.1+.


SQL> alter database disable block change tracking;
SQL> alter system set "_bct_public_dba_buffer_maxsize" = _bct_public_dba_buffer_size;

SQL> alter database enable block change tracking;

---

upg_by_std_upgrd          Failed  Manual fixup recommended.
This Warning from Post Upgrade Fixup Script can be safely ignored due to reasons mentioned below:
(Doc ID 2380677.1)

############### Post Install 11.2.0.4
22139245
24701882
