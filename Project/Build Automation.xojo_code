#tag BuildAutomation
			Begin BuildStepList Linux
				Begin BuildProjectStep Build
				End
			End
			Begin BuildStepList Mac OS X
				Begin BuildProjectStep Build
				End
				Begin CopyFilesBuildStep ReplaceIcons
					AppliesTo = 0
					Destination = 1
					Subdirectory = 
					FolderItem = Li4vLi4vQXJ0d29yay9BcHAuaWNucw==
					FolderItem = Li4vLi4vQXJ0d29yay9CZWFjb25Eb2N1bWVudC5pY25z
					FolderItem = Li4vLi4vQXJ0d29yay9CZWFjb25JZGVudGl0eS5pY25z
					FolderItem = Li4vLi4vQXJ0d29yay9CZWFjb25QcmVzZXQuaWNucw==
				End
				Begin CopyFilesBuildStep CopyPresetsMac
					AppliesTo = 0
					Destination = 1
					Subdirectory = 
					FolderItem = Li4vLi4vUHJlc2V0cy8=
				End
			End
			Begin BuildStepList Windows
				Begin BuildProjectStep Build
				End
				Begin CopyFilesBuildStep CopyPresetsWin
					AppliesTo = 0
					Destination = 1
					Subdirectory = 
					FolderItem = Li4vLi4vUHJlc2V0cy8=
				End
			End
#tag EndBuildAutomation
