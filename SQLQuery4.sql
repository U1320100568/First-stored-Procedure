-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE CreateTable
	-- Add the parameters for the stored procedure here
	@SettingName varchar(30)
AS
DECLARE 
 @TableName varchar(30),
 @QueryString varchar(300);
 SET @QueryString = '';
 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
    -- Insert statements for procedure here
	SET NOCOUNT ON;
 
 SELECT @TableName = TableName FROM dbo.ETLDictionary
 WHERE ETLSettingName = @SettingName;

 SELECT @QueryString = 
	replace(
	stuff(  
	(SELECT  ', '+CAST(ColumnName AS varchar) +'  '+CAST(DataType AS varchar)
				+'('+CAST(DataLength AS varchar)+') '
				+IIF(IsPrimaryKey = 1,' PRIMARY KEY ','')+' NOT NULL'
	  FROM dbo.ETLDictionaryDetail
	  WHERE ETLDictionaryId  IN(
	  SELECT ETLDictionaryId FROM dbo.ETLDictionary
	  WHERE ETLSettingName = @SettingName)
 
	  ORDER BY Seq 
	  FOR XML PATH('')
	)
	,1,1,'')
	,'()',' ');
 
 EXEC('CREATE TABLE [dbo].['+ @TableName +'] ('
 + @QueryString
 +');');
    -- Insert statements for procedure here
 --SET @QueryString= 'CREATE TABLE [dbo].['+ @TableName +'] ('
 --+ @QueryString
 --+');';

 SELECT @QueryString
END
GO
