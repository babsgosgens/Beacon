#tag Class
Protected Class LinkLabel
Inherits Label
	#tag Event
		Function MouseDown(X As Integer, Y As Integer) As Boolean
		  #Pragma Unused X
		  #Pragma Unused Y
		  
		  If Self.mShowAsLink Then
		    Self.TextColor = SystemColors.SystemRedColor
		    Return True
		  End If
		End Function
	#tag EndEvent

	#tag Event
		Sub MouseDrag(X As Integer, Y As Integer)
		  If X >= 0 And X <= Self.Width And Y >= 0 And Y <= Self.Height Then
		    Self.TextColor = SystemColors.SystemRedColor
		    #if BeaconUI.CursorsEnabled
		      Self.MouseCursor = System.Cursors.FingerPointer
		    #endif
		  Else
		    Self.TextColor = SystemColors.LinkColor
		    #if BeaconUI.CursorsEnabled
		      Self.MouseCursor = System.Cursors.StandardPointer
		    #endif
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub MouseEnter()
		  #if BeaconUI.CursorsEnabled
		    Self.MouseCursor = System.Cursors.FingerPointer
		  #endif
		End Sub
	#tag EndEvent

	#tag Event
		Sub MouseUp(X As Integer, Y As Integer)
		  If X >= 0 And X <= Self.Width And Y >= 0 And Y <= Self.Height Then
		    RaiseEvent Action
		    Self.TextColor = SystemColors.LinkColor
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub Open()
		  Self.ShowAsLink = Self.ShowAsLink
		  RaiseEvent Open
		End Sub
	#tag EndEvent


	#tag Hook, Flags = &h0
		Event Action()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Open()
	#tag EndHook


	#tag Property, Flags = &h21
		Private mShowAsLink As Boolean = True
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mShowAsLink
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Self.mShowAsLink = Value
			  
			  If Self.mShowAsLink Then
			    Self.TextColor = SystemColors.LinkColor
			    Self.Underline = True
			  Else
			    Self.TextColor = SystemColors.LabelColor
			    Self.Underline = False
			  End If
			End Set
		#tag EndSetter
		ShowAsLink As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		URL As String
	#tag EndProperty


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
			Name="TabStop"
			Visible=true
			Group="Position"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Height"
			Visible=true
			Group="Position"
			InitialValue="20"
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
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockLeft"
			Visible=true
			Group="Position"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockRight"
			Visible=true
			Group="Position"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockTop"
			Visible=true
			Group="Position"
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
			Name="Top"
			Visible=true
			Group="Position"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Width"
			Visible=true
			Group="Position"
			InitialValue="100"
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
			Name="Multiline"
			Visible=true
			Group="Appearance"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Selectable"
			Visible=true
			Group="Appearance"
			InitialValue="False"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Text"
			Visible=true
			Group="Appearance"
			InitialValue="Untitled"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TextAlign"
			Visible=true
			Group="Appearance"
			InitialValue="0"
			Type="Integer"
			EditorType="Enum"
			#tag EnumValues
				"0 - Left"
				"1 - Center"
				"2 - Right"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="TextColor"
			Group="Appearance"
			Type="Color"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Transparent"
			Visible=true
			Group="Appearance"
			InitialValue="False"
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Visible"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Bold"
			Visible=true
			Group="Font"
			InitialValue="False"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Italic"
			Visible=true
			Group="Font"
			InitialValue="False"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TextFont"
			Visible=true
			Group="Font"
			InitialValue="System"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TextSize"
			Visible=true
			Group="Font"
			InitialValue="0"
			Type="Single"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TextUnit"
			Visible=true
			Group="Font"
			InitialValue="0"
			Type="FontUnits"
			EditorType="Enum"
			#tag EnumValues
				"0 - Default"
				"1 - Pixel"
				"2 - Point"
				"3 - Inch"
				"4 - Millimeter"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="Underline"
			Visible=true
			Group="Font"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataField"
			Visible=true
			Group="Database Binding"
			Type="String"
			EditorType="DataField"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataSource"
			Visible=true
			Group="Database Binding"
			Type="String"
			EditorType="DataSource"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ShowAsLink"
			Visible=true
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="URL"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
