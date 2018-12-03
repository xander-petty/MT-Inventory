# MT-Inventory
Tool for creating hardware inventory

To utilize this module please check that your PowerShell Execution Policy is set to at least RemoteSigned on all computers involved (local or remote) and any remote computers also have PowerShell Remoting enabled. 

On local computer run the following:
Set-ExecutionPolicy RemoteSigned -Force 

On all remote computers:
Set-ExecutionPolicy RemoteSigned -Force
Enable-PSRemoting -Force 

NOTE: If you are not on a domain, you will need to do further research to enable PSRemoting. Such research is not made availbe here. 

To install, please copy the entire folder titled 'MT-Inventroy' and place it in your PowerShell modules folder. I prefer to place all of my modules here: 'C:\Program Files\WindowsPowerShell\Modules\'

Once the folder is in the module path, execution policy is set, and PS remoting is enabled on all remote devices, you can run the function New-Inventory. For syntax and more detailed descriptions once loaded, please read the help file. (Get-Help New-Inventory).
