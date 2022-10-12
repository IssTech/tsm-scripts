@echo off
REM Filename: rebalance.cmd
REM Run: '.\rebalance.cmd'

REM This script is made for Windows Platform only

REM Owner: IssTech AB
REM Contributor:
REM - Christian Petersson

cd /D C:\PROGRA~1\Tivoli\TSM\db2\BIN
set TABLE=SYSCATSPACE USERSPACE1 IDXSPACE1 LARGEIDXSPACE1 LARGESPACE1 REPLTBLSPACE1 REPLIDXSPACE1 ARCHOBJDATASPACE ARCHOBJIDXSPACE BACKOBJDATASPACE BACKOBJIDXSPACE BFABFDATASPACE BFABFIDXSPACE BFBFEXTDATASPACE BFBFEXTIDXSPACE DEDUPTBLSPACE1 DEDUPIDXSPACE1 DEDUPTBLSPACE2 DEDUPIDXSPACE2 DEDUPTBLSPACE3 DEDUPIDXSPACE3 DEDUPTBLSPACE4 DEDUPIDXSPACE4 DEDUPTBLSPACE5 DEDUPIDXSPACE5 SYSTOOLSPACE 

db2 connect to tsmdb1

for %%x in (%TABLE%) do CALL :REBALANCE_TABLE %%x

:REBALANCE_TABLE
	rem Running Rebalance on DB2 Tables
	echo Running Rebalance on Table %~1
	db2 alter tablespace %~1 rebalance
	
	rem set counter to 0 and wait 5 seconds until first check will be started
	set counter=0
	set status=1
	timeout /t 5 /nobreak
	
	:DB2_CHECK
	echo Check Status for Rebalance of table %~1

	
	rem Print Status of Rebalance
	db2 "select varchar(tbsp_name, 30) as tbsp_name, dbpartitionnum, member, rebalancer_mode, rebalancer_status, rebalancer_extents_remaining, rebalancer_extents_processed, rebalancer_start_time from table(mon_get_rebalance_status(NULL,-2)) as t"	
	if %errorlevel% == 1 (goto FINISH) else (echo Process not finish...)
	
	rem Timeout for waiting for the first check
	timeout /t 60
	
	rem Update the counter and if the counter have reach 5 (5 min) it will be reset to 0
	SET /A counter=%counter%+1
	if %counter% == 5 (SET /A counter=0)
	
	rem Rerun the status check
	echo test
	goto DB2_CHECK
	
	:FINISH
	rem Reduce space from tablespace
	db2 alter tablespace %~1 reduce max
	EXIT /B 0