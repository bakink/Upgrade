dcli -g ~/dbs_group -l root mkdir -p /u01/app/12.2.0.1/grid
dcli -g ~/dbs_group -l root chown oracle:oinstall /u01/app/12.2.0.1/grid

unzip -q /u01/patches/BP_170814/V840012-01.zip -d /u01/app/12.2.0.1/grid

yum install -y tigervnc-server.x86_64
yum install -y xterm

unset ORACLE_HOME ORACLE_BASE ORACLE_SID
cd /u01/app/12.2.0.1/grid
./gridSetup.sh

unset ORACLE_HOME ORACLE_BASE ORACLE_SID
export DISPLAY=<your_xserver>:0
cd /u01/app/12.2.0.1/grid
gridSetup.sh -J-Doracle.install.mgmtDB=false

unzip -oq -d /u01/app/12.2.0.1/grid /u01/patches/BP_170814/p6880880_122010_Linux-x86-64.zip

/u01/app/12.2.0.1/grid/OPatch/opatch apply -oh /u01/app/12.2.0.1/grid -local ./26609966
/u01/app/12.2.0.1/grid/OPatch/opatch apply -oh /u01/app/12.2.0.1/grid -local ./25586399
/u01/app/12.2.0.1/grid/OPatch/opatch apply -oh /u01/app/12.2.0.1/grid -local ./26609817

db-patch

backup rdbms-home

dcli -g ~/dbs_group -l root "cp -R -p /u01/app/oracle/product/11.2.0.4/dbhome_1 /u01/app/oracle/product/11.2.0.4/bkp-dbhome_1"

/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch rollback -id 21075138 -local
/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch rollback -id 16837274 -local

/u01/patches/BP_170814/26610265/26609929/custom/server/26609929/custom/scripts/prepatch.sh -dbhome /u01/app/oracle/product/11.2.0.4/dbhome_1

/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch napply -oh /u01/app/oracle/product/11.2.0.4/dbhome_1 -local /u01/patches/BP_170814/26610265/26609769
/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch napply -oh /u01/app/oracle/product/11.2.0.4/dbhome_1 -local /u01/patches/BP_170814/26610265/26609929/custom/server/26609929

21075138]$/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch apply -local
16837274]$/u01/app/oracle/product/11.2.0.4/dbhome_1/OPatch/opatch apply -local

/u01/patches/BP_170814/26610265/26609929/custom/server/26609929/custom/scripts/postpatch.sh -dbhome /u01/app/oracle/product/11.2.0.4/dbhome_1

cd /u01/app/oracle/product/11.2.0.4/dbhome_1
@rdbms/admin/catbundle.sql exa apply
