#tag Window
Begin Window DocumentExportWindow
   BackColor       =   &cFFFFFF00
   Backdrop        =   0
   CloseButton     =   False
   Compatibility   =   ""
   Composite       =   False
   Frame           =   8
   FullScreen      =   False
   FullScreenButton=   False
   HasBackColor    =   False
   Height          =   500
   ImplicitInstance=   False
   LiveResize      =   True
   MacProcID       =   0
   MaxHeight       =   32000
   MaximizeButton  =   False
   MaxWidth        =   32000
   MenuBar         =   0
   MenuBarVisible  =   True
   MinHeight       =   400
   MinimizeButton  =   False
   MinWidth        =   800
   Placement       =   1
   Resizeable      =   True
   Title           =   "Export"
   Visible         =   True
   Width           =   900
   Begin BeaconListbox FileList
      AutoDeactivate  =   True
      AutoHideScrollbars=   True
      Bold            =   False
      Border          =   True
      ColumnCount     =   1
      ColumnsResizable=   False
      ColumnWidths    =   ""
      DataField       =   ""
      DataSource      =   ""
      DefaultRowHeight=   32
      Enabled         =   True
      EnableDrag      =   False
      EnableDragReorder=   False
      GridLinesHorizontal=   0
      GridLinesVertical=   0
      HasHeading      =   False
      HeadingIndex    =   -1
      Height          =   502
      HelpTag         =   ""
      Hierarchical    =   False
      Index           =   -2147483648
      InitialParent   =   ""
      InitialValue    =   ""
      Italic          =   False
      Left            =   0
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   True
      RequiresSelection=   False
      RowCount        =   0
      Scope           =   2
      ScrollbarHorizontal=   False
      ScrollBarVertical=   True
      SelectionType   =   0
      ShowDropIndicator=   False
      TabIndex        =   0
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   0
      Transparent     =   False
      Underline       =   False
      UseFocusRing    =   False
      Visible         =   True
      Width           =   222
      _ScrollOffset   =   0
      _ScrollWidth    =   -1
   End
   Begin Label MessageLabel
      AutoDeactivate  =   True
      Bold            =   True
      DataField       =   ""
      DataSource      =   ""
      Enabled         =   True
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   False
      Left            =   242
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      Multiline       =   False
      Scope           =   2
      Selectable      =   False
      TabIndex        =   1
      TabPanelIndex   =   0
      TabStop         =   True
      Text            =   "Exported Values"
      TextAlign       =   0
      TextColor       =   &c00000000
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   20
      Transparent     =   False
      Underline       =   False
      Visible         =   True
      Width           =   638
   End
   Begin UITweaks.ResizedPushButton ActionButton
      AutoDeactivate  =   True
      Bold            =   False
      ButtonStyle     =   "0"
      Cancel          =   False
      Caption         =   "Finished"
      Default         =   False
      Enabled         =   True
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   False
      Left            =   784
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   False
      LockRight       =   True
      LockTop         =   False
      Scope           =   2
      TabIndex        =   2
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   460
      Transparent     =   False
      Underline       =   False
      Visible         =   True
      Width           =   96
   End
   Begin TextArea ContentArea
      AcceptTabs      =   False
      Alignment       =   0
      AutoDeactivate  =   True
      AutomaticallyCheckSpelling=   True
      BackColor       =   &cFFFFFF00
      Bold            =   False
      Border          =   True
      DataField       =   ""
      DataSource      =   ""
      Enabled         =   True
      Format          =   ""
      Height          =   380
      HelpTag         =   ""
      HideSelection   =   True
      Index           =   -2147483648
      Italic          =   False
      Left            =   242
      LimitText       =   0
      LineHeight      =   0.0
      LineSpacing     =   1.0
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      Mask            =   ""
      Multiline       =   True
      ReadOnly        =   True
      Scope           =   2
      ScrollbarHorizontal=   False
      ScrollbarVertical=   True
      Styled          =   True
      TabIndex        =   3
      TabPanelIndex   =   0
      TabStop         =   True
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   60
      Transparent     =   False
      Underline       =   False
      UseFocusRing    =   True
      Visible         =   True
      Width           =   638
   End
   Begin UITweaks.ResizedPushButton SaveButton
      AutoDeactivate  =   True
      Bold            =   False
      ButtonStyle     =   "0"
      Cancel          =   False
      Caption         =   "Save As…"
      Default         =   False
      Enabled         =   False
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   False
      Left            =   350
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   False
      Scope           =   2
      TabIndex        =   4
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   460
      Transparent     =   False
      Underline       =   False
      Visible         =   True
      Width           =   96
   End
   Begin UITweaks.ResizedPushButton CopyButton
      AutoDeactivate  =   True
      Bold            =   False
      ButtonStyle     =   "0"
      Cancel          =   False
      Caption         =   "Copy All"
      Default         =   False
      Enabled         =   False
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   False
      Left            =   242
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   False
      Scope           =   2
      TabIndex        =   5
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   460
      Transparent     =   False
      Underline       =   False
      Visible         =   True
      Width           =   96
   End
   Begin UITweaks.ResizedPushButton RewriteButton
      AutoDeactivate  =   True
      Bold            =   False
      ButtonStyle     =   "0"
      Cancel          =   False
      Caption         =   "Rewrite Clipboard"
      Default         =   False
      Enabled         =   False
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   False
      Left            =   458
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   False
      Scope           =   2
      TabIndex        =   6
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   460
      Transparent     =   False
      Underline       =   False
      Visible         =   True
      Width           =   140
   End
   Begin Timer ClipboardWatcher
      Enabled         =   True
      Index           =   -2147483648
      LockedInPosition=   False
      Mode            =   2
      Period          =   1000
      Scope           =   2
      TabPanelIndex   =   0
   End
End
#tag EndWindow

#tag WindowCode
	#tag Method, Flags = &h21
		Private Sub CheckClipboard()
		  If Self.FileList.ListIndex = -1 Then
		    If Self.RewriteButton.Enabled Then
		      Self.RewriteButton.Enabled = False
		    End If
		    If Self.RewriteButton.Caption <> "Rewrite Clipboard" Then
		      Self.RewriteButton.Caption = "Rewrite Clipboard"
		    End If
		    Return
		  End If
		  
		  Dim SelectedConfig As String = Self.FileList.Cell(Self.FileList.ListIndex, 0)
		  If SelectedConfig = "Command Line Options" Then
		    If Self.RewriteButton.Enabled Then
		      Self.RewriteButton.Enabled = False
		    End If
		    If Self.RewriteButton.Caption <> "Rewrite Clipboard" Then
		      Self.RewriteButton.Caption = "Rewrite Clipboard"
		    End If
		    Return
		  End If
		  
		  Dim Board As New Clipboard
		  If Board.TextAvailable = False Or ReplaceLineEndings(Board.Text, EndOfLine) = Self.ContentArea.Text Then
		    If Self.RewriteButton.Enabled Then
		      Self.RewriteButton.Enabled = False
		    End If
		    If Self.RewriteButton.Caption <> "Rewrite Clipboard" Then
		      Self.RewriteButton.Caption = "Rewrite Clipboard"
		    End If
		    Return
		  End If
		  
		  Dim SearchingFor As String
		  Select Case SelectedConfig
		  Case Beacon.RewriteModeGameIni
		    SearchingFor = "[" + Beacon.ShooterGameHeader + "]"
		  Case Beacon.RewriteModeGameUserSettingsIni
		    SearchingFor = "[" + Beacon.ServerSettingsHeader + "]"
		  Else
		    If Self.RewriteButton.Enabled Then
		      Self.RewriteButton.Enabled = False
		    End If
		    If Self.RewriteButton.Caption <> "Rewrite Clipboard" Then
		      Self.RewriteButton.Caption = "Rewrite Clipboard"
		    End If
		    Return
		  End Select
		  
		  If Board.Text.InStr(SearchingFor) <= 0 Then
		    If Self.RewriteButton.Enabled Then
		      Self.RewriteButton.Enabled = False
		    End If
		    If Self.RewriteButton.Caption <> "Rewrite Clipboard" Then
		      Self.RewriteButton.Caption = "Rewrite Clipboard"
		    End If
		    Return
		  End If
		  
		  If EncodeHex(Crypto.MD5(Board.Text)) = Self.mLastRewrittenHash Then
		    If Self.RewriteButton.Enabled Then
		      Self.RewriteButton.Enabled = False
		    End If
		    If Self.RewriteButton.Caption <> "Ready for Paste" Then
		      Self.RewriteButton.Caption = "Ready for Paste"
		    End If
		    Return
		  End If
		  
		  If Not Self.RewriteButton.Enabled Then
		    Self.RewriteButton.Enabled = True
		  End If
		  If Self.RewriteButton.Caption <> "Rewrite Clipboard" Then
		    Self.RewriteButton.Caption = "Rewrite Clipboard"
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Shared Sub Present(Parent As Window, Document As Beacon.Document)
		  Dim Configs() As Beacon.ConfigGroup = Document.ImplementedConfigs
		  Dim GameIniHeaders As New Xojo.Core.Dictionary
		  Dim GameUserSettingsIniHeaders As New Xojo.Core.Dictionary
		  Dim CommandLineHeaders As New Xojo.Core.Dictionary
		  
		  For Each Config As Beacon.ConfigGroup In Configs
		    Dim Values() As Beacon.ConfigValue = Config.CommandLineOptions(Document)
		    If Values <> Nil Then
		      For Each Value As Beacon.ConfigValue In Values
		        Dim Arr() As Text
		        If CommandLineHeaders.HasKey(Value.Header) Then
		          Arr = CommandLineHeaders.Value(Value.Header)
		        End If
		        If Value.Value = "" Then
		          Arr.Append(Value.Key)
		        Else
		          Arr.Append(Value.Key + "=" + Value.Value)
		        End If
		        CommandLineHeaders.Value(Value.Header) = Arr
		      Next
		    End If
		    
		    Beacon.ConfigValue.FillConfigDict(GameIniHeaders, Config.GameIniValues(Document))
		    Beacon.ConfigValue.FillConfigDict(GameUserSettingsIniHeaders, Config.GameUserSettingsIniValues(Document))
		  Next
		  
		  Dim Win As New DocumentExportWindow
		  Win.mCommandLineConfigs = CommandLineHeaders
		  Win.mGameIniConfigs = GameIniHeaders
		  Win.mGameUserSettingsConfigs = GameUserSettingsIniHeaders
		  Win.Setup()
		  Win.ShowModalWithin(Parent.TrueWindow)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RestoreCopyButton()
		  Self.CopyButton.Caption = "Copy All"
		  Self.CopyButton.Enabled = True
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RestoreRewriteButton()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Setup()
		  If Self.mCommandLineConfigs.Count > 0 Then
		    Self.FileList.AddRow("Command Line Options")
		  End If
		  
		  If Self.mGameUserSettingsConfigs.Count > 0 Then
		    Self.FileList.AddRow(Beacon.RewriteModeGameUserSettingsIni)
		  End If
		  
		  If Self.mGameIniConfigs.Count > 0 Then
		    Self.FileList.AddRow(Beacon.RewriteModeGameIni)
		  End If
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mCommandLineConfigs As Xojo.Core.DIctionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mGameIniConfigs As Xojo.Core.Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mGameUserSettingsConfigs As Xojo.Core.Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastRewrittenHash As String
	#tag EndProperty


#tag EndWindowCode

#tag Events FileList
	#tag Event
		Sub Change()
		  Xojo.Core.Timer.CancelCall(WeakAddressOf RestoreCopyButton)
		  Xojo.Core.Timer.CancelCall(WeakAddressOf RestoreRewriteButton)
		  
		  Self.CopyButton.Enabled = Me.ListIndex > -1
		  Self.CopyButton.Caption = "Copy All"
		  
		  If Me.ListIndex = -1 Then
		    Self.SaveButton.Enabled = False
		    Self.ContentArea.Text = ""
		    Self.CheckClipboard()
		    Return
		  End If
		  
		  Dim Option As String = Me.Cell(Me.ListIndex, 0)
		  If Option = "Command Line Options" Then
		    Self.ContentArea.Text = "?listen"
		    If Self.mCommandLineConfigs.HasKey("?") Then
		      Dim Arr() As Text = Self.mCommandLineConfigs.Value("?")
		      Self.ContentArea.Text = Self.ContentArea.Text + "?" + Text.Join(Arr, "?")
		    End If
		    If Self.mCommandLineConfigs.HasKey("-") Then
		      Dim Arr() As Text = Self.mCommandLineConfigs.Value("-")
		      For Each Command As Text In Arr
		        Self.ContentArea.Text = Self.ContentArea.Text + " -" + Command
		      Next
		    End If
		    Self.SaveButton.Enabled = False
		    Self.CheckClipboard()
		    Return
		  End If
		  
		  Dim Configs As Xojo.Core.Dictionary
		  If Option = "GameUserSettings.ini" Then
		    Configs = Self.mGameUserSettingsConfigs
		  ElseIf Option = "Game.ini" Then
		    Configs = Self.mGameIniConfigs
		  Else
		    Self.ContentArea.Text = ""
		    Self.CheckClipboard()
		    Return
		  End If
		  
		  Self.SaveButton.Enabled = True
		  Self.ContentArea.Text = ReplaceLineEndings(Beacon.RewriteIniContent("", Configs), EndOfLine)
		  Self.CheckClipboard()
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events ActionButton
	#tag Event
		Sub Action()
		  Self.Close()
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events SaveButton
	#tag Event
		Sub Action()
		  Dim ConfigFilename As String = Self.FileList.Cell(Self.FileList.ListIndex, 0)
		  
		  Dim Dialog As New SaveAsDialog
		  Dialog.Filter = BeaconFileTypes.IniFile
		  Dialog.SuggestedFileName = ConfigFilename
		  
		  Dim File As FolderItem = Dialog.ShowModal()
		  If File <> Nil Then
		    Dim Content As String
		    If File.Exists Then
		      Dim InStream As TextInputStream = TextInputStream.Open(File)
		      Content = InStream.ReadAll(Encodings.UTF8)
		      InStream.Close
		      
		      Dim Configs As Xojo.Core.Dictionary
		      Select Case ConfigFilename
		      Case Beacon.RewriteModeGameIni
		        Configs = Self.mGameIniConfigs
		      Case Beacon.RewriteModeGameUserSettingsIni
		        Configs = Self.mGameUserSettingsConfigs
		      End Select
		      Content = Beacon.RewriteIniContent(Content.ToText, Configs)
		    Else
		      Content = Self.ContentArea.Text
		    End If
		    
		    Dim OutStream As TextOutputStream = TextOutputStream.Create(File)
		    OutStream.Write(Content)
		    OutStream.Close
		  End If
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events CopyButton
	#tag Event
		Sub Action()
		  Dim Board As New Clipboard
		  Board.Text = Self.ContentArea.Text
		  Me.Caption = "Copied!"
		  Me.Enabled = False
		  Xojo.Core.Timer.CallLater(2000, WeakAddressOf RestoreCopyButton)
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events RewriteButton
	#tag Event
		Sub Action()
		  Dim SelectedConfig As String = Self.FileList.Cell(Self.FileList.ListIndex, 0)
		  Dim Configs As Xojo.Core.Dictionary
		  Select Case SelectedConfig
		  Case Beacon.RewriteModeGameIni
		    Configs = Self.mGameIniConfigs
		  Case Beacon.RewriteModeGameUserSettingsIni
		    Configs = Self.mGameUserSettingsConfigs
		  Else
		    Configs = New Xojo.Core.Dictionary
		  End Select
		  
		  Dim Board As New Clipboard
		  Board.Text = Beacon.RewriteIniContent(Board.Text.ToText, Configs)
		  Self.mLastRewrittenHash = EncodeHex(MD5(Board.Text))
		  Self.RewriteButton.Enabled = False
		  Self.RewriteButton.Caption = "Ready for Paste"
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events ClipboardWatcher
	#tag Event
		Sub Action()
		  Self.CheckClipboard()
		End Sub
	#tag EndEvent
#tag EndEvents
#tag ViewBehavior
	#tag ViewProperty
		Name="Name"
		Visible=true
		Group="ID"
		Type="String"
		EditorType="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Interfaces"
		Visible=true
		Group="ID"
		Type="String"
		EditorType="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Super"
		Visible=true
		Group="ID"
		Type="String"
		EditorType="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Width"
		Visible=true
		Group="Size"
		InitialValue="600"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Height"
		Visible=true
		Group="Size"
		InitialValue="400"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MinWidth"
		Visible=true
		Group="Size"
		InitialValue="64"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MinHeight"
		Visible=true
		Group="Size"
		InitialValue="64"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MaxWidth"
		Visible=true
		Group="Size"
		InitialValue="32000"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MaxHeight"
		Visible=true
		Group="Size"
		InitialValue="32000"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Frame"
		Visible=true
		Group="Frame"
		InitialValue="0"
		Type="Integer"
		EditorType="Enum"
		#tag EnumValues
			"0 - Document"
			"1 - Movable Modal"
			"2 - Modal Dialog"
			"3 - Floating Window"
			"4 - Plain Box"
			"5 - Shadowed Box"
			"6 - Rounded Window"
			"7 - Global Floating Window"
			"8 - Sheet Window"
			"9 - Metal Window"
			"11 - Modeless Dialog"
		#tag EndEnumValues
	#tag EndViewProperty
	#tag ViewProperty
		Name="Title"
		Visible=true
		Group="Frame"
		InitialValue="Untitled"
		Type="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="CloseButton"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Resizeable"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MaximizeButton"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MinimizeButton"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="FullScreenButton"
		Visible=true
		Group="Frame"
		InitialValue="False"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Composite"
		Group="OS X (Carbon)"
		InitialValue="False"
		Type="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MacProcID"
		Group="OS X (Carbon)"
		InitialValue="0"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="ImplicitInstance"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Placement"
		Visible=true
		Group="Behavior"
		InitialValue="0"
		Type="Integer"
		EditorType="Enum"
		#tag EnumValues
			"0 - Default"
			"1 - Parent Window"
			"2 - Main Screen"
			"3 - Parent Window Screen"
			"4 - Stagger"
		#tag EndEnumValues
	#tag EndViewProperty
	#tag ViewProperty
		Name="Visible"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="LiveResize"
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="FullScreen"
		Group="Behavior"
		InitialValue="False"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="HasBackColor"
		Visible=true
		Group="Background"
		InitialValue="False"
		Type="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="BackColor"
		Visible=true
		Group="Background"
		InitialValue="&hFFFFFF"
		Type="Color"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Backdrop"
		Visible=true
		Group="Background"
		Type="Picture"
		EditorType="Picture"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MenuBar"
		Visible=true
		Group="Menus"
		Type="MenuBar"
		EditorType="MenuBar"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MenuBarVisible"
		Visible=true
		Group="Deprecated"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
#tag EndViewBehavior