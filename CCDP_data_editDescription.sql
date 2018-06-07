
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Roy
-- Create date: 2018/6/7
-- Description:	�s�W�έק惡��Ʈw���y�z�A�Y�L���W�A�N�O�ק��ƪ��y�z�A�Y���A�N�O�ק���쪺�y�z
-- =============================================
CREATE PROCEDURE EditDescription
	-- Add the parameters for the stored procedure here
	@tableName nvarchar(50),		--��ƪ�W
	@Remark nvarchar(500),			--�y�z
	@columnName nvarchar(50) = NULL	--���W(�i��NULL)
	
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
