### opatch manual apply

(root) /u01/app/12.2.0.1/grid/perl/bin/perl /u01/app/12.2.0.1/grid/crs/install/rootcrs.pl -prepatch

/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch rollback -id 16837274 -local
/u01/app/oracle/product/12.2.0/dbhome_1/OPatch/opatch rollback -local -id 25385515 -oh /u01/app/oracle/product/12.2.0/dbhome_1
/u01/app/12.2.0.1/grid/OPatch/opatch rollback -local -id 25385515 -oh /u01/app/12.2.0.1/grid
--

/u01/patches/BP_180417/db/27726508/27475722/27441052/custom/server/27441052/custom/scripts/prepatch.sh
/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch napply -oh /u01/app/oracle/product/11.2.0.4/dbhome_1 -local /u01/patches/BP_180417/db/27726508/27475722/27346006
/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch napply -oh /u01/app/oracle/product/11.2.0.4/dbhome_1 -local /u01/patches/BP_180417/db/27726508/27475722/27441052/custom/server/27441052
/u01/patches/BP_180417/db/27726508/27475722/27441052/custom/server/27441052/custom/scripts/postpatch.sh -dbhome /u01/app/oracle/product/11.2.0.4/dbhome_1

/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch apply -local /u01/patches/BP_180417/db/conflict/11.2/16837274
/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch apply -local /u01/patches/BP_180417/db/27726508/27475598
--

/u01/app/12.2.0.1/grid/OPatch/opatch apply -local  /u01/patches/BP_180417/grid/27468969/27464465 -oh /u01/app/12.2.0.1/grid
/u01/app/12.2.0.1/grid/OPatch/opatch apply -local  /u01/patches/BP_180417/grid/27468969/27458609 -oh /u01/app/12.2.0.1/grid
/u01/app/12.2.0.1/grid/OPatch/opatch apply -local  /u01/patches/BP_180417/grid/27468969/26839277 -oh /u01/app/12.2.0.1/grid
/u01/app/12.2.0.1/grid/OPatch/opatch apply -local  /u01/patches/BP_180417/grid/27468969/27674384 -oh /u01/app/12.2.0.1/grid
/u01/app/12.2.0.1/grid/OPatch/opatch apply -local  /u01/patches/BP_180417/grid/27468969/27144050 -oh /u01/app/12.2.0.1/grid

/u01/patches/BP_180417/grid/27468969/27464465/custom/scripts/prepatch.sh -dbhome /u01/app/oracle/product/12.2.0/dbhome_1
/u01/app/oracle/product/12.2.0/dbhome_1/OPatch/opatch apply -oh /u01/app/oracle/product/12.2.0/dbhome_1 -local /u01/patches/BP_180417/grid/27468969/27464465
/u01/app/oracle/product/12.2.0/dbhome_1/OPatch/opatch apply -oh /u01/app/oracle/product/12.2.0/dbhome_1 -local /u01/patches/BP_180417/grid/27468969/27674384
/u01/patches/BP_180417/grid/27468969/27464465/custom/scripts/postpatch.sh -dbhome /u01/app/oracle/product/12.2.0/dbhome_1
--

/u01/app/12.2.0.1/grid/OPatch/opatch apply -oh /u01/app/12.2.0.1/grid -local /u01/patches/BP_180417/db/conflict/12.2/25385515/25385515
/u01/app/oracle/product/12.2.0/dbhome_1/OPatch/opatch apply -oh /u01/app/oracle/product/12.2.0/dbhome_1 -local /u01/patches/BP_180417/db/conflict/12.2/25385515/25385515
/u01/app/oracle/product/12.2.0/dbhome_1/OPatch/opatch apply -oh /u01/app/oracle/product/12.2.0/dbhome_1 -local /u01/patches/BP_180417/db/12.2/trChar/26380097
--

(root) /u01/app/12.2.0.1/grid/rdbms/install/rootadd_rdbms.sh
(root) /u01/app/12.2.0.1/grid/perl/bin/perl /u01/app/12.2.0.1/grid/crs/install/rootcrs.pl -postpatch

### post patching
11.2.0.4.BP apply
@?/rdbms/admin/catbundle.sql exa apply

Plan Change :
BP180417:
   No optimizer fixes applied as part of this bundle

11.2.0.4 OJVM apply :
cd /u01/patches/BP_180417/db/27726508/27475598
SQL> CONNECT / AS SYSDBA
SQL> STARTUP
SQL> alter system set cluster_database=false scope=spfile;
SQL> SHUTDOWN
SQL> STARTUP UPGRADE
SQL> @postinstall.sql
SQL> alter system set cluster_database=true scope=spfile;
SQL> SHUTDOWN
SQL> STARTUP
SQL> @?/rdbms/admin/utlrp.sql

12.2 BP apply
/u01/app/oracle/product/12.2.0/dbhome_1/OPatch/datapatch -verbose


RMAN> connect catalog <user>/<password>@<service>
RMAN> upgrade catalog;
RMAN> upgrade catalog;

###

### opatchauto ###

# Rollback the conflicted 25385515 (RMAN Backup Trace Bug) patch from the 12.2 both GI and DB homes
(root) /u01/app/12.2.0.1/grid/OPatch/opatchauto rollback /u01/patches/BP_180417/db/conflict/12.2/25385515
(root) /u01/app/12.2.0.1/grid/OPatch/opatchauto apply /u01/patches/BP_180417/grid/27468969
(root) /u01/app/12.2.0.1/grid/OPatch/opatchauto apply /u01/patches/BP_180417/db/conflict/12.2/25385515

# Rollback the conflicted 16837274 (cardinality feedback poor subsequent plan) patch from the 12.2 DB homes

(oracle) srvctl stop home -o /u01/app/oracle/product/11.2.0.4/dbhome_1 -n alzx4dbadm01,2,3,4 -s /tmp/stat.txt
(oracle) /u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch rollback -id 16837274 -local

/u01/patches/BP_180417/db/27726508/27475722/27441052/custom/server/27441052/custom/scripts/prepatch.sh
/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch napply -oh /u01/app/oracle/product/11.2.0.4/dbhome_1 -local /u01/patches/BP_180417/db/27726508/27475722/27346006
/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch napply -oh /u01/app/oracle/product/11.2.0.4/dbhome_1 -local /u01/patches/BP_180417/db/27726508/27475722/27441052/custom/server/27441052
/u01/patches/BP_180417/db/27726508/27475722/27441052/custom/server/27441052/custom/scripts/postpatch.sh -dbhome /u01/app/oracle/product/11.2.0.4/dbhome_1

/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch apply -local /u01/patches/BP_180417/db/conflict/11.2/16837274
/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch apply -local /u01/patches/BP_180417/db/27726508/27475598

srvctl start home -o /u01/app/oracle/product/11.2.0.4/dbhome_1 -n alzx4dbadm01,2,3,4 -s /tmp/stat.txt

--> # post patching
### / ###
