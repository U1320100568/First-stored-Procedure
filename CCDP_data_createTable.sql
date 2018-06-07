

DECLARE 
@fileSchemaId int,
@output nvarchar(100) OUTPUT
SET @fileSchemaId = 1


DECLARE 
@tableEName nvarchar(50),
@tableCName nvarchar(50),
@tableRemark nvarchar(500),
@tableLock bit,
@columnName nvarchar(50),
@columnRemark nvarchar(500),
@loopIndex int,		--迴圈index
@queryString nvarchar(MAX)


BEGIN
SET NOCOUNT ON;
--存column schema 的 暫存table
IF OBJECT_ID('tempdb.dbo.#schemaColumn') IS NOT NULL
	DROP TABLE [#schemaColumn]  --判斷暫存table是否存在

-------1. 取某段column name 2. 去掉空白
SELECT ROW_NUMBER() OVER(ORDER BY Col.FileSchemaColumnId) AS RowNumber, 
		REPLACE(SUBSTRING(Col.ColumnEName, Col.ETLStartIndex, Col.ETLDataLength),' ','') AS ColumnEName,
		REPLACE(SUBSTRING(Col.ColumnCName, Col.ETLStartIndex, Col.ETLDataLength),' ','') AS ColumnCName,
		Col.DataLength, Col.Remark ,Dic.DataText AS DataType
INTO #schemaColumn 
FROM [CCDP].dbo.FileSchemaColumn Col,[CCDP].dbo.SysDataDictionary  Dic 
WHERE Col.FileSchemaId = @fileSchemaId AND Col.DataTypeId = Dic.DataDictionaryId

--SELECT * FROM #schemaColumn --debug

--存table name 、 remark、 lock
SELECT @tableEName = REPLACE(TableEName,' ','') , @tableCName = REPLACE(TableCName,' ',''), @tableRemark = Remark,@tableLock = IsLock
FROM [CCDP].dbo.FileSchema WHERE FileSchemaId = @fileSchemaId

SET @queryString = 'CREATE TABLE '+ '[CCDP_Data].dbo.'+ @tableEName + '(' 

--逐一取出column schema
SET @loopIndex = 1
WHILE @loopIndex <= (SELECT MAX(RowNumber) FROM #schemaColumn)
BEGIN 
	
	SELECT @queryString = @queryString 
	+ CASE RowNumber WHEN 1 THEN '' ELSE ', ' END
	+ ' '+ ColumnEName + ' '+ DataType+' '
	+ CASE DataType WHEN 'nvarchar' THEN '(' +CONVERT(nvarchar(20),DataLength) + ')' ELSE '' END
	+ ' NOT NULL '
	FROM #schemaColumn
	WHERE RowNumber = @loopIndex

	SET @loopIndex = @loopIndex+1
END;



--檢查表格被鎖住
IF @tableLock = 1
	SET @output = N'Table is locked' 
--檢查有無欄位table schema
ELSE IF RIGHT(@queryString,1) = '(' 
	SET @output = N'There is no column schema for the table' 
--檢查有無存在table
ELSE IF OBJECT_ID('[CCDP_Data].dbo.'+@tableEName,'U') IS NOT NULL
	SET @output = N'Table is existed' 
--檢查有無欄位column schema
ELSE IF NOT EXISTS(SELECT * FROM [CCDP].dbo.FileSchema WHERE FileSchemaId = @fileSchemaId)
	SET @output =  N'There is no table schema' 
--通過檢查，執行query，建立表格
ELSE 
	BEGIN
		--新增表格
		SET @queryString = @queryString+' )'
		EXEC(@queryString)

		--新增表格的 描述
		--USE [CCDP_Data];
		--因為stored procedure 不能使用USE statement ，所以寫成額外的stored procedure
		EXEC CCDP_Data.dbo.EditDescription @tableEName,@tableRemark

		--新增欄位描述
		SET @loopIndex = 1
		WHILE @loopIndex <= (SELECT MAX(RowNumber) FROM #schemaColumn)
			BEGIN 
				--取出column remark
				SELECT @columnRemark = Remark, @columnName = ColumnEName
				FROM #schemaColumn
				WHERE RowNumber = @loopIndex

				--將column remark 填進 描述中
				EXEC CCDP_Data.dbo.EditDescription @tableEName,@columnRemark,@columnName

				SET @loopIndex = @loopIndex+1
			END;

		SET @output = N'Success'
	END


--移除temporary table
DROP TABLE #schemaColumn
--SELECT @queryString --debug

END