MERGE table1		AS TARGET
USING table2	AS SOURCE
	ON (table1.column = table2.column COLLATE DATABASE_DEFAULT)
WHEN MATCHED THEN 
	UPDATE SET column2 = source.column2,
WHEN NOT MATCHED THEN 
	INSERT (column,column2) 
	VALUES (value1,value2)
;