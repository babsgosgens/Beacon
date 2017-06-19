#tag Class
Protected Class LocalData
Implements Beacon.DataSource
	#tag Method, Flags = &h21
		Private Sub BeginTransaction()
		  Self.mLock.Enter
		  
		  If UBound(Self.mTransactions) = -1 Then
		    Self.mTransactions.Insert(0, "")
		    Self.SQLExecute("BEGIN TRANSACTION;")
		  Else
		    Dim Savepoint As String = "Savepoint_" + EncodeHex(Crypto.GenerateRandomBytes(4))
		    Self.mTransactions.Insert(0, Savepoint)
		    Self.SQLExecute("SAVEPOINT " + Savepoint + ";")
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub BuildSchema()
		  Self.SQLExecute("PRAGMA foreign_keys = ON;")
		  Self.SQLExecute("PRAGMA journal_mode = WAL;")
		  
		  Self.SQLExecute("CREATE TABLE loot_sources (class_string TEXT NOT NULL PRIMARY KEY, label TEXT NOT NULL, kind TEXT NOT NULL, engram_mask INTEGER NOT NULL, multiplier_min REAL NOT NULL, multiplier_max REAL NOT NULL, uicolor TEXT NOT NULL, sort INTEGER NOT NULL UNIQUE);")
		  Self.SQLExecute("CREATE TABLE engrams (path TEXT NOT NULL PRIMARY KEY, class_string TEXT NOT NULL, label TEXT NOT NULL, availability INTEGER NOT NULL, can_blueprint INTEGER NOT NULL, built_in INTEGER NOT NULL);")
		  Self.SQLExecute("CREATE TABLE variables (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL);")
		  Self.SQLExecute("CREATE TABLE presets (preset_id TEXT NOT NULL PRIMARY KEY, label TEXT NOT NULL, contents TEXT NOT NULL);")
		  Self.SQLExecute("CREATE INDEX engrams_class_string_idx ON engrams(class_string);")
		  
		  Self.mBase.UserVersion = Self.SchemaVersion
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function CheckError(SQLString As String) As RuntimeException
		  If Self.mBase.Error Then
		    Dim Err As New UnsupportedOperationException
		    Err.Message = Self.mBase.ErrorMessage + EndOfLine + SQLString
		    Return Err
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CheckForEngramUpdates()
		  Dim CheckURL As Text = Self.ClassesURL()
		  App.Log("Checking for engram updates from " + CheckURL)
		  
		  If Self.mUpdater = Nil Then
		    Self.mUpdater = New Xojo.Net.HTTPSocket
		    Self.mUpdater.ValidateCertificates = True
		    AddHandler Self.mUpdater.PageReceived, WeakAddressOf Self.mUpdater_PageReceived
		    AddHandler Self.mUpdater.Error, WeakAddressOf Self.mUpdater_Error
		  End If
		  Self.mUpdater.Send("GET", CheckURL)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ClassesURL() As Text
		  Dim LastSync As String = Self.Variable("last_sync")
		  Dim CheckURL As Text = Beacon.WebURL("/download/classes.php?version=" + App.NonReleaseVersion.ToText)
		  If LastSync <> "" Then
		    CheckURL = CheckURL + "&changes_since=" + EncodeURLComponent(LastSync).ToText
		  End If
		  Return CheckURL
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Commit()
		  If UBound(Self.mTransactions) = -1 Then
		    Return
		  End If
		  
		  Dim Savepoint As String = Self.mTransactions(0)
		  Self.mTransactions.Remove(0)
		  
		  If Savepoint = "" Then
		    Self.SQLExecute("COMMIT TRANSACTION;")
		  Else
		    Self.SQLExecute("RELEASE SAVEPOINT " + Savepoint + ";")
		  End If
		  
		  Self.mLock.Leave
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  Self.mEngramCache = New Dictionary
		  Self.mLock = New CriticalSection
		  
		  Dim LegacyFile As FolderItem = App.ApplicationSupport.Child("Beacon.sqlite")
		  If LegacyFile.Exists Then
		    LegacyFile.Delete
		  End If
		  
		  Self.mBase = New SQLiteDatabase
		  Self.mBase.DatabaseFile = App.ApplicationSupport.Child("Library.sqlite")
		  
		  Dim FirstBuild As Boolean
		  If Self.mBase.DatabaseFile.Exists Then
		    If Not Self.mBase.Connect Then
		      Return
		    End If
		    FirstBuild = False
		  Else
		    If Not Self.mBase.CreateDatabaseFile Then
		      Return
		    End If
		    FirstBuild = True
		  End If
		  
		  Dim CurrentSchemaVersion As Integer = Self.mBase.UserVersion
		  If CurrentSchemaVersion <> Self.SchemaVersion Then
		    Self.mBase.Close
		    Self.mBase.DatabaseFile.MoveFileTo(App.ApplicationSupport.Child("Library " + Str(CurrentSchemaVersion, "-0") + ".sqlite"))
		    
		    Self.mBase = New SQLiteDatabase
		    Self.mBase.DatabaseFile = App.ApplicationSupport.Child("Library.sqlite")
		    Call Self.mBase.CreateDatabaseFile
		    Self.BuildSchema()
		  End If
		  
		  If CurrentSchemaVersion < Self.SchemaVersion Then
		    Self.MigrateData(App.ApplicationSupport.Child("Library " + Str(CurrentSchemaVersion, "-0") + ".sqlite"), CurrentSchemaVersion)
		  End If
		  
		  Self.CheckForEngramUpdates()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function CustomPresetsFolder() As FolderItem
		  Dim SupportFolder As FolderItem = App.ApplicationSupport
		  Dim PresetsFolder As FolderItem = SupportFolder.Child("Presets")
		  If PresetsFolder.Exists Then
		    If Not PresetsFolder.Directory Then
		      PresetsFolder.Delete
		      PresetsFolder.CreateAsFolder
		    End If
		  Else
		    PresetsFolder.CreateAsFolder
		  End If
		  Return PresetsFolder
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DeleteEngram(Engram As Beacon.Engram) As Boolean
		  Try
		    Dim Results As RecordSet = Self.SQLSelect("SELECT built_in FROM engrams WHERE LOWER(path) = LOWER(?1);", Engram.Path)
		    If Results.RecordCount = 1 And Results.Field("built_in").BooleanValue = True Then
		      Return False
		    End If
		    
		    Self.BeginTransaction()
		    Self.SQLExecute("DELETE FROM engrams WHERE LOWER(path) = LOWER(?1) AND built_in = 0;", Engram.Path)
		    Self.Commit()
		    
		    Return True
		  Catch Err As UnsupportedOperationException
		    Return False
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FileForCustomPreset(Preset As Beacon.Preset) As FolderItem
		  Return Self.CustomPresetsFolder.Child(Preset.PresetID + BeaconFileTypes.BeaconPreset.PrimaryExtension)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetCustomEngrams() As Beacon.Engram()
		  Try
		    Dim RS As RecordSet = Self.SQLSelect("SELECT path, label, availability, can_blueprint FROM engrams WHERE built_in = 0;")
		    If RS.RecordCount = 0 Then
		      Return Nil
		    End If
		    
		    Dim Engrams() As Beacon.Engram = Self.RecordSetToEngram(RS)
		    For Each Engram As Beacon.Engram In Engrams
		      Self.mEngramCache.Value(Engram.Path) = Engram
		    Next
		    Return Engrams
		  Catch Err As UnsupportedOperationException
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetEngramByClass(ClassString As Text) As Beacon.Engram
		  // Part of the Beacon.DataSource interface.
		  
		  Try
		    If ClassString.Length < 2 Or ClassString.Right(2) <> "_C" Then
		      ClassString = ClassString + "_C"
		    End If
		    
		    Dim RS As RecordSet = Self.SQLSelect("SELECT path, label, availability, can_blueprint FROM engrams WHERE LOWER(class_string) = LOWER(?1);", ClassString)
		    If RS.RecordCount = 0 Then
		      Return Nil
		    End If
		    
		    Dim Engrams() As Beacon.Engram = Self.RecordSetToEngram(RS)
		    For Each Engram As Beacon.Engram In Engrams
		      Self.mEngramCache.Value(Engram.Path) = Engram
		    Next
		    Return Engrams(0)
		  Catch Err As UnsupportedOperationException
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetEngramByPath(Path As Text) As Beacon.Engram
		  // Part of the Beacon.DataSource interface.
		  
		  If Self.mEngramCache.HasKey(Path) Then
		    Return Self.mEngramCache.Value(Path)
		  End If
		  
		  Try
		    Dim RS As RecordSet = Self.SQLSelect("SELECT path, label, availability, can_blueprint FROM engrams WHERE LOWER(path) = LOWER(?1);", Path)
		    If RS.RecordCount = 0 Then
		      Return Nil
		    End If
		    
		    Dim Engrams() As Beacon.Engram = Self.RecordSetToEngram(RS)
		    For Each Engram As Beacon.Engram In Engrams
		      Self.mEngramCache.Value(Engram.Path) = Engram
		    Next
		    Return Engrams(0)
		  Catch Err As UnsupportedOperationException
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetLootSource(ClassString As Text) As Beacon.LootSource
		  // Part of the Beacon.DataSource interface.
		  
		  Try
		    Dim Results As RecordSet = Self.SQLSelect("SELECT class_string, label, kind, engram_mask, multiplier_min, multiplier_max, uicolor, sort FROM loot_sources WHERE LOWER(class_string) = LOWER(?1);", ClassString)
		    If Results.RecordCount = 0 Then
		      Return Nil
		    End If
		    
		    Dim Sources() As Beacon.LootSource = Self.RecordSetToLootSource(Results)
		    Return Sources(0)
		  Catch Err As UnsupportedOperationException
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Shared Function IconForLootSource(Source As Beacon.LootSource, HighlightColor As Color) As Picture
		  Const Size = 24
		  
		  Dim HighlightMask As Picture
		  Dim ColorMask As Picture
		  
		  Select Case Source.Kind
		  Case Beacon.LootSource.Kinds.Bonus
		    HighlightMask = IconLootBonus
		    ColorMask = IconLootBonusColorMask
		  Case Beacon.LootSource.Kinds.Cave
		    HighlightMask = IconLootCave
		    ColorMask = IconLootCaveColorMask
		  Case Beacon.LootSource.Kinds.Sea
		    HighlightMask = IconLootSea
		    ColorMask = IconLootSeaColorMask
		  Case Beacon.LootSource.Kinds.BossSpider
		    HighlightMask = IconLootSpider
		    ColorMask = IconLootSpiderColorMask
		  Case Beacon.LootSource.Kinds.BossGorilla
		    HighlightMask = IconLootGorilla
		    ColorMask = IconLootGorillaColorMask
		  Case Beacon.LootSource.Kinds.BossDragon
		    HighlightMask = IconLootDragon
		    ColorMask = IconLootDragonColorMask
		  Case Beacon.LootSource.Kinds.BossManticore
		    HighlightMask = IconLootManticore
		    ColorMask = IconLootManticoreColorMask
		  Else
		    HighlightMask = IconLootStandard
		    ColorMask = IconLootStandardColorMask
		  End Select
		  
		  Dim HighlightOpacity As Integer = HighlightColor.Alpha
		  Dim FillOpacity As Integer = Source.UIColor.Alpha
		  
		  Dim Bitmaps() As Picture
		  For Factor As Integer = 1 To 3
		    Dim HighlightRep As Picture = HighlightMask.BestRepresentation(Size, Size, Factor)
		    Dim ColorRep As Picture = ColorMask.BestRepresentation(Size, Size, Factor)
		    
		    Dim Highlight As New Picture(Size * Factor, Size * Factor, 32)
		    Highlight.VerticalResolution = 72 * Factor
		    Highlight.HorizontalResolution = 72 * Factor
		    Highlight.Graphics.ForeColor = RGB(HighlightColor.Red, HighlightColor.Green, HighlightColor.Blue)
		    Highlight.Graphics.FillRect(0, 0, Highlight.Width, Highlight.Height)
		    Highlight.Mask.Graphics.DrawPicture(HighlightRep, 0, 0, Highlight.Width, Highlight.Height, 0, 0, HighlightRep.Width, HighlightRep.Height)
		    Highlight.Mask.Graphics.ForeColor = RGB(255, 255, 255, 255 - HighlightOpacity)
		    Highlight.Mask.Graphics.FillRect(0, 0, Highlight.Width, Highlight.Height)
		    
		    Dim Fill As New Picture(Size * Factor, Size * Factor, 32)
		    Fill.VerticalResolution = 72 * Factor
		    Fill.HorizontalResolution = 72 * Factor
		    Fill.Graphics.ForeColor = Source.UIColor
		    Fill.Graphics.FillRect(0, 0, Fill.Width, Fill.Height)
		    Fill.Mask.Graphics.DrawPicture(ColorRep, 0, 0, Fill.Width, Fill.Height, 0, 0, ColorRep.Width, ColorRep.Height)
		    Fill.Mask.Graphics.ForeColor = RGB(255, 255, 255, 255 - FillOpacity)
		    Fill.Mask.Graphics.FillRect(0, 0, Fill.Width, Fill.Height)
		    
		    Dim Combined As New Picture(Size * Factor, Size * Factor)
		    Combined.VerticalResolution = 72 * Factor
		    Combined.HorizontalResolution = 72 * Factor
		    Combined.Graphics.DrawPicture(Highlight, 0, 0, Combined.Width, Combined.Height, 0, 0, Highlight.Width, Highlight.Height)
		    Combined.Graphics.DrawPicture(Fill, 0, 0, Combined.Width, Combined.Height, 0, 0, Fill.Width, Fill.Height)
		    
		    Bitmaps.Append(Combined)
		  Next
		  Return New Picture(Size, Size, Bitmaps)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Import(Content As Text) As Boolean
		  Dim ChangeDict As Xojo.Core.Dictionary = Xojo.Data.ParseJSON(Content)
		  
		  Dim RequiredKeys() As Text = Array("loot_sources", "engrams", "presets", "timestamp", "is_full", "beacon_version")
		  For Each RequiredKey As Text In RequiredKeys
		    If Not ChangeDict.HasKey(RequiredKey) Then
		      App.Log("Cannot import classes because key '" + RequiredKey + "' is missing.")
		      Return False
		    End If
		  Next
		  
		  Dim FileVersion As Integer = ChangeDict.Value("beacon_version")
		  If FileVersion < 2 Then
		    App.Log("Cannot import classes because file format is too old.")
		    return False
		  End If
		  
		  Try
		    Self.BeginTransaction()
		    
		    Dim ShouldTruncate As Boolean = ChangeDict.Value("is_full") = 1
		    If ShouldTruncate Then
		      Self.SQLExecute("DELETE FROM loot_sources;")
		      Self.SQLExecute("DELETE FROM engrams WHERE builtin = 1;")
		      Self.SQLExecute("DELETE FROM presets;")
		    End If
		    
		    Dim SourcesDict As Xojo.Core.Dictionary = ChangeDict.Value("loot_sources")
		    Dim EngramsDict As Xojo.Core.Dictionary = ChangeDict.Value("engrams")
		    Dim PresetsDict As Xojo.Core.Dictionary = ChangeDict.Value("presets")
		    Dim LastSync As Text = ChangeDict.Value("timestamp")
		    
		    Dim SourceAdditions() As Auto = SourcesDict.Value("additions")
		    Dim SourceRemovals() As Auto = SourcesDict.Value("removals")
		    For Each ClassString As Text In SourceRemovals
		      Self.SQLExecute("DELETE FROM loot_sources WHERE LOWER(class_string) = LOWER(?1);", ClassString)
		    Next
		    For Each Dict As Xojo.Core.Dictionary In SourceAdditions
		      If Dict.HasKey("version") And Dict.Value("version") > App.NonReleaseVersion Then
		        Continue
		      End If
		      
		      Dim ClassString As Text = Dict.Value("class")
		      Dim Label As Text = Dict.Value("label")
		      Dim Kind As Text = Dict.Value("kind")
		      Dim Mask As Integer = Dict.Value("mask")
		      Dim MultMin As Double = Dict.Value("mult_min")
		      Dim MultMax As Double = Dict.Value("mult_max")
		      Dim UIColor As Text = Dict.Value("uicolor")
		      Dim SortValue As Integer = Dict.Value("sort")
		      
		      Self.SQLExecute("DELETE FROM loot_sources WHERE LOWER(class_string) = LOWER(?1);", ClassString)
		      Self.SQLExecute("INSERT INTO loot_sources (class_string, label, kind, engram_mask, multiplier_min, multiplier_max, uicolor, sort) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8);", ClassString, Label, Kind, Mask, MultMin, MultMax, UIColor, SortValue)
		    Next
		    
		    Dim EngramAdditions() As Auto = EngramsDict.Value("additions")
		    Dim EngramRemovals() As Auto = EngramsDict.Value("removed_paths")
		    For Each ClassString As Text In EngramRemovals
		      Self.SQLExecute("DELETE FROM engrams WHERE LOWER(path) = LOWER(?1) AND built_in = 1;", ClassString)
		    Next
		    For Each Dict As Xojo.Core.Dictionary In EngramAdditions
		      If Dict.HasKey("version") And Dict.Value("version") > App.NonReleaseVersion Then
		        Continue
		      End If
		      
		      Dim Path As Text = Dict.Value("path")
		      Dim ClassString As Text = Dict.Value("class")
		      Dim Label As Text = Dict.Value("label")
		      Dim Availability As Integer = Dict.Value("availability")
		      Dim CanBlueprint As Boolean = (Dict.Value("blueprint") = 1)
		      
		      Self.SQLExecute("DELETE FROM engrams WHERE LOWER(path) = LOWER(?1);", Path)
		      Self.SQLExecute("INSERT INTO engrams (path, class_string, label, availability, can_blueprint, built_in) VALUES (?1, ?2, ?3, ?4, ?5, 1);", Path, ClassString, Label, Availability, CanBlueprint)
		    Next
		    
		    Dim PresetAdditions() As Auto = PresetsDict.Value("additions")
		    Dim PresetRemovals() As Auto = PresetsDict.Value("removals")
		    Dim ReloadPresets As Boolean = False
		    For Each PresetID As Text In PresetRemovals
		      Self.SQLExecute("DELETE FROM presets WHERE LOWER(preset_id) = LOWER(?1);", PresetID)
		      ReloadPresets = True
		    Next
		    For Each Dict As Xojo.Core.Dictionary In PresetAdditions
		      Dim PresetID As Text = Dict.Value("id")
		      Dim Label As Text = Dict.Value("label")
		      Dim Contents As Text = Dict.Value("contents")
		      Self.SQLExecute("DELETE FROM presets WHERE LOWER(preset_id) = LOWER(?1);", PresetID)
		      Self.SQLExecute("INSERT INTO presets (preset_id, label, contents) VALUES (?1, ?2, ?3);", PresetID, Label, Contents)
		      ReloadPresets = True
		    Next
		    
		    Self.Variable("last_sync") = LastSync
		    Self.Commit()
		    If ReloadPresets Then
		      Self.LoadPresets()
		    End If
		    
		    App.Log("Imported classes. Engrams date is " + LastSync)
		    
		    Return True
		  Catch Err As RuntimeException
		    Self.Rollback()
		    Return False
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ImportLocalClasses()
		  Dim File As FolderItem = App.ResourcesFolder.Child("Classes.json")
		  If File.Exists Then
		    Dim Stream As TextInputStream = TextInputStream.Open(File)
		    Dim Content As String = Stream.ReadAll(Encodings.UTF8)
		    Stream.Close
		    
		    Call Self.Import(Content.ToText)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsPresetCustom(Preset As Beacon.Preset) As Boolean
		  Dim File As FolderItem = Self.FileForCustomPreset(Preset)
		  Return File.Exists
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastSync() As Xojo.Core.Date
		  Dim LastSync As String = Self.Variable("last_sync")
		  If LastSync = "" Then
		    Return Nil
		  End If
		  
		  Dim Now As New Date
		  Dim TempDate As Xojo.Core.Date = Xojo.Core.Date.FromText(LastSync.ToText)
		  Return New Xojo.Core.Date(TempDate.SecondsFrom1970 + (Now.GMTOffset * 3600), New Xojo.Core.TimeZone("UTC"))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub LoadPresets()
		  Dim Presets As New Dictionary
		  
		  Dim BuiltInIDs() As Text
		  Dim Results As RecordSet = Self.SQLSelect("SELECT contents FROM presets")
		  While Not Results.EOF
		    Dim Dict As Xojo.Core.Dictionary = Xojo.Data.ParseJSON(Results.Field("contents").StringValue.ToText)
		    Dim Preset As Beacon.Preset = Beacon.Preset.FromDictionary(Dict)
		    If Preset <> Nil Then
		      Preset.Type = Beacon.Preset.Types.BuiltIn
		      Presets.Value(Preset.PresetID) = Preset
		      BuiltInIDs.Append(Preset.PresetID)
		    End If
		    Results.MoveNext
		  Wend
		  
		  Dim Folder As FolderItem = Self.CustomPresetsFolder
		  If Folder <> Nil Then
		    Dim Extension As String = BeaconFileTypes.BeaconPreset.PrimaryExtension
		    Dim ExtensionLength As Integer = Len(Extension)
		    
		    For I As Integer = 1 To Folder.Count
		      Dim File As FolderItem = Folder.Item(I)
		      If Right(File.Name, ExtensionLength) <> Extension Then
		        Continue For I
		      End If
		      
		      Dim Preset As Beacon.Preset = Beacon.Preset.FromFile(File)
		      If Preset <> Nil Then
		        Dim CorrectFile As FolderItem = Self.FileForCustomPreset(Preset)
		        If File.NativePath <> CorrectFile.NativePath Then
		          If Not CorrectFile.Exists Then
		            Self.SavePreset(Preset, False)
		          End If
		          File.Delete
		        End If
		        
		        Preset.Type = if(BuiltInIDs.IndexOf(Preset.PresetID) > -1, Beacon.Preset.Types.CustomizedBuiltIn, Beacon.Preset.Types.Custom)
		        Presets.Value(Preset.PresetID) = Preset
		      End If
		    Next
		  End If
		  
		  Redim Self.mPresets(Presets.Count - 1)
		  Dim Keys() As Variant = Presets.Keys
		  For I As Integer = 0 To UBound(Keys)
		    Self.mPresets(I) = Presets.Value(Keys(I))
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MigrateData(Source As FolderItem, FromSchemaVersion As Integer)
		  If Not Self.mBase.AttachDatabase(Source, "legacy") Then
		    App.Log("Unable to attach database " + Source.NativePath)
		    Return
		  End If
		  
		  Dim Commands() As String
		  If FromSchemaVersion = 0 Then
		  End If
		  
		  If UBound(Commands) > -1 Then
		    Self.BeginTransaction()
		    Try
		      For Each Command As String In Commands
		        Self.SQLExecute(Command)
		      Next
		    Catch Err As UnsupportedOperationException
		      Self.Rollback()
		      Self.mBase.DetachDatabase("legacy")
		      App.Log("Unable to migrate data: " + Err.Message)
		      Return
		    End Try
		    Self.Commit()
		  End If
		  
		  Self.mBase.DetachDatabase("legacy")
		  Source.Delete
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub mUpdater_Error(Sender As Xojo.Net.HTTPSocket, Error As RuntimeException)
		  #Pragma Unused Sender
		  
		  App.Log("Engram check error: " + Error.Reason)
		  Self.ImportLocalClasses()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub mUpdater_PageReceived(Sender As Xojo.Net.HTTPSocket, URL As Text, HTTPStatus As Integer, Content As Xojo.Core.MemoryBlock)
		  #Pragma Unused Sender
		  #Pragma Unused URL
		  
		  If HTTPStatus <> 200 Then
		    App.Log("Engram update returned HTTP " + Str(HTTPStatus, "-0"))
		    Self.ImportLocalClasses()
		    Return
		  End If
		  
		  Dim TextContent As Text = Xojo.Core.TextEncoding.UTF8.ConvertDataToText(Content)
		  Dim ExpectedHash As Text = Sender.ResponseHeader("Content-MD5")
		  Dim ComputedHash As Text = EncodeHex(Crypto.MD5(TextContent)).ToText
		  
		  If ComputedHash <> ExpectedHash Then
		    App.Log("Engram update hash mismatch. Expected " + ExpectedHash + ", computed " + ComputedHash + ".")
		    Return
		  End If
		  
		  Call Self.Import(TextContent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Presets() As Beacon.Preset()
		  Dim Results() As Beacon.Preset
		  For Each Preset As Beacon.Preset In Self.mPresets
		    Results.Append(New Beacon.Preset(Preset))
		  Next
		  Return Results
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function RecordSetToEngram(Results As RecordSet) As Beacon.Engram()
		  Dim Engrams() As Beacon.Engram
		  While Not Results.EOF
		    Dim Engram As New Beacon.MutableEngram(Results.Field("path").StringValue.ToText)
		    Engram.Label = Results.Field("label").StringValue.ToText
		    Engram.Availability = Results.Field("availability").IntegerValue
		    Engram.CanBeBlueprint = Results.Field("can_blueprint").BooleanValue
		    Engrams.Append(Engram)
		    Results.MoveNext
		  Wend
		  Return Engrams
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function RecordSetToLootSource(Results As RecordSet) As Beacon.LootSource()
		  Dim Sources() As Beacon.LootSource
		  While Not Results.EOF
		    Dim HexColor As String = Results.Field("uicolor").StringValue
		    Dim RedHex, GreenHex, BlueHex, AlphaHex As String = "00"
		    If Len(HexColor) = 3 Then
		      RedHex = Mid(HexColor, 1, 1) + Mid(HexColor, 1, 1)
		      GreenHex = Mid(HexColor, 2, 1) + Mid(HexColor, 2, 1)
		      BlueHex = Mid(HexColor, 3, 1) + Mid(HexColor, 3, 1)
		    ElseIf Len(HexColor) = 4 Then
		      RedHex = Mid(HexColor, 1, 1) + Mid(HexColor, 1, 1)
		      GreenHex = Mid(HexColor, 2, 1) + Mid(HexColor, 2, 1)
		      BlueHex = Mid(HexColor, 3, 1) + Mid(HexColor, 3, 1)
		      AlphaHex = Mid(HexColor, 4, 1) + Mid(HexColor, 4, 1)
		    ElseIf Len(HexColor) = 6 Then
		      RedHex = Mid(HexColor, 1, 2)
		      GreenHex = Mid(HexColor, 3, 2)
		      BlueHex = Mid(HexColor, 5, 2)
		    ElseIf Len(HexColor) = 8 Then
		      RedHex = Mid(HexColor, 1, 2)
		      GreenHex = Mid(HexColor, 3, 2)
		      BlueHex = Mid(HexColor, 5, 2)
		      AlphaHex = Mid(HexColor, 7, 2)
		    End If
		    
		    Dim Source As New Beacon.MutableLootSource(Results.Field("class_string").StringValue.ToText, True)
		    Source.Label = Results.Field("label").StringValue.ToText
		    Source.Kind = Beacon.LootSource.TextToKind(Results.Field("kind").StringValue.ToText)
		    Source.Package = Beacon.LootSource.IntegerToPackage(Results.Field("engram_mask").IntegerValue)
		    Source.Multipliers = New Beacon.Range(Results.Field("multiplier_min").DoubleValue, Results.Field("multiplier_max").DoubleValue)
		    Source.UIColor = RGB(Integer.FromHex(RedHex.ToText), Integer.FromHex(GreenHex.ToText), Integer.FromHex(BlueHex.ToText), Integer.FromHex(AlphaHex.ToText))
		    Source.SortValue = Results.Field("sort").IntegerValue
		    Sources.Append(New Beacon.LootSource(Source))
		    Results.MoveNext
		  Wend
		  Return Sources
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemovePreset(Preset As Beacon.Preset)
		  Dim File As FolderItem = Self.FileForCustomPreset(Preset)
		  If File.Exists Then
		    File.Delete
		    Self.LoadPresets
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Rollback()
		  If UBound(Self.mTransactions) = -1 Then
		    Return
		  End If
		  
		  Dim Savepoint As String = Self.mTransactions(0)
		  Self.mTransactions.Remove(0)
		  
		  If Savepoint = "" Then
		    Self.SQLExecute("ROLLBACK TRANSACTION;")
		  Else
		    Self.SQLExecute("ROLLBACK TRANSACTION TO SAVEPOINT " + Savepoint + ";")
		    Self.SQLExecute("RELEASE SAVEPOINT " + Savepoint + ";")
		  End If
		  
		  Self.mLock.Leave
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SaveEngram(Engram As Beacon.Engram, Replace As Boolean = True) As Boolean
		  If Not Engram.IsValid Then
		    Return False
		  End If
		  
		  Self.BeginTransaction()
		  Try
		    Dim Results As RecordSet = Self.SQLSelect("SELECT built_in FROM engrams WHERE LOWER(path) = LOWER(?1);", Engram.Path)
		    If Results.RecordCount = 1 Then
		      If Replace = False Then
		        Return False
		      End If
		      
		      Dim BuiltIn As Boolean = Results.Field("built_in").BooleanValue
		      If BuiltIn Then
		        Self.Rollback()
		        Return False
		      End If
		      
		      Self.SQLExecute("UPDATE engrams SET path = ?1, class_string = ?2, label = ?3, can_blueprint = ?4, availability = ?5 WHERE LOWER(path) = LOWER(?1);", Engram.Path, Engram.ClassString, Engram.Label, Engram.CanBeBlueprint, Engram.Availability)
		    Else
		      Self.SQLExecute("INSERT INTO engrams (path, class_string, label, can_blueprint, availability, built_in) VALUES (?1, ?2, ?3, ?4, ?5, 0);", Engram.Path, Engram.ClassString, Engram.Label, Engram.CanBeBlueprint, Engram.Availability)
		    End If
		    Self.Commit()
		  Catch Err As UnsupportedOperationException
		    Self.RollBack()
		    Return False
		  End Try
		  
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SavePreset(Preset As Beacon.Preset)
		  Self.SavePreset(Preset, True)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SavePreset(Preset As Beacon.Preset, Reload As Boolean)
		  Dim File As FolderItem = Self.FileForCustomPreset(Preset)
		  Preset.ToFile(File)
		  If Reload Then
		    Self.LoadPresets()
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SearchForEngrams(SearchText As Text) As Beacon.Engram()
		  // Part of the Beacon.DataSource interface.
		  
		  Dim Engrams() As Beacon.Engram
		  
		  Try
		    Dim Results As RecordSet
		    If SearchText = "" Then
		      Results = Self.SQLSelect("SELECT path, label, availability, can_blueprint FROM engrams ORDER BY label;")
		    Else
		      Results = Self.SQLSelect("SELECT path, label, availability, can_blueprint FROM engrams WHERE LOWER(label) LIKE LOWER(?1) OR LOWER(class_string) LIKE LOWER(?1) ORDER BY label;", "%" + SearchText + "%")
		    End If
		    
		    Engrams = Self.RecordSetToEngram(Results)
		    For Each Engram As Beacon.Engram In Engrams
		      Self.mEngramCache.Value(Engram.Path) = Engram
		    Next
		  Catch Err As UnsupportedOperationException
		    
		  End Try
		  
		  Return Engrams
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SearchForLootSources(SearchText As Text) As Beacon.LootSource()
		  // Part of the Beacon.DataSource interface.
		  
		  Dim Sources() As Beacon.LootSource
		  
		  Try
		    Dim Results As RecordSet
		    If SearchText = "" Then
		      Results = Self.SQLSelect("SELECT class_string, label, kind, engram_mask, multiplier_min, multiplier_max, uicolor, sort FROM loot_sources ORDER BY label;")
		    Else
		      Results = Self.SQLSelect("SELECT class_string, label, kind, engram_mask, multiplier_min, multiplier_max, uicolor, sort FROM loot_sources WHERE LOWER(label) LIKE LOWER(?1) OR LOWER(class_string) LIKE LOWER(?1) ORDER BY label;", "%" + SearchText + "%")
		    End If
		    
		    Sources = Self.RecordSetToLootSource(Results)
		  Catch Err As UnsupportedOperationException
		    
		  End Try
		  
		  Return Sources
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SQLExecute(SQLString As String, ParamArray Values() As Variant)
		  Self.mLock.Enter
		  
		  If UBound(Values) = -1 Then
		    Self.mBase.SQLExecute(SQLString)
		    Dim Err As RuntimeException = Self.CheckError(SQLString)
		    Self.mLock.Leave
		    If Err <> Nil Then
		      Raise Err
		    End If
		    Return
		  End If
		  
		  Dim Statement As SQLitePreparedStatement = Self.mBase.Prepare(SQLString)
		  Dim Err As RuntimeException = Self.CheckError(SQLString)
		  If Err <> Nil Then
		    Self.mLock.Leave
		    Raise Err
		  End If
		  
		  For I As Integer = 0 To UBound(Values)
		    Dim Value As Variant = Values(I)
		    Select Case Value.Type
		    Case Variant.TypeInteger, Variant.TypeInt32
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_INTEGER)
		    Case Variant.TypeInt64
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_INT64)
		    Case Variant.TypeCurrency, Variant.TypeDouble, Variant.TypeSingle
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_DOUBLE)
		    Case Variant.TypeText
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_TEXT)
		      Dim StringValue As String = Value.TextValue
		      Value = StringValue
		    Case Variant.TypeNil
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_NULL)
		    Case Variant.TypeBoolean
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_BOOLEAN)
		    Else
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_TEXT)
		    End Select
		    
		    Statement.Bind(I, Value)
		  Next
		  
		  Statement.SQLExecute()
		  Err = Self.CheckError(SQLString)
		  Self.mLock.Leave
		  If Err <> Nil Then
		    Raise Err
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SQLSelect(SQLString As String, ParamArray Values() As Variant) As RecordSet
		  Self.mLock.Enter
		  
		  Dim RS As RecordSet
		  
		  If UBound(Values) = -1 Then
		    RS = Self.mBase.SQLSelect(SQLString)
		    Dim Err As RuntimeException = Self.CheckError(SQLString)
		    Self.mLock.Leave
		    If Err <> Nil Then
		      Raise Err
		    End If
		    Return RS
		  End If
		  
		  Dim Statement As SQLitePreparedStatement = Self.mBase.Prepare(SQLString)
		  Dim Err As RuntimeException = Self.CheckError(SQLString)
		  If Err <> Nil Then
		    Self.mLock.Leave
		    Raise Err
		  End If
		  
		  For I As Integer = 0 To UBound(Values)
		    Dim Value As Variant = Values(I)
		    Select Case Value.Type
		    Case Variant.TypeInteger, Variant.TypeInt32
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_INTEGER)
		    Case Variant.TypeInt64
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_INT64)
		    Case Variant.TypeCurrency, Variant.TypeDouble, Variant.TypeSingle
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_DOUBLE)
		    Case Variant.TypeText
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_TEXT)
		      Dim StringValue As String = Value.TextValue
		      Value = StringValue
		    Case Variant.TypeNil
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_NULL)
		    Case Variant.TypeBoolean
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_BOOLEAN)
		    Else
		      Statement.BindType(I, SQLitePreparedStatement.SQLITE_TEXT)
		    End Select
		    
		    Statement.Bind(I, Value)
		  Next
		  
		  RS = Statement.SQLSelect()
		  Err = Self.CheckError(SQLString)
		  Self.mLock.Leave
		  If Err <> Nil Then
		    Raise Err
		  End If
		  Return RS
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Variable(Key As String) As String
		  Try
		    Dim Results As RecordSet = Self.SQLSelect("SELECT value FROM variables WHERE LOWER(key) = LOWER(?1);", Key)
		    If Results.RecordCount = 1 Then
		      Return Results.Field("value").StringValue
		    End If 
		  Catch Err As RuntimeException
		    Return ""
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Variable(Key As String, Assigns Value As String)
		  Try
		    Self.BeginTransaction()
		    Self.SQLExecute("INSERT OR REPLACE INTO variables (key, value) VALUES (?1, ?2);", Key, Value)
		    Self.Commit()
		  Catch Err As UnsupportedOperationException
		    Self.Rollback()
		  End Try
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mBase As SQLiteDatabase
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mEngramCache As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLock As CriticalSection
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPresets() As Beacon.Preset
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTransactions() As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mUpdater As Xojo.Net.HTTPSocket
	#tag EndProperty


	#tag Constant, Name = SchemaVersion, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant


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
