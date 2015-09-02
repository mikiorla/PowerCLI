$datastorename = "DATASTORE-X"

$ds = Get-Datastore -Name $datastorename | %{Get-View $_.Id}

$fileQueryFlags = New-Object VMware.Vim.FileQueryFlags
$fileQueryFlags.FileSize = $true
$fileQueryFlags.FileType = $true
$fileQueryFlags.Modification = $true

$searchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
$searchSpec.details = $fileQueryFlags
$searchSpec.sortFoldersFirst = $true

$dsBrowser = Get-View $ds.browser

$rootPath = "["+$ds.summary.Name+"]"
$searchResult = $dsBrowser.SearchDatastoreSubFolders($rootPath, $searchSpec)
$myCol = @()
foreach ($folder in $searchResult)
{
	foreach ($fileResult in $folder.File)
	{
		$file = "" | select Name, Size, Modified, FullPath
		$file.Name = $fileResult.Path
		$file.Size = $fileResult.Filesize
		$file.Modified = $fileResult.Modification
		$file.FullPath = $folder.FolderPath + $file.Name
		$myCol += $file
	}
}
$myCol | Out-Default