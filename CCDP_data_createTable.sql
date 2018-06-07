

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
@loopIndex int,		--�j��index
@queryString nvarchar(MAX)


BEGIN
SET NOCOUNT ON;
--�scolumn schema �� �Ȧstable
IF OBJECT_ID('tempdb.dbo.#schemaColumn') IS NOT NULL
	DROP TABLE [#schemaColumn]  --�P�_�Ȧstable�O�_�s�b

-------1. ���Y�qcolumn name 2. �h���ť�
SELECT ROW_NUMBER() OVER(ORDER BY Col.FileSchemaColumnId) AS RowNumber, 
		REPLACE(SUBSTRING(Col.ColumnEName, Col.ETLStartIndex, Col.ETLDataLength),' ','') AS ColumnEName,
		REPLACE(SUBSTRING(Col.ColumnCName, Col.ETLStartIndex, Col.ETLDataLength),' ','') AS ColumnCName,
		Col.DataLength, Col.Remark ,Dic.DataText AS DataType
INTO #schemaColumn 
FROM [CCDP].dbo.FileSchemaColumn Col,[CCDP].dbo.SysDataDictionary  Dic 
WHERE Col.FileSchemaId = @fileSchemaId AND Col.DataTypeId = Dic.DataDictionaryId

--SELECT * FROM #schemaColumn --debug

--�stable name �B remark�B lock
SELECT @tableEName = REPLACE(TableEName,' ','') , @tableCName = REPLACE(TableCName,' ',''), @tableRemark = Remark,@tableLock = IsLock
FROM [CCDP].dbo.FileSchema WHERE FileSchemaId = @fileSchemaId

SET @queryString = 'CREATE TABLE '+ '[CCDP_Data].dbo.'+ @tableEName + '(' 

--�v�@���Xcolumn schema
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



--�ˬd���Q���
IF @tableLock = 1
	SET @output = N'Table is locked' 
--�ˬd���L���table schema
ELSE IF RIGHT(@queryString,1) = '(' 
	SET @output = N'There is no column schema for the table' 
--�ˬd���L�s�btable
ELSE IF OBJECT_ID('[CCDP_Data].dbo.'+@tableEName,'U') IS NOT NULL
	SET @output = N'Table is existed' 
--�ˬd���L���column schema
ELSE IF NOT EXISTS(SELECT * FROM [CCDP].dbo.FileSchema WHERE FileSchemaId = @fileSchemaId)
	SET @output =  N'There is no table schema' 
--�q�L�ˬd�A����query�A�إߪ��
ELSE 
	BEGIN
		--�s�W���
		SET @queryString = @queryString+' )'
		EXEC(@queryString)

		--�s�W��檺 �y�z
		--USE [CCDP_Data];
		--�]��stored procedure ����ϥ�USE statement �A�ҥH�g���B�~��stored procedure
		EXEC CCDP_Data.dbo.EditDescription @tableEName,@tableRemark

		--�s�W���y�z
		SET @loopIndex = 1
		WHILE @loopIndex <= (SELECT MAX(RowNumber) FROM #schemaColumn)
			BEGIN 
				--���Xcolumn remark
				SELECT @columnRemark = Remark, @columnName = ColumnEName
				FROM #schemaColumn
				WHERE RowNumber = @loopIndex

				--�Ncolumn remark ��i �y�z��
				EXEC CCDP_Data.dbo.EditDescription @tableEName,@columnRemark,@columnName

				SET @loopIndex = @loopIndex+1
			END;

		SET @output = N'Success'
	END


--����temporary table
DROP TABLE #schemaColumn
--SELECT @queryString --debug

END