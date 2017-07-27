SELECT  'Head of the Blocking Chain -->' AS SPID_State ,
        spid ,
        blocked ,
        hostname ,
        program_name ,
        cmd ,
        text AS Executing_script ,
        waittime ,
        lastwaittype ,
       -- a.dbid ,
        cpu ,
        physical_io ,
        memusage ,
        login_time ,
        last_batch ,
        status
FROM    sys.sysprocesses a
        CROSS APPLY sys.dm_exec_sql_text(sql_handle)
WHERE hostname ='SACETLV108'

WHERE   blocked = 0
        AND spid IN ( SELECT    blocked
                      FROM      sys.sysprocesses
                      WHERE     blocked <> 0 )




 sp_who2 475
 EXEC dbo.ETL_Load_CDR_09a_CxMedication_wkly

 SELECT COUNT(*) FROM dbo.CxClinicalRecord WHERE DataSourceSID ='5'
 SELECT * FROM synchlog
 ORDER BY IntLogId DESC
 
 SELECT * FROM sys.sysprocesses



 SELECT [Spid] = session_Id
, ecid
, [Database] = DB_NAME(sp.dbid)
, [User] = nt_username
, [Status] = er.status
, [Wait] = wait_type
, [Individual Query] = SUBSTRING (qt.text,
er.statement_start_offset/2,
(CASE WHEN er.statement_end_offset = -1
THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
ELSE er.statement_end_offset END -
er.statement_start_offset)/2)
,[Parent Query] = qt.text
, Program = program_name
, Hostname
, nt_domain
, start_time
,sp.last_batch
FROM sys.dm_exec_requests er
INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle)as qt
WHERE session_Id > 50 -- Ignore system spids.
AND session_Id NOT IN (@@SPID) -- Ignore this current statement.
--and DB_NAME(sp.dbid)='RangeCheckTool'
ORDER BY 1, 2


SELECT
db.name DBName,
tl.request_session_id,
wt.blocking_session_id,
OBJECT_NAME(p.OBJECT_ID) BlockedObjectName,
tl.resource_type,
h1.TEXT AS RequestingText,
h2.TEXT AS BlockingTest,
tl.request_mode
FROM sys.dm_tran_locks AS tl
INNER JOIN sys.databases db ON db.database_id = tl.resource_database_id
INNER JOIN sys.dm_os_waiting_tasks AS wt ON tl.lock_owner_address = wt.resource_address
INNER JOIN sys.partitions AS p ON p.hobt_id = tl.resource_associated_entity_id
INNER JOIN sys.dm_exec_connections ec1 ON ec1.session_id = tl.request_session_id
INNER JOIN sys.dm_exec_connections ec2 ON ec2.session_id = wt.blocking_session_id
CROSS APPLY sys.dm_exec_sql_text(ec1.most_recent_sql_handle) AS h1
CROSS APPLY sys.dm_exec_sql_text(ec2.most_recent_sql_handle) AS h2


SELECT 
   SessionId    = s.session_id, 
   UserProcess  = CONVERT(CHAR(1), s.is_user_process),
   LoginInfo    = s.login_name,   
   DbInstance   = ISNULL(db_name(r.database_id), N''), 
   TaskState    = ISNULL(t.task_state, N''), 
   Command      = ISNULL(r.command, N''), 
   App            = ISNULL(s.program_name, N''), 
   WaitTime_ms  = ISNULL(w.wait_duration_ms, 0),
   WaitType     = ISNULL(w.wait_type, N''),
   WaitResource = ISNULL(w.resource_description, N''), 
   BlockBy        = ISNULL(CONVERT (varchar, w.blocking_session_id), ''),
   HeadBlocker  = 
        CASE 
            -- session has active request; is blocked; blocking others
            WHEN r2.session_id IS NOT NULL AND r.blocking_session_id = 0 THEN '1' 
            -- session idle; has an open tran; blocking others
            WHEN r.session_id IS NULL THEN '1' 
            ELSE ''
        END, 
   TotalCPU_ms        = s.cpu_time, 
   TotalPhyIO_mb    = (s.reads + s.writes) * 8 / 1024, 
   MemUsage_kb        = s.memory_usage * 8192 / 1024, 
   OpenTrans        = ISNULL(r.open_transaction_count,0), 
   LoginTime        = s.login_time, 
   LastReqStartTime = s.last_request_start_time,
   HostName            = ISNULL(s.host_name, N''),
   NetworkAddr        = ISNULL(c.client_net_address, N''), 
   ExecContext        = ISNULL(t.exec_context_id, 0),
   ReqId            = ISNULL(r.request_id, 0),
   WorkLoadGrp        = N'',
   LastCommandBatch = (select text from sys.dm_exec_sql_text(c.most_recent_sql_handle)) 
   --,lastbatch         = sys.sysprocesses.last_batch
  
FROM sys.dm_exec_sessions s 
LEFT OUTER JOIN sys.dm_exec_connections c ON (s.session_id = c.session_id)
LEFT OUTER JOIN sys.dm_exec_requests r ON (s.session_id = r.session_id)
LEFT OUTER JOIN sys.dm_os_tasks t ON (r.session_id = t.session_id AND r.request_id = t.request_id)
LEFT OUTER JOIN 
(
    -- Using row_number to select longest wait for each thread, 
    -- should be representative of other wait relationships if thread has multiple involvements. 
    SELECT *, ROW_NUMBER() OVER (PARTITION BY waiting_task_address ORDER BY wait_duration_ms DESC) AS row_num
    FROM sys.dm_os_waiting_tasks 
) w ON (t.task_address = w.waiting_task_address) AND w.row_num = 1
LEFT OUTER JOIN sys.dm_exec_requests r2 ON (r.session_id = r2.blocking_session_id)
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) as st
--JOIN sys.sysprocesses a ON a.request_id = r.request_id
--CROSS APPLY sys.dm_exec_sql_text(a.sql_handle)
WHERE s.session_Id > 50                         -- ignore anything pertaining to the system spids.
AND s.session_Id NOT IN (@@SPID)     -- let's avoid our own query! 
ORDER BY s.session_id;

SELECT @@spid
sp_who 498


SELECT  FROM sys.sysprocesses

SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='PROCEDURE'

SELECT PROCEDURE STATUS WHERE db ='CDR_MSDOM_PROD2'

EXEC sp_who2


select 
  object_name(st.objectid) as ProcName,
  qs.status,
  qs.last_batch,
  er.wait_type
from 
  sys.sysprocesses as qs 
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st 
  JOIN sys.dm_exec_requests er ON er.session_id=qs.spid
  JOIN sys.dm_exec_procedure_stats ON 
where 
  object_name(1780253447) is not NULL
  
 
 SELECT spid FROM 
  sys.sysprocesses as qs 
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st 
  JOIN sys.dm_exec_requests er ON er.session_id=qs.spid
  sp_who2 1780253447
  EXEC sp_who 1780253447
  SELECT * FROM sys.sysprocesses

  SELECT * FROM sys.dm_exec_procedure_stats 
  WHERE object_id = 1780253447
  DECLARE @so VARCHAR(MAX)
  SET @so = 'Synch_Int_CDR_Handler'
  SELECT OBJECT_NAME(1956254074)
  SELECT OBJECT_ID(@so)
  SELECT * FROM sys.dm_exec_procedure_stats WHERE type='P 'ORDER BY last_execution_time desc
  execution_count
  total_worker_time
  last_worker_time

  SELECT OBJECT_NAME(@@procid)


  SELECT * FROM sys.dm_exec_requests
  WHERE session_id > 50
  ORDER BY total_elapsed_time DESC
  
  SELECT  requests.session_id, 
        requests.status, 
        requests.command, 
        requests.statement_start_offset,
        requests.statement_end_offset,
        requests.total_elapsed_time,
        details.text
FROM    sys.dm_exec_requests requests
CROSS APPLY sys.dm_exec_sql_text (requests.plan_handle) details
WHERE   requests.session_id > 50
ORDER BY total_elapsed_time DESC


SELECT  SUBSTRING(detail.text, 
                  requests.statement_start_offset / 2, 
                  (requests.statement_end_offset - requests.statement_start_offset) / 2)
FROM    sys.dm_exec_requests requests
CROSS APPLY sys.dm_exec_sql_text (requests.plan_handle) detail
WHERE   requests.session_id IN (  SELECT  requests.session_id
FROM    sys.dm_exec_requests requests
CROSS APPLY sys.dm_exec_sql_text (requests.plan_handle) details
WHERE   requests.session_id > 50)


SELECT OBJECT_NAME(@@procid)


DECLARE @current VARCHAR(MAX);
SET @current = ( SELECT Stored_Procedure
                 FROM   dbo.Stored_Procedures_Log
                 WHERE  Stored_Procedure = 'Synch_Int_CDR_03_CxOrg'
               );
SELECT  @current;
SELECT  OBJECT_ID(@current);


SELECT  SPID = er.session_id ,
        STATUS = ses.status ,
        sp.last_batch ,
        [Login] = ses.login_name ,
        Host = ses.host_name ,
        BlkBy = er.blocking_session_id ,
        DBName = DB_NAME(er.database_id) ,
        CommandType = er.command ,
        SQLStatement = st.text ,
        st.objectid ,
        ElapsedMS = er.total_elapsed_time ,
        CPUTime = er.cpu_time ,
        IOReads = er.logical_reads + er.reads ,
        IOWrites = er.writes ,
        LastWaitType = er.last_wait_type ,
        StartTime = er.start_time ,
        Protocol = con.net_transport ,
        ConnectionWrites = con.num_writes ,
        ConnectionReads = con.num_reads ,
        ClientAddress = con.client_net_address ,
        Authentication = con.auth_scheme
FROM    sys.dm_exec_requests er
        OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st
        INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
        LEFT JOIN sys.dm_exec_sessions ses ON ses.session_id = er.session_id
        LEFT JOIN sys.dm_exec_connections con ON con.session_id = ses.session_id
WHERE er.session_id=370   
--er.session_id > 50
        --AND ses.host_name = 'SACETLV108';


EXEC sp_helptext Synch_Int_CDR_Handler;

SELECT  *
FROM    sys.dm_exec_procedure_stats;

EXEC msdb.dbo.sp_help_job @execution_status = 1;

SELECT  [Spid] = session_id ,
        ecid ,
        [Database] = DB_NAME(sp.dbid) ,
        [User] = nt_username ,
        [Status] = er.status ,
        [Wait] = wait_type ,
        [Individual Query] = SUBSTRING(qt.text, er.statement_start_offset / 2,
                                       ( CASE WHEN er.statement_end_offset = -1
                                              THEN LEN(CONVERT(NVARCHAR(MAX), qt.text))
                                                   * 2
                                              ELSE er.statement_end_offset
                                         END - er.statement_start_offset ) / 2) ,
        [Parent Query] = qt.text ,
        Program = program_name ,
        hostname ,
        nt_domain ,
        sp.last_batch ,
        start_time
FROM    sys.dm_exec_requests er
        INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
        CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
WHERE   session_id > 50 -- Ignore system spids.
        AND session_id NOT IN ( @@SPID ); 


		
SELECT  SPID = er.session_id ,
        STATUS = ses.status ,
        sp.last_batch ,
        [Login] = ses.login_name ,
        Host = ses.host_name ,
        BlkBy = er.blocking_session_id ,
        DBName = DB_NAME(er.database_id) ,
        CommandType = er.command ,
        SQLStatement = st.text ,
        st.objectid ,
        ElapsedMS = er.total_elapsed_time ,
        CPUTime = er.cpu_time ,
        IOReads = er.logical_reads + er.reads ,
        IOWrites = er.writes ,
        LastWaitType = er.last_wait_type ,
        StartTime = er.start_time ,
        Protocol = con.net_transport ,
        ConnectionWrites = con.num_writes ,
        ConnectionReads = con.num_reads ,
        ClientAddress = con.client_net_address ,
        Authentication = con.auth_scheme
FROM    sys.dm_exec_requests er
        OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st
        INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
        LEFT JOIN sys.dm_exec_sessions ses ON ses.session_id = er.session_id
        LEFT JOIN sys.dm_exec_connections con ON con.session_id = ses.session_id
WHERE   er.session_id > 50