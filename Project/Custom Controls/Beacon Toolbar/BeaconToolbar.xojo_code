#tag Class
Protected Class BeaconToolbar
Inherits ControlCanvas
Implements ObservationKit.Observer
	#tag Event
		Sub Activate()
		  RaiseEvent Activate
		  Self.Invalidate
		End Sub
	#tag EndEvent

	#tag Event
		Sub Deactivate()
		  RaiseEvent Deactivate
		  Self.Invalidate
		End Sub
	#tag EndEvent

	#tag Event
		Function MouseDown(X As Integer, Y As Integer) As Boolean
		  Dim Point As New REALbasic.Point(X, Y)
		  Self.mMouseDownName = ""
		  Self.mMouseHeld = False
		  Self.mMouseDownX = X
		  Self.mMouseDownY = Y
		  Self.mMouseX = X
		  Self.mMouseY = Y
		  
		  Tooltip.Hide
		  CallLater.Cancel(Self.mHoverCallbackKey)
		  
		  If Self.mResizerEnabled And Self.mResizerRect <> Nil And Self.mResizerRect.Contains(Point) Then
		    Self.mResizing = True
		    RaiseEvent ResizeStarted()
		    If Self.mResizerStyle = ResizerTypes.Horizontal Then
		      Self.mStartingSize = Self.Width
		      Self.mResizeOffset = X
		    ElseIf Self.mResizerStyle = ResizerTypes.Vertical Then
		      Self.mStartingSize = Self.Top
		      Self.mResizeOffset = Y
		    End If
		    Return True
		  End If
		  
		  Dim HitItem As BeaconToolbarItem = Self.ItemAtPoint(Point)
		  If HitItem <> Nil And HitItem.Enabled Then
		    Self.mMouseDownName = HitItem.Name
		    Self.mPressedName = Self.mMouseDownName
		    Self.Refresh
		    If HitItem.HasMenu Then
		      Self.mHoldTimer.Mode = Timer.ModeSingle
		    End If
		    Return True
		  End If
		End Function
	#tag EndEvent

	#tag Event
		Sub MouseDrag(X As Integer, Y As Integer)
		  If X = Self.mMouseX And Y = Self.mMouseY Then
		    Return
		  End If
		  
		  Self.mMouseX = X
		  Self.mMouseY = Y
		  
		  If Self.mResizing Then
		    Dim DeltaX As Integer = 0
		    Dim DeltaY As Integer = 0
		    
		    If Self.mResizerStyle = ResizerTypes.Horizontal Then
		      DeltaX = X - Self.mResizeOffset
		      
		      Dim NewWidth As Integer = Self.Width + DeltaX
		      RaiseEvent ShouldResize(NewWidth)
		      Self.mResizeOffset = Self.mResizeOffset + (Self.Width - Self.mStartingSize)
		      Self.mStartingSize = Self.Width
		    ElseIf Self.mResizerStyle = ResizerTypes.Vertical Then
		      DeltaY = Y - Self.mResizeOffset
		      
		      Dim NewTop As Integer = Self.Top + DeltaY
		      RaiseEvent ShouldResize(NewTop)
		    End If
		    
		    RaiseEvent ResizerDragged(DeltaX, DeltaY)
		    
		    Return
		  End If
		  
		  If Self.mMouseDownName <> "" Then
		    Dim Item As BeaconToolbarItem = Self.ItemWithName(Self.mMouseDownName)
		    If Item <> Nil Then
		      Dim Rect As REALbasic.Rect = Item.Rect
		      If Rect.Contains(New REALbasic.Point(X, Y)) Then
		        If Self.mPressedName <> Item.Name Then
		          Self.mPressedName = Item.Name
		          Self.Invalidate
		        End If
		        If Not Self.mMouseHeld Then
		          Self.mHoldTimer.Reset
		          Self.mHoldTimer.Mode = Timer.ModeSingle
		        End If
		      Else
		        If Self.mPressedName <> "" Then
		          Self.mPressedName = ""
		          Self.Invalidate
		        End If
		        Self.mHoldTimer.Reset
		        Self.mHoldTimer.Mode = Timer.ModeOff
		      End If
		      Return
		    End If
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub MouseExit()
		  #if BeaconUI.CursorsEnabled
		    Self.MouseCursor = Nil
		  #endif
		  Self.HoverItem = Nil
		End Sub
	#tag EndEvent

	#tag Event
		Sub MouseMove(X As Integer, Y As Integer)
		  Dim Point As New REALbasic.Point(X, Y)
		  Self.HoverItem = Self.ItemAtPoint(Point)
		  
		  If Self.mResizerRect <> Nil Then
		    #if BeaconUI.CursorsEnabled
		      If Self.mResizerRect.Contains(Point) Then
		        If Self.mResizerStyle = ResizerTypes.Horizontal Then
		          Self.MouseCursor = System.Cursors.SplitterEastWest
		        ElseIf Self.mResizerStyle = ResizerTypes.Vertical Then
		          Self.MouseCursor = System.Cursors.SplitterNorthSouth
		        End If
		      Else
		        Self.MouseCursor = Nil
		      End If
		    #endif
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub MouseUp(X As Integer, Y As Integer)
		  Self.mMouseX = X
		  Self.mMouseY = Y
		  
		  Self.mHoldTimer.Reset
		  Self.mHoldTimer.Mode = Timer.ModeOff
		  
		  If Self.mResizing Then
		    Self.mResizing = False
		    RaiseEvent ResizeFinished()
		    Return
		  End If
		  
		  If Self.mMouseDownName <> "" Then
		    Dim Item As BeaconToolbarItem = Self.ItemWithName(Self.mMouseDownName)
		    If Item <> Nil And Item.Rect.Contains(New REALbasic.Point(X, Y)) And Not Self.mMouseHeld Then
		      // Action
		      RaiseEvent Action(Item)
		    End If
		    Self.mPressedName = ""
		    Self.mMouseDownName = ""
		    Self.Invalidate
		    Return
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub Open()
		  RaiseEvent Open
		  Self.Transparent = True
		  Self.DoubleBuffer = False
		End Sub
	#tag EndEvent

	#tag Event
		Sub Paint(g As Graphics, areas() As REALbasic.Rect)
		  #Pragma Unused Areas
		  
		  Self.PaintContent(G)
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor
		  Self.mLeftItems = New BeaconToolbarItemArray
		  Self.mLeftItems.AddObserver(Self, BeaconToolbarItem.KeyChanged)
		  Self.mRightItems = New BeaconToolbarItemArray
		  Self.mRightItems.AddObserver(Self, BeaconToolbarItem.KeyChanged)
		  Self.mHoldTimer = New Timer
		  Self.mHoldTimer.Mode = Timer.ModeOff
		  Self.mHoldTimer.Period = 250
		  AddHandler Self.mHoldTimer.Action, WeakAddressOf Self.mHoldTimer_Action
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Destructor()
		  CallLater.Cancel(Self.mHoverCallbackKey)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DrawButton(G As Graphics, Button As BeaconToolbarItem, Rect As REALbasic.Rect, Mode As ButtonModes, Highlighted As Boolean)
		  #Pragma Unused Highlighted
		  
		  Dim PrecisionX As Double = 1 / G.ScaleX
		  Dim PrecisionY As Double = 1 / G.ScaleY
		  
		  If Button.Icon <> Nil Then
		    Dim UseAccent As Boolean = True
		    Dim AccentColor As Color
		    Select Case Button.IconColor
		    Case BeaconToolbarItem.IconColors.Blue
		      AccentColor = SystemColors.SystemBlueColor
		    Case BeaconToolbarItem.IconColors.Brown
		      AccentColor = SystemColors.SystemBrownColor
		    Case BeaconToolbarItem.IconColors.Gray
		      AccentColor = SystemColors.SystemGrayColor
		    Case BeaconToolbarItem.IconColors.Green
		      AccentColor = SystemColors.SystemGreenColor
		    Case BeaconToolbarItem.IconColors.Orange
		      AccentColor = SystemColors.SystemOrangeColor
		    Case BeaconToolbarItem.IconColors.Pink
		      AccentColor = SystemColors.SystemPinkColor
		    Case BeaconToolbarItem.IconColors.Purple
		      AccentColor = SystemColors.SystemPurpleColor
		    Case BeaconToolbarItem.IconColors.Red
		      AccentColor = SystemColors.SystemRedColor
		    Case BeaconToolbarItem.IconColors.Yellow
		      AccentColor = SystemColors.SystemYellowColor
		    Else
		      UseAccent = False
		    End Select
		    
		    Dim IconColor As Color
		    If Button.Toggled Then
		      IconColor = SystemColors.AlternateSelectedControlTextColor
		    Else
		      IconColor = If(UseAccent And Button.Enabled, AccentColor, SystemColors.ControlTextColor)
		    End If
		    If Mode = ButtonModes.Disabled Then
		      IconColor = IconColor.AtOpacity(0.25)
		    End If
		    
		    If Button.Toggled Then
		      G.ForeColor = If(UseAccent, AccentColor, SystemColors.SelectedContentBackgroundColor)
		      G.FillRoundRect(NearestMultiple(Rect.Left, PrecisionX), NearestMultiple(Rect.Top, PrecisionY), NearestMultiple(Rect.Width, PrecisionX), NearestMultiple(Rect.Height, PrecisionY), 4, 4)
		    End If
		    
		    Dim Overlay As Picture
		    If Button.HasMenu Then
		      Overlay = IconToolbarDropdown
		    End If
		    Dim Icon As Picture = BeaconUI.IconWithColor(Button.Icon, IconColor, Overlay)
		    G.DrawPicture(Icon, NearestMultiple(Rect.Left + ((Rect.Width - Icon.Width) / 2), PrecisionX), NearestMultiple(Rect.Top + ((Rect.Height - Icon.Height) / 2), PrecisionY))
		  End If
		  
		  If Mode = ButtonModes.Pressed Then
		    G.ForeColor = &c00000080
		    G.FillRoundRect(NearestMultiple(Rect.Left, PrecisionX), NearestMultiple(Rect.Top, PrecisionY), NearestMultiple(Rect.Width, PrecisionX), NearestMultiple(Rect.Height, PrecisionY), 4, 4)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HoverItem() As BeaconToolbarItem
		  Return Self.mHoverItem
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub HoverItem(Assigns Item As BeaconToolbarItem)
		  If Self.mHoverItem = Item Then
		    Return
		  End If
		  
		  Self.mHoverItem = Item
		  
		  Tooltip.Hide
		  CallLater.Cancel(Self.mHoverCallbackKey)
		  
		  If Item <> Nil And Item.HelpTag <> "" Then
		    Self.mHoverCallbackKey = CallLater.Schedule(1000, WeakAddressOf ShowHoverTooltip)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ItemAtPoint(X As Integer, Y As Integer) As BeaconToolbarItem
		  Return Self.ItemAtPoint(New REALbasic.Point(X, Y))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ItemAtPoint(Point As REALbasic.Point) As BeaconToolbarItem
		  If Self.mLeftItems <> Nil Then
		    For I As Integer = 0 To Self.mLeftItems.UBound
		      Try
		        If Self.mLeftItems(I) <> Nil And Self.mLeftItems(I).Rect.Contains(Point) Then
		          Return Self.mLeftItems(I)
		        End If
		      Catch Err As NilObjectException
		        Continue
		      End Try
		    Next
		  End If
		  
		  If Self.mRightItems <> Nil Then
		    For I As Integer = 0 To Self.mRightItems.UBound
		      Try
		        If Self.mRightItems(I) <> Nil And Self.mRightItems(I).Rect.Contains(Point) Then
		          Return Self.mRightItems(I)
		        End If
		      Catch Err As NilObjectException
		        Continue
		      End Try
		    Next
		  End If
		  
		  Exception NOE As NilObjectException
		    Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ItemWithName(Name As String) As BeaconToolbarItem
		  For I As Integer = 0 To Self.mLeftItems.UBound
		    If Self.mLeftItems(I).Name = Name Then
		      Return Self.mLeftItems(I)
		    End If
		  Next
		  For I As Integer = 0 To Self.mRightItems.UBound
		    If Self.mRightItems(I).Name = Name Then
		      Return Self.mRightItems(I)
		    End If
		  Next
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub mHoldTimer_Action(Sender As Timer)
		  #Pragma Unused Sender
		  
		  If Self.mMouseHeld Or Self.mPressedName = "" Then
		    Return
		  End If
		  
		  Dim Item As BeaconToolbarItem = Self.ItemWithName(Self.mPressedName)
		  Dim Menu As New MenuItem
		  RaiseEvent BuildMenu(Item, Menu)
		  Self.mMouseHeld = True
		  
		  If Menu.Count = 0 Then
		    Return
		  End If
		  
		  Dim Position As Xojo.Core.Point = Self.Window.GlobalPosition
		  Dim Choice As MenuItem = Menu.PopUp(Position.X + Self.Left + Item.Rect.Left, Position.Y + Self.Top + Item.Rect.Bottom)
		  If Choice <> Nil Then
		    RaiseEvent HandleMenuAction(Item, Choice)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ObservedValueChanged(Source As ObservationKit.Observable, Key As Text, Value As Auto)
		  // Part of the ObservationKit.Observer interface.
		  
		  #Pragma Unused Source
		  #Pragma Unused Key
		  #Pragma Unused Value
		  
		  Self.Invalidate
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Operator_Lookup(Name As String) As BeaconToolbarItem
		  Return Self.ItemWithName(Name)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub PaintContent(G As Graphics)
		  Const CellPadding = 8
		  Const ButtonSize = 24
		  
		  Dim Highlighted As Boolean = True
		  #if TargetCocoa And BeaconUI.ToolbarHasBackground = False
		    Declare Function IsMainWindow Lib "Cocoa.framework" Selector "isMainWindow" (Target As Integer) As Boolean
		    Declare Function IsKeyWindow Lib "Cocoa.framework" Selector "isKeyWindow" (Target As Integer) As Boolean
		    Highlighted = IsKeyWindow(Self.TrueWindow.Handle) Or IsMainWindow(Self.TrueWindow.Handle)
		  #endif
		  
		  Dim ContentRect As New REALbasic.Rect(CellPadding, CellPadding, G.Width - (CellPadding * 2), G.Height - (CellPadding * 2))
		  
		  If Self.mResizerStyle <> ResizerTypes.None Then
		    Dim ResizeIcon As Picture
		    Select Case Self.mResizerStyle
		    Case ResizerTypes.Horizontal
		      ResizeIcon = IconToolbarHResize
		    Case ResizerTypes.Vertical
		      ResizeIcon = IconToolbarVResize
		    End Select
		    
		    ContentRect.Right = ContentRect.Right - (CellPadding + ResizeIcon.Width)
		    
		    Dim ResizerLeft As Integer = ContentRect.Right + CellPadding
		    Dim ResizerTop As Integer = (G.Height - ResizeIcon.Height) / 2
		    
		    Self.mResizerRect = New REALbasic.Rect(ResizerLeft, 0, G.Width - ResizerLeft, G.Height)
		    
		    Dim ResizeColor As Color = SystemColors.LabelColor
		    If Not Self.ResizerEnabled Then
		      ResizeColor = ResizeColor.AtOpacity(0.25)
		    End If
		    
		    ResizeIcon = BeaconUI.IconWithColor(ResizeIcon, ResizeColor)
		    G.DrawPicture(ResizeIcon, ResizerLeft, ResizerTop)
		  Else
		    Self.mResizerRect = Nil
		  End If
		  
		  Dim NextLeft As Integer = ContentRect.Left
		  Dim NextRight As Integer = ContentRect.Right
		  Dim ItemsPerSide As Integer = Max(Self.LeftItems.Count, Self.RightItems.Count)
		  ContentRect.Left = ContentRect.Left + (ItemsPerSide * (ButtonSize + CellPadding))
		  ContentRect.Width = ContentRect.Width - ((ItemsPerSide * 2) * (ButtonSize + CellPadding))
		  
		  For I As Integer = 0 To Self.mLeftItems.UBound
		    Dim Item As BeaconToolbarItem = Self.mLeftItems(I)
		    Dim Mode As ButtonModes = ButtonModes.Normal
		    If Self.mPressedName = Item.Name Then
		      Mode = ButtonModes.Pressed
		    End If
		    If Not Item.Enabled Then
		      Mode = ButtonModes.Disabled
		    End If
		    
		    Item.Rect = New REALbasic.Rect(NextLeft, CellPadding, ButtonSize, ButtonSize)
		    Self.DrawButton(G, Item, Item.Rect, Mode, Highlighted)
		    NextLeft = Item.Rect.Right + CellPadding
		  Next
		  
		  For I As Integer = 0 To Self.mRightItems.UBound
		    Dim Item As BeaconToolbarItem = Self.mRightItems(I)
		    Dim Mode As ButtonModes = ButtonModes.Normal
		    If Self.mPressedName = Item.Name Then
		      Mode = ButtonModes.Pressed
		    End If
		    If Not Item.Enabled Then
		      Mode = ButtonModes.Disabled
		    End If
		    
		    Item.Rect = New REALbasic.Rect(NextRight - ButtonSize, CellPadding, ButtonSize, ButtonSize)
		    Self.DrawButton(G, Item, Item.Rect, Mode, Highlighted)
		    NextRight = Item.Rect.Left - CellPadding
		  Next
		  
		  If Self.Caption <> "" Then
		    Dim Caption As String = Self.Caption.NthField(EndOfLine, 1)
		    
		    Dim CaptionSize As Double = 0
		    
		    G.TextSize = CaptionSize
		    Dim CaptionWidth As Integer = Ceil(G.StringWidth(Caption))
		    
		    CaptionWidth = Min(CaptionWidth, ContentRect.Width)
		    Dim CaptionLeft As Integer = ContentRect.Left + ((ContentRect.Width - CaptionWidth) / 2)
		    Dim CaptionBottom As Integer = ContentRect.Top + (ContentRect.Height / 2) + ((G.TextAscent * 0.8) / 2)
		    
		    G.ForeColor = SystemColors.LabelColor
		    G.DrawString(Self.Caption, CaptionLeft, CaptionBottom, CaptionWidth, True)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ShowHoverTooltip()
		  If Self.mHoverItem = Nil Then
		    Return
		  End If
		  
		  Tooltip.Show(Self.mHoverItem.HelpTag, System.MouseX, System.MouseY + 16)
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Action(Item As BeaconToolbarItem)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Activate()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event BuildMenu(Item As BeaconToolbarItem, Menu As MenuItem)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Deactivate()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event HandleMenuAction(Item As BeaconToolbarItem, ChosenItem As MenuItem)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Open()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ResizeFinished()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ResizerDragged(DeltaX As Integer, DeltaY As Integer)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ResizeStarted()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ShouldResize(ByRef NewSize As Integer)
	#tag EndHook


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mCaption
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If StrComp(Self.mCaption, Value, 0) <> 0 Then
			    Self.mCaption = Value
			    Self.Invalidate
			  End If
			End Set
		#tag EndSetter
		Caption As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mLeftItems
			End Get
		#tag EndGetter
		LeftItems As BeaconToolbarItemArray
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mCaption As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mHoldTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mHoverCallbackKey As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mHoverItem As BeaconToolbarItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLeftItems As BeaconToolbarItemArray
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMouseDownName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMouseDownX As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMouseDownY As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMouseHeld As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMouseX As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMouseY As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPressedName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mResizeOffset As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mResizerEnabled As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mResizerRect As REALbasic.Rect
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mResizerStyle As BeaconToolbar.ResizerTypes
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mResizing As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRightItems As BeaconToolbarItemArray
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStartingSize As Integer
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mResizerStyle
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Self.mResizerStyle <> Value Then
			    Self.mResizerStyle = Value
			    Self.Invalidate
			  End If
			End Set
		#tag EndSetter
		Resizer As BeaconToolbar.ResizerTypes
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mResizerEnabled
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Self.mResizerEnabled <> Value Then
			    Self.mResizerEnabled = Value
			    Self.Invalidate
			  End If
			End Set
		#tag EndSetter
		ResizerEnabled As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mRightItems
			End Get
		#tag EndGetter
		RightItems As BeaconToolbarItemArray
	#tag EndComputedProperty


	#tag Enum, Name = ButtonModes, Type = Integer, Flags = &h21
		Normal
		  Disabled
		Pressed
	#tag EndEnum

	#tag Enum, Name = ResizerTypes, Type = Integer, Flags = &h0
		None
		  Horizontal
		Vertical
	#tag EndEnum


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			Type="Integer"
			EditorType="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
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
			Name="Height"
			Visible=true
			Group="Position"
			InitialValue="40"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="InitialParent"
			Group="Position"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockBottom"
			Visible=true
			Group="Position"
			InitialValue="False"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockLeft"
			Visible=true
			Group="Position"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockRight"
			Visible=true
			Group="Position"
			InitialValue="False"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockTop"
			Visible=true
			Group="Position"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabIndex"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabPanelIndex"
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabStop"
			Visible=true
			Group="Position"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Width"
			Visible=true
			Group="Position"
			InitialValue="200"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AutoDeactivate"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Backdrop"
			Group="Appearance"
			Type="Picture"
			EditorType="Picture"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Enabled"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="HelpTag"
			Visible=true
			Group="Appearance"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="UseFocusRing"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Visible"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ScrollSpeed"
			Group="Behavior"
			InitialValue="20"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AcceptFocus"
			Visible=true
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AcceptTabs"
			Visible=true
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Caption"
			Visible=true
			Group="Behavior"
			InitialValue="Untitled"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DoubleBuffer"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="EraseBackground"
			Group="Behavior"
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Resizer"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="BeaconToolbar.ResizerTypes"
			EditorType="Enum"
			#tag EnumValues
				"0 - None"
				"1 - Horizontal"
				"2 - Vertical"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="Transparent"
			Group="Behavior"
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ResizerEnabled"
			Visible=true
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
