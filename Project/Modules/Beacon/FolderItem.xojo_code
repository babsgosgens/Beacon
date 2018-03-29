#tag Class
Protected Class FolderItem
	#tag Method, Flags = &h0
		Function Child(Name As Text) As Beacon.FolderItem
		  #if TargetiOS
		    Return Self.mSource.Child(Name)
		  #else
		    Return Self.mLegacySource.Child(Name)
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Children() As Xojo.Core.Iterable
		  Dim Items As Beacon.Collection
		  #if TargetiOS
		    For Each Child As Xojo.IO.FolderItem In Self.mSource.Children
		      Dim Converted As Beacon.FolderItem = Child
		      Items.Append(Converted)
		    Next
		  #else
		    For I As Integer = 0 To Self.mLegacySource.Count
		      Dim Converted As Beacon.FolderItem = Self.mLegacySource.Item(I)
		      Items.Append(Converted)
		    Next
		  #endif
		  Return Items
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(FromPath As Text)
		  #if TargetiOS
		    Self.mSource = New Xojo.IO.FolderItem(FromPath)
		  #else
		    Self.mLegacySource = GetFolderItem(FromPath, Global.FolderItem.PathTypeNative)
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  #if TargetiOS
		    Return Self.mSource.Count
		  #else
		    Return Self.mLegacySource.Count
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CreateAsFolder()
		  #if TargetiOS
		    Self.mSource.CreateAsFolder
		  #else
		    Self.mLegacySource.CreateAsFolder
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Private Shared Sub DeepDelete(File As Global.FolderItem)
		  Dim C As Integer = File.Count
		  For I As Integer = C DownTo 0
		    DeepDelete(File.Item(I))
		  Next
		  File.Delete
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, CompatibilityFlags = (TargetIOS and (Target32Bit or Target64Bit))
		Private Shared Sub DeepDelete(File As Xojo.IO.FolderItem)
		  For Each Child As Xojo.IO.FolderItem In File.Children
		    DeepDelete(Child)
		  Next
		  File.Delete
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Delete(Deep As Boolean = False)
		  #if TargetiOS
		    If Deep Then
		      Self.DeepDelete(Self.mSource)
		    Else
		      Self.mSource.Delete
		    End If
		  #else
		    If Deep Then
		      Self.DeepDelete(Self.mLegacySource)
		    Else
		      Self.mLegacySource.Delete
		    End If
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Destructor()
		  If Self.mIsTemporary And Self.Exists Then
		    Self.Delete(True)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DisplayName() As Text
		  #if TargetiOS
		    Return Self.mSource.DisplayName
		  #else
		    Return Self.mLegacySource.DisplayName.ToText
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Exists() As Boolean
		  #if TargetiOS
		    Return Self.mSource <> Nil And Self.mSource.Exists
		  #else
		    Return Self.mLegacySource <> Nil And Self.mLegacySource.Exists
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Extension() As Text
		  Dim Name As Text = Self.Name
		  If Name.IndexOf(".") = -1 Then
		    Return ""
		  End If
		  
		  Dim Parts() As Text = Name.Split(".")
		  Return Parts(Parts.Ubound)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsFolder() As Boolean
		  #if TargetiOS
		    Return Self.mSource.IsFolder
		  #else
		    Return Self.mLegacySource.Directory
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Function IsType(Type As FileType) As Boolean
		  Return Self.Name.EndsWith(Type.PrimaryExtension.ToText)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Length() As UInt64
		  #if TargetiOS
		    Return Self.mSource.Length
		  #else
		    Return Self.mLegacySource.Length
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Name() As Text
		  #if TargetiOS
		    Return Self.mSource.Name
		  #else
		    Return Self.mLegacySource.Name.ToText
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Function Operator_Convert() As Global.FolderItem
		  Return Self.mLegacySource
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, CompatibilityFlags = (TargetIOS and (Target32Bit or Target64Bit))
		Function Operator_Convert() As Xojo.IO.FolderItem
		  Return Self.mSource
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Sub Operator_Convert(Source As Global.FolderItem)
		  Self.mLegacySource = Source
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, CompatibilityFlags = (TargetIOS and (Target32Bit or Target64Bit))
		Sub Operator_Convert(Source As Xojo.IO.FolderItem)
		  Self.mSource = Source
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Path() As Text
		  #if TargetiOS
		    Return Self.mSource.Path
		  #else
		    Return Self.mLegacySource.NativePath.ToText
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Length As Integer = -1) As Xojo.Core.MemoryBlock
		  #if TargetiOS
		    Dim Stream As Xojo.IO.BinaryStream = Xojo.IO.BinaryStream.Open(Self.mSource, Xojo.IO.BinaryStream.LockModes.Read)
		    If Length <= 0 Then
		      Length = Stream.Length
		    Else
		      Length = Min(Stream.Length, Length)
		    End If
		    Dim Content As Xojo.Core.MemoryBlock = Stream.Read(Length)
		    Stream.Close
		    Return Content
		  #else
		    Dim Stream As BinaryStream = BinaryStream.Open(Self.mLegacySource, False)
		    If Length <= 0 Then
		      Length = Stream.Length
		    Else
		      Length = Min(Stream.Length, Length)
		    End If
		    Dim Content As Global.MemoryBlock = Stream.Read(Length, Nil)
		    Stream.Close
		    
		    Dim Mem As New Xojo.Core.MemoryBlock(Content)
		    Return Mem.Left(Content.Size)
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Encoding As Xojo.Core.TextEncoding) As Text
		  Dim Content As Xojo.Core.MemoryBlock = Self.Read()
		  Return Encoding.ConvertDataToText(Content, False)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Shared Function Temporary() As Beacon.FolderItem
		  Dim Item As Beacon.FolderItem
		  #if TargetiOS
		    Item = Xojo.IO.SpecialFolder.Temporary.Child(Beacon.CreateUUID)
		  #else
		    Item = SpecialFolder.Temporary.Child(Beacon.CreateUUID)
		  #endif
		  Item.mIsTemporary = True
		  Return Item
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(Content As Text, Encoding As Xojo.Core.TextEncoding)
		  Self.Write(Encoding.ConvertTextToData(Content))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(Content As Xojo.Core.MemoryBlock)
		  #if TargetiOS
		    Dim Stream As Xojo.IO.BinaryStream = Xojo.IO.BinaryStream.Create(Self.mSource)
		    Stream.Write(Content)
		    Stream.Close
		  #else
		    Dim Stream As BinaryStream = BinaryStream.Create(Self.mLegacySource, True)
		    Stream.Write(CType(Content.Data, MemoryBlock).StringValue(0, Content.Size))
		    Stream.Close
		  #endif
		End Sub
	#tag EndMethod


	#tag Note, Name = Purpose
		
		This is a wrapper class so the classic framework can use classic folderitem
		and the new framework can use the new folderitem without worrying about
		the details.
		
		Why not just use all Xojo.IO.FolderItem? Because it doesn't work with non-ascii
		characters on Windows.
	#tag EndNote


	#tag Property, Flags = &h21
		Private mIsTemporary As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Private mLegacySource As Global.FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21, CompatibilityFlags = (TargetIOS and (Target32Bit or Target64Bit))
		Private mSource As Xojo.IO.FolderItem
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
