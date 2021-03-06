﻿function Get-SSFolder
{
    <#
    .SYNOPSIS
        Get details on folders from secret server

    .DESCRIPTION
        Get details on folders from secret server

    .PARAMETER Name
        Name to search for.  Accepts wildcards as '*'.

    .PARAMETER Id
        Id to search for.  Accepts wildcards as '*'.

    .PARAMETER FolderPath
        Full folder path to search for.  Accepts wildcards as '*'

    .PARAMETER Uri
        uri for your win auth web service.

    .PARAMETER WebServiceProxy
        Existing web service proxy from SecretServerConfig variable

    .EXAMPLE
        Get-SSFolder -FolderPath "*Systems*Service Accounts"

    .EXAMPLE
        Get-SSFolder -Id 55

    .FUNCTIONALITY
        Secret Server
    #>
    [CmdletBinding()]
    param(
        [string]$Name = '*',

        [string]$Id = '*',

        [Alias("Path")]
        [string]$FolderPath = '*',

        [string]$Uri = $SecretServerConfig.Uri,

        [System.Web.Services.Protocols.SoapHttpClientProtocol]$WebServiceProxy = $SecretServerConfig.Proxy,
        
        [string]$Token = $SecretServerConfig.Token        
    )
    
    if(-not $WebServiceProxy.whoami)
    {
        Write-Warning "Your SecretServerConfig proxy does not appear connected.  Creating new connection to $uri"
        try
        {
            $WebServiceProxy = New-WebServiceProxy -uri $Uri -UseDefaultCredential -ErrorAction stop
        }
        catch
        {
            Throw "Error creating proxy for $Uri`: $_"
        }
    }
    
    #Find all folders, filter on name.  We need all to build the folderpath tree
    if($Token){
        $Folders = @( $WebServiceProxy.SearchFolders($Token,$null).Folders )
    }
    else{
        $Folders = @( $WebServiceProxy.SearchFolders($null).Folders )
    }

    #Loop through folders.  Get the full folder path
    foreach($Folder in $Folders) {
        if($Folder.Name -notlike $Name -or $Folder.Id -notlike $Id) {
            continue
        }
        $Folder = New-Object PSObject $Folder
        $Folder.PSTypeNames.Insert(0,"SecretServer.Folder")

        $FolderName = $Folder.Name
        $ParentId = $Folder.ParentFolderId
        $FullPath = "$FolderName"
        while($ParentID -notlike -1) {
            $WorkingFolder = $Folders | Where-Object {$_.Id -eq $ParentId}
            $FullPath = $WorkingFolder.Name, $FullPath -join "\"
            $ParentID = $WorkingFolder.ParentFolderId
        }
        if($FullPath -notlike $FolderPath) {
            continue
        }
        $Folder | Add-Member -MemberType NoteProperty -Name "FolderPath" -Value $FullPath -force -PassThru
    }
}