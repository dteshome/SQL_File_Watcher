/*
Author: Dawit A
Date: 04/19/2016
Note: Checks if a file exists and if it does, it will check the the size of the file. If the size of the file is 0 or if the file does not exist, the script generate an error message.

*/

Declare @File_Name varchar(100) = ''
     ,  @Dir varchar(100) = ''
     ,  @isExist Bit = 0
     ,  @Error_Message varchar(120) = Null

Declare  @Full_File_Path  varchar(210) = @Dir + @File_Name

Exec Master.dbo.xp_fileexist @Full_File_Path, @isExist Output; 

If @isExist = 1
    Begin
        --- Enabling CMDshell to config the server 
        Exec sp_configure 'show advanced options', 1;
        Reconfigure;
        Exec sp_configure 'xp_cmdshell',1;
        Reconfigure;

        ---- get file metadata info 
        Declare @metadata Table (metadata Nvarchar(Max))
        Declare @File_Modified_Date datetime = Null 
            , @FileSize Int = 0
            , @cmd varchar(120) = ' dir ' + @Dir

            Insert Into @metadata(metadata)
            Exec Master.dbo.xp_cmdshell @cmd

            Select Top 1 @File_Modified_Date = Cast(left(metadata, 20) as datetime)
                       , @FileSize = Isnull(Cast(Case When Substring(metadata, 25, 5) = '<DIR>' then null 
                                                Else Replace(Substring(metadata, 25, 15), ',', '')
                                            End as Int), 0)
            From @metadata
            Where metadata Is Not Null 
             And Left(metadata, 1) <> ' '
             And metadata Not Like '%<DIR>%.'
             And metadata like '%' + @File_Name + '%'

        If @FileSize = 0
            Begin
                Set @Error_Message = @File_Name + ' is empty! '
                RaisError(15601, -1,-1, @Error_Message);
            End 
       ----- Reconfiguring the server 
       Exec sp_configure 'show advanced options', 1; 
       Reconfigure;
       Exec sp_configure 'xp_cmdsheel', 0;
       Reconfigure;
    End 
Else 
    Begin
        Set @Error_Message = @File_Name + ' does not exist'
        RaisError(15602, -1, -1, @Error_Message)
    End 
