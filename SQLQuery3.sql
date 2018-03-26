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
 @ColumnName varchar(30),
 @DataType varchar(30),
 @DataLength varchar(30),
 @Primary bit,
 

 @QueryString varchar(300),
 @DataCount int,
 @_i int
 
 SET @_i=1;
 SET @QueryString = '';
 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
    -- Insert statements for procedure here
	SET NOCOUNT ON;
 
 SELECT @TableName = TableName FROM dbo.ETLDictionary
 WHERE ETLSettingName = @SettingName;

 SELECT @DataCount= count(*) FROM dbo.ETLDictionaryDetail
 WHERE ETLDictionaryId IN(
 SELECT ETLDictionaryId FROM dbo.ETLDictionary
 WHERE ETLSettingName = @SettingName) ;
   
 WHILE @_i <= @DataCount
 BEGIN
  SELECT @ColumnName = ColumnName, @DataType = DataType, @DataLength = DataLength, @Primary = IsPrimaryKey
  FROM dbo.ETLDictionaryDetail
  WHERE ETLDictionaryId IN(
  SELECT ETLDictionaryId FROM dbo.ETLDictionary
  WHERE ETLSettingName = @SettingName) and Seq = @_i ;

  SET @QueryString = @QueryString +@ColumnName+' '+ @DataType ;
  IF @DataType = 'nvarchar'  SET @QueryString = @QueryString+' ('+@DataLength+') ';
  IF @Primary = 1  SET @QueryString = @QueryString+ ' PRIMARY KEY ';
  SET @QueryString = @QueryString+' Not Null ';
  IF @_i<>5  SET @QueryString = @QueryString+' , ';
  
  SET @_i= @_i+1;
 END
 
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
