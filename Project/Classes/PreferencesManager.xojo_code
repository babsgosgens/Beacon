#tag Class
Protected Class PreferencesManager
	#tag Method, Flags = &h0
		Function AutoValue(Key As Text, Default As Auto = Nil) As Auto
		  If Not Self.mValues.HasKey(Key) Then
		    Return Default
		  End If
		  
		  Return Self.mValues.Value(Key)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AutoValue(Key As Text, Assigns Value As Auto)
		  Self.BeginTransaction()
		  Self.mValues.Value(Key) = Value
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub BeginTransaction()
		  If Self.mTransactionLevel = 0 Then
		    Self.mSavedValues = Self.CloneDictionary(Self.mValues)
		  End If
		  
		  Self.mTransactionLevel = Self.mTransactionLevel + 1
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function BinaryValue(Key As Text, Default As Xojo.Core.MemoryBlock = Nil) As Xojo.Core.MemoryBlock
		  If Not Self.mValues.HasKey(Key) Then
		    Return Default
		  End If
		  
		  Dim Value As Auto = Self.mValues.Value(Key)
		  Dim Info As Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType(Value)
		  If Info.FullName <> "Text" Then
		    Return Default
		  End If
		  
		  Return Self.DecodeHex(Value)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub BinaryValue(Key As Text, Assigns Value As Xojo.Core.MemoryBlock)
		  Self.BeginTransaction()
		  Self.mValues.Value(Key) = Self.EncodeHex(Value)
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function BooleanValue(Key As Text, Default As Boolean = False) As Boolean
		  If Not Self.mValues.HasKey(Key) Then
		    Return Default
		  End If
		  
		  Dim Value As Auto = Self.mValues.Value(Key)
		  Dim Info As Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType(Value)
		  If Info.FullName <> "Boolean" Then
		    Return Default
		  End If
		  
		  Return Value
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub BooleanValue(Key As Text, Assigns Value As Boolean)
		  Self.BeginTransaction()
		  Self.mValues.Value(Key) = Value
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ClearAllValues()
		  Self.BeginTransaction()
		  Self.mValues.RemoveAll
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ClearValue(Key As Text)
		  If Self.mValues.HasKey(Key) Then
		    Self.BeginTransaction()
		    Self.mValues.Remove(Key)
		    Self.Commit()
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function CloneDictionary(Source As Xojo.Core.Dictionary) As Xojo.Core.Dictionary
		  If Source = Nil Then
		    Return Nil
		  End If
		  
		  Dim Clone As New Xojo.Core.Dictionary
		  
		  For Each Entry As Xojo.Core.DictionaryEntry In Source
		    Dim Key As Auto = Entry.Key
		    Dim Value As Auto = Entry.Value
		    Dim Info As Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType(Value)
		    If Info.FullName = "Xojo.Core.Dictionary" Then
		      Value = CloneDictionary(Value)
		    End If
		    Clone.Value(Key) = Value
		  Next
		  
		  Return Clone
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ColorValue(Key As Text, Assigns Value As Color)
		  Dim RedHex As Text = Value.Red.ToHex(2)
		  Dim GreenHex As Text = Value.Green.ToHex(2)
		  Dim BlueHex As Text = Value.Blue.ToHex(2)
		  Dim AlphaHex As Text = Value.Alpha.ToHex(2)
		  
		  Self.BeginTransaction()
		  Self.mValues.Value(Key) = RedHex + GreenHex + BlueHex + AlphaHex
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ColorValue(Key As Text, Default As Color) As Color
		  If Not Self.mValues.HasKey(Key) Then
		    Return Default
		  End If
		  
		  Dim Value As Auto = Self.mValues.Value(Key)
		  Dim Info As Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType(Value)
		  If Info.FullName <> "Text" Then
		    Return Default
		  End If
		  
		  Dim TextValue As Text = Value
		  If TextValue.Length < 8 Then
		    Return Default
		  End If
		  
		  Dim RedHex As Text = TextValue.Mid(0, 2)
		  Dim GreenHex As Text = TextValue.Mid(2, 2)
		  Dim BlueHex As Text = TextValue.Mid(4, 2)
		  Dim AlphaHex As Text = TextValue.Mid(6, 2)
		  
		  Return Color.RGBA(Integer.FromHex(RedHex), Integer.FromHex(GreenHex), Integer.FromHex(BlueHex), Integer.FromHex(AlphaHex))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Commit()
		  Self.mTransactionLevel = Self.mTransactionLevel - 1
		  
		  If Self.mTransactionLevel = 0 Then
		    Self.mSavedValues = Nil
		    Self.Write()
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Sub Constructor(File As Global.FolderItem)
		  Self.mFile = File
		  
		  If Self.mFile.Exists Then
		    Dim Stream As TextInputStream = TextInputStream.Open(Self.mFile)
		    Dim Contents As String = Stream.ReadAll(Encodings.UTF8)
		    Stream.Close
		    
		    Self.Constructor(Contents.ToText)
		  Else
		    Self.Constructor("")
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Contents As Text)
		  If Contents <> "" Then
		    Try
		      Self.mValues = Xojo.Data.ParseJSON(Contents)
		    Catch Err As RuntimeException
		      Self.mValues = New Xojo.Core.Dictionary
		    End Try
		    Self.mValues.Value("Existing User") = True
		  Else
		    Self.mValues = New Xojo.Core.Dictionary
		    Self.mValues.Value("Existing User") = False
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, CompatibilityFlags = (TargetIOS and (Target32Bit or Target64Bit))
		Sub Constructor(File As Xojo.IO.FolderItem)
		  Self.mFile = File
		  
		  If Self.mFile.Exists Then
		    Dim Stream As Xojo.IO.TextInputStream = Xojo.IO.TextInputStream.Open(Self.mFile, Xojo.Core.TextEncoding.UTF8)
		    Dim Contents As Text = Stream.ReadAll
		    Stream.Close
		    
		    Self.Constructor(Contents)
		  Else
		    Self.Constructor("")
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function DecodeHex(Source As Text) As Xojo.Core.MemoryBlock
		  Dim Bytes() As UInt8
		  For I As Integer = 0 To Source.Length - 2 Step 2
		    Dim Value As UInt8 = UInt8.FromHex(Source.Mid(I, 2))
		    Bytes.Append(Value)
		  Next
		  Return New Xojo.Core.MemoryBlock(Bytes)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DictionaryValue(Key As Text, Default As Xojo.Core.Dictionary = Nil) As Xojo.Core.Dictionary
		  If Not Self.mValues.HasKey(Key) Then
		    Return Default
		  End If
		  
		  Dim Value As Auto = Self.mValues.Value(Key)
		  Dim Info As Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType(Value)
		  If Info.FullName <> "Xojo.Core.Dictionary" Then
		    Return Default
		  End If
		  
		  Return Self.CloneDictionary(Value)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DictionaryValue(Key As Text, Assigns Value As Xojo.Core.Dictionary)
		  Self.BeginTransaction()
		  Self.mValues.Value(Key) = Self.CloneDictionary(Value)
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DoubleValue(Key As Text, Assigns Value As Boolean)
		  Self.BeginTransaction()
		  Self.mValues.Value(Key) = Value
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DoubleValue(Key As Text, Default As Double = 0) As Double
		  If Not Self.mValues.HasKey(Key) Then
		    Return Default
		  End If
		  
		  Dim Value As Auto = Self.mValues.Value(Key)
		  Dim Info As Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType(Value)
		  If Info.FullName <> "Double" Then
		    Return Default
		  End If
		  
		  Return Value
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function EncodeHex(Block As Xojo.Core.MemoryBlock) As Text
		  Dim Chars() As Text
		  For I As Integer = 0 To Block.Size - 1
		    Dim Value As UInt8 = Block.UInt8Value(I)
		    Chars.Append(Value.ToHex(2))
		  Next
		  Return Chars.Join("")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IntegerValue(Key As Text, Default As Int32 = 0) As Int32
		  If Not Self.mValues.HasKey(Key) Then
		    Return Default
		  End If
		  
		  Dim Value As Auto = Self.mValues.Value(Key)
		  Dim Info As Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType(Value)
		  If Info.FullName <> "Int32" Then
		    Return Default
		  End If
		  
		  Return Value
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub IntegerValue(Key As Text, Assigns Value As Int32)
		  Self.BeginTransaction()
		  Self.mValues.Value(Key) = Value
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PointValue(Key As Text, Default As Xojo.Core.Point = Nil) As Xojo.Core.Point
		  If Not Self.mValues.HasKey(Key) Then
		    Return Default
		  End If
		  
		  Dim Value As Auto = Self.mValues.Value(Key)
		  Dim Info As Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType(Value)
		  If Info.FullName <> "Xojo.Core.Dictionary" Then
		    Return Default
		  End If
		  
		  Dim Dict As Xojo.Core.Dictionary = Value
		  Return New Xojo.Core.Point(Dict.Value("Left"), Dict.Value("Top"))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PointValue(Key As Text, Assigns Value As Xojo.Core.Point)
		  Dim Dict As New Xojo.Core.Dictionary
		  Dict.Value("Left") = Value.X
		  Dict.Value("Top") = Value.Y
		  
		  Self.BeginTransaction()
		  Self.mValues.Value(Key) = Dict
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function RectValue(Key As Text, Default As Xojo.Core.Rect = Nil) As Xojo.Core.Rect
		  If Not Self.mValues.HasKey(Key) Then
		    Return Default
		  End If
		  
		  Dim Value As Auto = Self.mValues.Value(Key)
		  Dim Info As Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType(Value)
		  If Info.FullName <> "Xojo.Core.Dictionary" Then
		    Return Default
		  End If
		  
		  Dim Dict As Xojo.Core.Dictionary = Value
		  Return New Xojo.Core.Rect(Dict.Value("Left"), Dict.Value("Top"), Dict.Value("Width"), Dict.Value("Height"))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RectValue(Key As Text, Assigns Value As Xojo.Core.Rect)
		  Dim Dict As New Xojo.Core.Dictionary
		  Dict.Value("Left") = Value.Left
		  Dict.Value("Top") = Value.Top
		  Dict.Value("Width") = Value.Width
		  Dict.Value("Height") = Value.Height
		  
		  Self.BeginTransaction()
		  Self.mValues.Value(Key) = Dict
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Rollback()
		  Self.mTransactionLevel = Self.mTransactionLevel - 1
		  
		  If Self.mTransactionLevel = 0 Then
		    Self.mValues = Self.mSavedValues
		    Self.mSavedValues = Nil
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SizeValue(Key As Text, Default As Xojo.Core.Size = Nil) As Xojo.Core.Size
		  If Not Self.mValues.HasKey(Key) Then
		    Return Default
		  End If
		  
		  Dim Value As Auto = Self.mValues.Value(Key)
		  Dim Info As Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType(Value)
		  If Info.FullName <> "Xojo.Core.Dictionary" Then
		    Return Default
		  End If
		  
		  Dim Dict As Xojo.Core.Dictionary = Value
		  Return New Xojo.Core.Size(Dict.Value("Width"), Dict.Value("Height"))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SizeValue(Key As Text, Assigns Value As Xojo.Core.Size)
		  Dim Dict As New Xojo.Core.Dictionary
		  Dict.Value("Width") = Value.Width
		  Dict.Value("Height") = Value.Height
		  
		  Self.BeginTransaction()
		  Self.mValues.Value(Key) = Dict
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TextValue(Key As Text, Default As Text = "") As Text
		  If Not Self.mValues.HasKey(Key) Then
		    Return Default
		  End If
		  
		  Dim Value As Auto = Self.mValues.Value(Key)
		  Dim Info As Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType(Value)
		  If Info.FullName <> "Text" Then
		    Return Default
		  End If
		  
		  Return Value
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub TextValue(Key As Text, Assigns Value As Text)
		  Self.BeginTransaction()
		  Self.mValues.Value(Key) = Value
		  Self.Commit()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Write()
		  Dim Writer As New Beacon.JSONWriter(Self.mValues, Self.mFile)
		  Writer.Run
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Private mFile As Global.FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21, CompatibilityFlags = (TargetIOS and (Target32Bit or Target64Bit))
		Private mFile As Xojo.IO.FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSavedValues As Xojo.Core.Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTransactionLevel As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mValues As Xojo.Core.Dictionary
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
