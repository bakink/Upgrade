----------
12c ENV :
----------
cd /u01/app/oracle/product/12.2.0.1/dbhome_1/rdbms/admin/
SQL> startup downgrade pfile='/home/oracle/acn.pfile';

SQL> @?/rdbms/admin/catols.sql
SQL> exec lbacsys.configure_ols
SQL> exec lbacsys.ols_enforcement.enable_ols
SQL> shu immediate;
SQL> startup
SQL> @?/rdbms/admin/catmac.sql system temp <syspasswd>
SQL> grant select on ALL_USERS to CTXSYS;

OPatch]$./datapatch -rollback all -force

1. Delete the registry entry where STATUS='WITH ERRORS'
SQL>create table registry$sqlpatch_org as select * from registry$sqlpatch ;
SQL>delete from registry$sqlpatch where patch_id='27105253' and STATUS='WITH ERRORS'; ====> This should delete 8 rows.
SQL>commit ;
2. Run datapatch as Below to rollback 27105253:
datapatch -rollback 27105253 -force -verbose
3. Update registry entry where STATUS='WITH ERRORS' with STATUS='SUCCESS'
UPDATE dba_registry_sqlpatch
SET status = 'SUCCESS', action_time = SYSTIMESTAMP
WHERE patch_id = 27105253
AND action = UPPER('rollback')
AND action_time = (SELECT MAX(action_time)
FROM dba_registry_sqlpatch
WHERE patch_id = 27105253
AND action = UPPER('rollback'));
commit;
4. Check status in dba_registry_sqlpatch
SQL> select PATCH_ID,ACTION,STATUS,ACTION_TIME,DESCRIPTION from registry$sqlpatch;
5. Run the Downgrade to check if you are getting error.


SQL> spool /home/oracle/acn_downgrade.log
SQL> @olspredowngrade.sql
SQL> @catdwgrd.sql

SQL> SHUTDOWN IMMEDIATE
----------
11g ENV :
----------
SQL> STARTUP UPGRADE
SQL> $ORACLE_HOME/rdbms/admin/catrelod.sql
