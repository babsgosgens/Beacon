#tag Module
Protected Module BeaconEncryption
	#tag Method, Flags = &h1
		Protected Function BlowfishDecrypt(Key As Xojo.Core.MemoryBlock, Data As Xojo.Core.MemoryBlock) As Xojo.Core.MemoryBlock
		  If Data.Size < BeaconEncryption.BlowfishHeader.Size Then
		    Dim Err As New Xojo.Crypto.CryptoException
		    Err.Reason = "Data is too short"
		    Raise Err
		  End If
		  
		  Dim Header As BeaconEncryption.BlowfishHeader = Data.Left(BeaconEncryption.BlowfishHeader.Size)
		  If Header.MagicByte <> BeaconEncryption.BlowfishMagicByte Then
		    Dim Err As New Xojo.Crypto.CryptoException
		    Err.Reason = "Data is not properly encrypted"
		    Raise Err
		  End If
		  If Header.Version > BeaconEncryption.BlowfishVersion Then
		    Dim Err As New Xojo.Crypto.CryptoException
		    Err.Reason = "Encryption is too new"
		    Raise Err
		  End If
		  
		  Data = Data.Mid(Header.Size)
		  
		  Dim Crypt As New M_Crypto.Blowfish_MTC(Beacon.ConvertMemoryBlock(Key))
		  Crypt.SetInitialVector(Beacon.ConvertMemoryBlock(Header.Vector))
		  Data = Beacon.ConvertMemoryBlock(Crypt.DecryptCBC(Beacon.ConvertMemoryBlock(Data)))
		  
		  Dim ComputedChecksum As UInt32 = Beacon.CRC32(Data)
		  If ComputedChecksum <> Header.Checksum Then
		    Dim Err As New Xojo.Crypto.CryptoException
		    Err.Reason = "CRC32 checksum failed on decrypted data."
		    Raise Err
		  End If
		  
		  Return Data
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function BlowfishEncrypt(Key As Xojo.Core.MemoryBlock, Data As Xojo.Core.MemoryBlock) As Xojo.Core.MemoryBlock
		  Dim Header As New BeaconEncryption.BlowfishHeader
		  Header.MagicByte = BlowfishMagicByte
		  Header.Version = BlowfishVersion
		  Header.Vector = Xojo.Crypto.GenerateRandomBytes(8)
		  Header.Length = Data.Size
		  Header.Checksum = Beacon.CRC32(Data)
		  
		  System.DebugLog("Checksum is " + Header.Checksum.ToText)
		  System.DebugLog("Checksum by MBS is " + CRC_32OfStrMBS(Beacon.ConvertMemoryBlock(Data)).ToText)
		  System.DebugLog("Header is " + Beacon.EncodeHex(Header))
		  
		  Dim Output As New Xojo.Core.MutableMemoryBlock(0)
		  Output.Append(Header)
		  
		  Dim Crypt As New M_Crypto.Blowfish_MTC(Beacon.ConvertMemoryBlock(Key))
		  Crypt.SetInitialVector(Beacon.ConvertMemoryBlock(Header.Vector))
		  Output.Append(Beacon.ConvertMemoryBlock(Crypt.EncryptCBC(Beacon.ConvertMemoryBlock(Data))))
		  
		  Return Output
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub GenerateKeyPair()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function PEMDecodePrivateKey(Key As Text) As Xojo.Core.MemoryBlock
		  Key = Key.Trim
		  Key = Key.ReplaceAll(Text.FromUnicodeCodepoint(13) + Text.FromUnicodeCodepoint(10), Text.FromUnicodeCodepoint(10))
		  Key = Key.ReplaceAll(Text.FromUnicodeCodepoint(13), Text.FromUnicodeCodepoint(10))
		  
		  Dim Lines() As Text = Key.Split(Text.FromUnicodeCodepoint(10))
		  If Lines(0).IndexOf("BEGIN RSA PRIVATE KEY") = -1 Or Lines(Lines.Ubound).IndexOf("END RSA PRIVATE KEY") = -1 Then
		    Dim Err As New Xojo.Crypto.CryptoException
		    Err.Reason = "Text does not appear to be a PEM-encoded private key"
		    Raise Err
		  End If
		  
		  Lines.Remove(0)
		  Lines.Remove(Lines.Ubound)
		  
		  Key = Text.Join(Lines, Text.FromUnicodeCodepoint(10))
		  
		  Return Xojo.Crypto.BERDecodePrivateKey(Beacon.DecodeBase64(Key))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function PEMDecodePublicKey(Key As Text) As Xojo.Core.MemoryBlock
		  Key = Key.Trim
		  Key = Key.ReplaceAll(Text.FromUnicodeCodepoint(13) + Text.FromUnicodeCodepoint(10), Text.FromUnicodeCodepoint(10))
		  Key = Key.ReplaceAll(Text.FromUnicodeCodepoint(13), Text.FromUnicodeCodepoint(10))
		  
		  Dim Lines() As Text = Key.Split(Text.FromUnicodeCodepoint(10))
		  If Lines(0).IndexOf("BEGIN PUBLIC KEY") = -1 Or Lines(Lines.Ubound).IndexOf("END PUBLIC KEY") = -1 Then
		    Dim Err As New Xojo.Crypto.CryptoException
		    Err.Reason = "Text does not appear to be a PEM-encoded public key"
		    Raise Err
		  End If
		  
		  Lines.Remove(0)
		  Lines.Remove(Lines.Ubound)
		  
		  Key = Text.Join(Lines, Text.FromUnicodeCodepoint(10))
		  
		  #Pragma BreakOnExceptions Off
		  Try
		    Return Xojo.Crypto.BERDecodePublicKey(Beacon.DecodeBase64(Key))
		  Catch Err As Xojo.Crypto.CryptoException
		    Return Xojo.Core.TextEncoding.UTF8.ConvertTextToData(Beacon.EncodeHex(Beacon.DecodeBase64(Key)))
		  End Try
		  #Pragma BreakOnExceptions Default
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function PEMEncodePrivateKey(Key As Xojo.Core.MemoryBlock) As Text
		  Dim Base64 As Text = Beacon.EncodeBase64(Xojo.Crypto.DEREncodePrivateKey(Key))
		  Dim Lines() As Text = Array("-----BEGIN RSA PRIVATE KEY-----")
		  While Base64.Length > 64
		    Lines.Append(Base64.Left(64))
		    Base64 = Base64.Mid(64)
		  Wend
		  If Base64.Length > 0 Then
		    Lines.Append(Base64)
		  End If
		  Lines.Append("-----END RSA PRIVATE KEY-----")
		  Return Text.Join(Lines, Text.FromUnicodeCodepoint(10))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function PEMEncodePublicKey(Key As Xojo.Core.MemoryBlock) As Text
		  Dim Base64 As Text = Beacon.EncodeBase64(Beacon.DecodeHex(Xojo.Core.TextEncoding.UTF8.ConvertDataToText(Key)))
		  Dim Lines() As Text = Array("-----BEGIN PUBLIC KEY-----")
		  While Base64.Length > 64
		    Lines.Append(Base64.Left(64))
		    Base64 = Base64.Mid(64)
		  Wend
		  If Base64.Length > 0 Then
		    Lines.Append(Base64)
		  End If
		  Lines.Append("-----END PUBLIC KEY-----")
		  Return Text.Join(Lines, Text.FromUnicodeCodepoint(10))
		End Function
	#tag EndMethod


	#tag Constant, Name = BlowfishLittleEndian, Type = Boolean, Dynamic = False, Default = \"False", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BlowfishMagicByte, Type = Double, Dynamic = False, Default = \"&h8A", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BlowfishVersion, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant


End Module
#tag EndModule
