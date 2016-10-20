#tag Class
Protected Class Preset
Implements Beacon.Countable
	#tag Method, Flags = &h0
		Sub Constructor()
		  Self.mLabel = "Untitled Preset"
		  Self.mGrouping = "Miscellaneous"
		  Self.mMinItems = 1
		  Self.mMaxItems = 3
		  Self.mWeight = 1
		  
		  Self.mQualityModifierStandard = 0
		  Self.mQualityModifierBonus = 3
		  Self.mQualityModifierCave = 6
		  Self.mQualityModifierSea = 6
		  
		  Self.mQuantityMultiplierStandard = 1
		  Self.mQuantityMultiplierBonus = 2
		  Self.mQuantityMultiplierCave = 1
		  Self.mQuantityMultiplierSea = 1
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Source As Beacon.Preset)
		  Self.mLabel = Source.mLabel
		  Self.mGrouping = Source.mGrouping
		  Self.mMinItems = Source.mMinItems
		  Self.mMaxItems = Source.mMaxItems
		  Self.mWeight = Source.mWeight
		  
		  Self.mQualityModifierStandard = Source.mQualityModifierStandard
		  Self.mQualityModifierBonus = Source.mQualityModifierBonus
		  Self.mQualityModifierCave = Source.mQualityModifierCave
		  Self.mQualityModifierSea = Source.mQualityModifierSea
		  
		  Self.mQuantityMultiplierStandard = Source.mQuantityMultiplierStandard
		  Self.mQuantityMultiplierBonus = Source.mQuantityMultiplierBonus
		  Self.mQuantityMultiplierCave = Source.mQuantityMultiplierCave
		  Self.mQuantityMultiplierSea = Source.mQuantityMultiplierSea
		  
		  Redim Self.mContents(UBound(Source.mContents))
		  For I As Integer = 0 To UBound(Self.mContents)
		    Self.mContents(I) = New Beacon.PresetEntry(Source.mContents(I))
		  Next
		  
		  Self.mPresetID = Source.mPresetID
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  Return UBound(Self.mContents) + 1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Entry(Index As Integer) As Beacon.PresetEntry
		  Return New Beacon.PresetEntry(Self.mContents(Index))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Shared Function FromDictionary(Dict As Xojo.Core.Dictionary) As Beacon.Preset
		  Dim Preset As New Beacon.Preset
		  If Dict.HasKey("ID") Then
		    // Don't use lookup here to prevent creating the UUID unless necessary
		    Preset.mPresetID = Dict.Value("ID")
		  End If
		  Preset.mLabel = Dict.Lookup("Label", Preset.Label)
		  Preset.mGrouping = Dict.Lookup("Grouping", Preset.Grouping)
		  Preset.mMinItems = Dict.Lookup("Min", Preset.MinItems)
		  Preset.mMaxItems = Dict.Lookup("Max", Preset.MaxItems)
		  Preset.mWeight = Dict.Lookup("Weight", Preset.Weight)
		  
		  Dim Multipliers As New Beacon.Range(1, 1)
		  Dim Contents As Xojo.Core.Dictionary = Dict.Lookup("Contents", Nil)
		  If Contents <> Nil Then
		    For Each Set As Xojo.Core.DictionaryEntry In Contents
		      Dim ValidForIsland As Boolean = (Set.Key = "Common" Or Set.Key = "Island")
		      Dim ValidForScorched As Boolean = (Set.Key = "Common" Or Set.Key = "Scorched")
		      Dim Items() As Auto = Set.Value
		      For Each Item As Xojo.Core.Dictionary In Items
		        Dim Entry As Beacon.SetEntry = Beacon.SetEntry.Import(Item, Multipliers)
		        If Entry <> Nil Then
		          Dim Child As New Beacon.PresetEntry(Entry)
		          Child.ValidForIsland = ValidForIsland
		          Child.ValidForScorched = ValidForScorched
		          Preset.mContents.Append(Child)
		        End If
		      Next
		    Next
		  End If
		  
		  Dim Modifiers As Xojo.Core.Dictionary = Dict.Lookup("Modifiers", Nil)
		  If Modifiers <> Nil Then
		    For Each Set As Xojo.Core.DictionaryEntry In Modifiers
		      Dim Item As Xojo.Core.Dictionary = Set.Value
		      
		      Select Case Set.Key
		      Case "Standard"
		        Preset.mQualityModifierStandard = Item.Lookup("Quality", Preset.QualityModifier(Beacon.LootSource.Kinds.Standard))
		        Preset.mQuantityMultiplierStandard = Item.Lookup("Quantity", Preset.QuantityMultiplier(Beacon.LootSource.Kinds.Standard))
		      Case "Bonus"
		        Preset.mQualityModifierBonus = Item.Lookup("Quality", Preset.QualityModifier(Beacon.LootSource.Kinds.Bonus))
		        Preset.mQuantityMultiplierBonus = Item.Lookup("Quantity", Preset.QuantityMultiplier(Beacon.LootSource.Kinds.Bonus))
		      Case "Cave"
		        Preset.mQualityModifierCave = Item.Lookup("Quality", Preset.QualityModifier(Beacon.LootSource.Kinds.Cave))
		        Preset.mQuantityMultiplierCave = Item.Lookup("Quantity", Preset.QuantityMultiplier(Beacon.LootSource.Kinds.Cave))
		      Case "Sea"
		        Preset.mQualityModifierSea = Item.Lookup("Quality", Preset.QualityModifier(Beacon.LootSource.Kinds.Sea))
		        Preset.mQuantityMultiplierSea = Item.Lookup("Quantity", Preset.QuantityMultiplier(Beacon.LootSource.Kinds.Sea))
		      End Select
		    Next
		  End If
		  
		  Return New Beacon.Preset(Preset)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Shared Function FromFile(File As Xojo.IO.FolderItem) As Beacon.Preset
		  If File = Nil Or File.Exists = False Or File.IsFolder = True Then
		    Return Nil
		  End If
		  
		  Try
		    Dim Stream As Xojo.IO.BinaryStream = Xojo.IO.BinaryStream.Open(File, Xojo.IO.BinaryStream.LockModes.Read)
		    Dim Bytes As Xojo.Core.MemoryBlock = Stream.Read(Stream.Length)
		    Stream.Close
		    
		    Dim TextContents As Text = Xojo.Core.TextEncoding.UTF8.ConvertDataToText(Bytes)
		    
		    Dim Dict As Xojo.Core.Dictionary = Xojo.Data.ParseJSON(TextContents)
		    Return Beacon.Preset.FromDictionary(Dict)
		  Catch Err As Xojo.IO.IOException
		    Return Nil
		  Catch Err As Xojo.Data.InvalidJSONException
		    Return Nil
		  Catch Err As TypeMismatchException
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetIterator() As Xojo.Core.Iterator
		  Return New Beacon.PresetIterator(Self)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Grouping() As Text
		  Return Self.mGrouping
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IndexOf(Entry As Beacon.PresetEntry) As Integer
		  For I As Integer = 0 To UBound(Self.mContents)
		    If Self.mContents(I) = Entry Then
		      Return I
		    End If
		  Next
		  Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsCustom() As Boolean
		  Return Beacon.Data.IsPresetCustom(Self)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Label() As Text
		  Return Self.mLabel
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MaxItems() As Integer
		  Return Self.mMaxItems
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MinItems() As Integer
		  Return Self.mMinItems
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Operator_Subscript(Index As Integer) As Beacon.PresetEntry
		  Return New Beacon.PresetEntry(Self.mContents(Index))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PresetID() As Text
		  If Self.mPresetID = "" Then
		    Self.mPresetID = Beacon.CreateUUID
		  End If
		  Return Self.mPresetID
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function QualityModifier(Kind As Beacon.LootSource.Kinds) As Integer
		  Select Case Kind
		  Case Beacon.LootSource.Kinds.Standard
		    Return Self.mQualityModifierStandard
		  Case Beacon.LootSource.Kinds.Bonus
		    Return Self.mQualityModifierBonus
		  Case Beacon.LootSource.Kinds.Cave
		    Return Self.mQualityModifierCave
		  Case Beacon.LootSource.Kinds.Sea
		    Return Self.mQualityModifierSea
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function QuantityMultiplier(Kind As Beacon.LootSource.Kinds) As Double
		  Select Case Kind
		  Case Beacon.LootSource.Kinds.Standard
		    Return Self.mQuantityMultiplierStandard
		  Case Beacon.LootSource.Kinds.Bonus
		    Return Self.mQuantityMultiplierBonus
		  Case Beacon.LootSource.Kinds.Cave
		    Return Self.mQuantityMultiplierCave
		  Case Beacon.LootSource.Kinds.Sea
		    Return Self.mQuantityMultiplierSea
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToDictionary() As Xojo.Core.Dictionary
		  Dim CommonItems(), IslandItems(), ScorchedItems() As Xojo.Core.Dictionary
		  For Each Entry As Beacon.PresetEntry In Self.mContents
		    Dim Exported As Xojo.Core.Dictionary = Entry.Export
		    If Entry.ValidForIsland And Entry.ValidForScorched Then
		      CommonItems.Append(Exported)
		    ElseIf Entry.ValidForIsland Then
		      IslandItems.Append(Exported)
		    ElseIf Entry.ValidForScorched Then
		      ScorchedItems.Append(Exported)
		    End If
		  Next
		  
		  Dim Contents As New Xojo.Core.Dictionary
		  Contents.Value("Common") = CommonItems
		  Contents.Value("Island") = IslandItems
		  Contents.Value("Scorched") = ScorchedItems
		  
		  Dim StandardModifiers As New Xojo.Core.Dictionary
		  StandardModifiers.Value("Quality") = Self.mQualityModifierStandard
		  StandardModifiers.Value("Quantity") = Self.mQuantityMultiplierStandard
		  
		  Dim BonusModifiers As New Xojo.Core.Dictionary
		  BonusModifiers.Value("Quality") = Self.mQualityModifierBonus
		  BonusModifiers.Value("Quantity") = Self.mQuantityMultiplierBonus
		  
		  Dim CaveModifiers As New Xojo.Core.Dictionary
		  CaveModifiers.Value("Quality") = Self.mQualityModifierCave
		  CaveModifiers.Value("Quantity") = Self.mQuantityMultiplierCave
		  
		  Dim SeaModifiers As New Xojo.Core.Dictionary
		  SeaModifiers.Value("Quality") = Self.mQualityModifierSea
		  SeaModifiers.Value("Quantity") = Self.mQuantityMultiplierSea
		  
		  Dim Modifiers As New Xojo.Core.Dictionary
		  Modifiers.Value("Standard") = StandardModifiers
		  Modifiers.Value("Bonus") = BonusModifiers
		  Modifiers.Value("Cave") = CaveModifiers
		  Modifiers.Value("Sea") = SeaModifiers
		  
		  Dim Dict As New Xojo.Core.Dictionary
		  Dict.Value("ID") = Self.mPresetID
		  Dict.Value("Label") = Self.mLabel
		  Dict.Value("Grouping") = Self.mGrouping
		  Dict.Value("Min") = Self.mMinItems
		  Dict.Value("Max") = Self.mMaxItems
		  Dict.Value("Weight") = Self.mWeight
		  Dict.Value("Contents") = Contents
		  Dict.Value("Modifiers") = Modifiers
		  Return Dict
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ToFile(File As Xojo.IO.FolderItem)
		  Dim Contents As Text = Xojo.Data.GenerateJSON(Self.ToDictionary)
		  Dim Bytes As Xojo.Core.MemoryBlock = Xojo.Core.TextEncoding.UTF8.ConvertTextToData(Contents)
		  Dim Stream As Xojo.IO.BinaryStream = Xojo.IO.BinaryStream.Open(File, Xojo.IO.BinaryStream.LockModes.Write)
		  Stream.Write(Bytes)
		  Stream.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ValidForIsland() As Boolean
		  For Each Entry As Beacon.PresetEntry In Self.mContents
		    If Entry.ValidForIsland Then
		      Return True
		    End If
		  Next
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ValidForScorched() As Boolean
		  For Each Entry As Beacon.PresetEntry In Self.mContents
		    If Entry.ValidForScorched Then
		      Return True
		    End If
		  Next
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Weight() As Double
		  Return Self.mWeight
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected mContents() As Beacon.PresetEntry
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mGrouping As Text
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLabel As Text
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mMaxItems As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mMinItems As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPresetID As Text
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mQualityModifierBonus As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mQualityModifierCave As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mQualityModifierSea As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mQualityModifierStandard As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mQuantityMultiplierBonus As Double
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mQuantityMultiplierCave As Double
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mQuantityMultiplierSea As Double
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mQuantityMultiplierStandard As Double
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mWeight As Double
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
