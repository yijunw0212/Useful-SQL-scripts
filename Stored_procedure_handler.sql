
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ETL_Load_CDR_Load_Handler]
AS
    BEGIN
        DECLARE @ETLSPRunningCount INTEGER;
        DECLARE @currentSP VARCHAR(MAX);
        DECLARE @Load_CDRString VARCHAR(MAX);
        DECLARE @ix INTEGER;
        DECLARE @pos INTEGER;
        SET @ix = 1; 
        SET @pos = 1;

--build Stored Procedures name string
        DECLARE @nametable TABLE ( Col1 VARCHAR(MAX) );
        INSERT  INTO @nametable
                SELECT  DISTINCT
                        so.name
                FROM    sys.syscomments sc
                        INNER JOIN sys.objects so ON sc.id = so.object_id
                WHERE   so.type = 'P'
                        AND so.name LIKE 'ETL_Load%'
                        AND so.name NOT LIKE '%Handler'; 

        SELECT  @Load_CDRString = ISNULL(@Load_CDRString + ',', '')
                + ISNULL(Col1, '')
        FROM    @nametable
        WHERE   Col1 LIKE 'ETL_Load_CDR%';
        UPDATE  Stored_Procedures_Log
        SET     RunningFlag = 0
        WHERE   Stored_Procedure LIKE 'ETL_Load_CDR%';


        WHILE @ix > 0
            BEGIN
                SET @ETLSPRunningCount = ( SELECT   COUNT(*)
                                           FROM     Stored_Procedures_Log t1
                                           WHERE    t1.Stored_Procedure LIKE 'Synch_%'
                                                    AND t1.RunningFlag != 0
                                         );
                IF ( @ETLSPRunningCount = 0 ) -- etl process is not running  
                    BEGIN	
                        SET @ix = CHARINDEX(',', @Load_CDRString, @pos); 
                        IF @ix > 0
                            BEGIN
                                SET @currentSP = SUBSTRING(@Load_CDRString,
                                                           @pos, @ix - @pos); 
                            END;
                        ELSE
                            BEGIN
                                SET @currentSP = SUBSTRING(@Load_CDRString,
                                                           @pos,
                                                           LEN(@Load_CDRString));
                            END;
                        SET @currentSP = LTRIM(RTRIM(@currentSP));                             
                        SET @pos = @ix + 1; 

                        UPDATE  dbo.Stored_Procedures_Log
                        SET     StartTime = GETDATE()
                        WHERE   LTRIM(RTRIM(Stored_Procedure)) = @currentSP;
						UPDATE  Stored_Procedures_Log
                        SET     RunningFlag = @@SPID
                        WHERE   LTRIM(RTRIM(Stored_Procedure)) = @currentSP;
                        BEGIN TRY  
    -- Execute the stored procedure inside the TRY block.  
                            EXECUTE @currentSP;  
                        END TRY  
                        BEGIN CATCH  
                                    PRINT ERROR_NUMBER();
                                    PRINT ERROR_SEVERITY();
                                    PRINT ERROR_STATE();
                                    PRINT ERROR_PROCEDURE();
                                    PRINT ERROR_MESSAGE();
                                    PRINT ERROR_LINE();
                        END CATCH;
                        PRINT @currentSP;
                        UPDATE  Stored_Procedures_Log
                        SET     RunningFlag = 0
                        WHERE   LTRIM(RTRIM(Stored_Procedure)) = @currentSP;
                        UPDATE  dbo.Stored_Procedures_Log
                        SET     FinishTime = GETDATE()
                        WHERE   LTRIM(RTRIM(Stored_Procedure)) = @currentSP;
						WAITFOR DELAY '00:01:00';
                    END;
                ELSE --etl process is running 
                    BEGIN
                        WAITFOR DELAY '00:00:10';
                    END;

            END;

        UPDATE  dbo.Stored_Procedures_Log
        SET     ExecutionCount = execution_count
        FROM    ( SELECT    execution_count ,
                            object_id
                  FROM      sys.dm_exec_procedure_stats
                ) a
        WHERE   Stored_Procedure = OBJECT_NAME(a.object_id);
                        
        UPDATE  dbo.Stored_Procedures_Log
        SET     Duration = b.last_elapsed_time
        FROM    ( SELECT    last_elapsed_time ,
                            object_id
                  FROM      sys.dm_exec_procedure_stats
                  WHERE     type = 'P '
                ) b
        WHERE   Stored_Procedure = OBJECT_NAME(b.object_id);
        
        UPDATE  dbo.Stored_Procedures_Log
        SET     AverageDuration = c.total_elapsed_time / c.execution_count
        FROM    ( SELECT    execution_count ,
                            total_elapsed_time ,
                            object_id
                  FROM      sys.dm_exec_procedure_stats
                  WHERE     type = 'P '
                ) c
        WHERE   Stored_Procedure = OBJECT_NAME(c.object_id);
    END;








