
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Roy
-- Create date: 2018/6/7
-- Description:	新增或修改此資料庫的描述，若無欄位名，就是修改資料表的描述，若有，就是修改欄位的描述
-- =============================================
CREATE PROCEDURE EditDescription
	-- Add the parameters for the stored procedure here
	@tableName nvarchar(50),		--資料表名
	@Remark nvarchar(500),			--描述
	@columnName nvarchar(50) = NULL	--欄位名(可為NULL)
	
AS
BEGIN
	
	SET NOCOUNT ON;
	IF @columnName IS NULL 
	BEGIN
		IF NOT EXISTS(SELECT * FROM ::fn_listextendedproperty(NULL,'schema','dbo','table',@tableName,NULL,NULL))
			BEGIN
			EXEC sp_addextendedproperty 'MS_Description',@Remark,'schema','dbo','table',@tableName
			END
		ELSE
			BEGIN
			EXEC sp_updateextendedproperty 'MS_Description',@Remark,'schema','dbo','table',@tableName
		END
	END
	ELSE
	BEGIN
		IF NOT EXISTS(SELECT * FROM ::fn_listextendedproperty (NULL, 'schema', 'dbo', 'table', @tableName, 'column', @columnName)) 
			BEGIN  
			EXEC sp_addextendedproperty 'MS_Description', @Remark, 'schema', 'dbo', 'table', @tableName, 'column', @columnName
			END  
		ELSE 
			BEGIN  
			EXEC sp_updateextendedproperty 'MS_Description', @Remark, 'schema', 'dbo', 'table', @tableName, 'column', @columnName
			END
	END

    
END
GO
