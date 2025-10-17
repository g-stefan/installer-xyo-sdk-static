;--------------------------------
; XYO SDK Installer
;
; Created by Grigore Stefan <g_stefan@yahoo.com>
; Public domain (Unlicense) <http://unlicense.org>
; SPDX-FileCopyrightText: 2020-2024 Grigore Stefan <g_stefan@yahoo.com>
; SPDX-License-Identifier: Unlicense
;

!include "MUI2.nsh"
!include "LogicLib.nsh"

; The name of the installer
Name "XYO SDK Static"

; Version
!define XYOSDKVersion "$%PRODUCT_VERSION%"

; The file to write
OutFile "release\xyo-sdk-static-${XYOSDKVersion}-installer.exe"

Unicode True
RequestExecutionLevel admin
BrandingText "Grigore Stefan [ github.com/g-stefan ]"

!define SoftwareInstallDir "$PROGRAMFILES64\XYO"
!define SoftwareMainDir "\XYO"
!define SoftwareSubDir "\SDK.Static"
!define SoftwareRegKey "Software\XYO\SDK.Static"
!define UninstallRegKey "Software\Microsoft\Windows\CurrentVersion\Uninstall\XYO SDK Static"
!define UninstallName "Uninstall SDK.Static"

; The default installation directory
InstallDir "${SoftwareInstallDir}"

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "${SoftwareRegKey}" "InstallPath"

; Variables
Var PathUserProfile

;--------------------------------
;Interface Settings

!define MUI_ABORTWARNING
!define MUI_ICON "source\system-installer.ico"
!define MUI_UNICON "source\system-installer.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "source\xyo-installer-wizard.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "source\xyo-uninstaller-wizard.bmp"

;--------------------------------
;Pages

!define MUI_COMPONENTSPAGE_SMALLDESC
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "output\license.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!ifdef INNER
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH
!endif

;--------------------------------
;Languages

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Generate signed uninstaller
!ifdef INNER
	!echo "Inner invocation"                  ; just to see what's going on
	OutFile "temp\dummy-installer.exe"       ; not really important where this is
	SetCompress off                           ; for speed
!else
	!echo "Outer invocation"
 
	; Call makensis again against current file, defining INNER.  This writes an installer for us which, when
	; it is invoked, will just write the uninstaller to some location, and then exit.
 
	!makensis '/NOCD /DINNER "source\${__FILE__}"' = 0
 
	; So now run that installer we just created as build\temp-installer.exe.  Since it
	; calls quit the return value isn't zero.
 
	!system 'set __COMPAT_LAYER=RunAsInvoker&"temp\dummy-installer.exe"' = 2
 
	; That will have written an uninstaller binary for us.  Now we sign it with your
	; favorite code signing tool.
 
	!system 'grigore-stefan.sign "XYO SDK Static" "temp\${UninstallName}.exe"' = 0
 
	; Good.  Now we can carry on writing the real installer. 	 
!endif

;--------------------------------
;Signed uninstaller: Generate uninstaller only
Function .onInit
!ifdef INNER 
	; If INNER is defined, then we aren't supposed to do anything except write out
	; the uninstaller.  This is better than processing a command line option as it means
	; this entire code path is not present in the final (real) installer.
	SetSilent silent
	WriteUninstaller "$EXEDIR\${UninstallName}.exe"
	Quit  ; just bail out quickly when running the "inner" installer
!endif
FunctionEnd

;--------------------------------
;Installer Sections

Section "XYO SDK (required)" MainSection

	SectionIn RO
	SetRegView 64

	WriteRegStr HKLM "${SoftwareRegKey}" "InstallPath" "$INSTDIR"

	; Write the uninstall keys for Windows
	WriteRegStr HKLM "${UninstallRegKey}" "DisplayName" "XYO SDK Static"
	WriteRegStr HKLM "${UninstallRegKey}" "Publisher" "Grigore Stefan [ github.com/g-stefan ]"
	WriteRegStr HKLM "${UninstallRegKey}" "DisplayVersion" "${XYOSDKVersion}"
	WriteRegStr HKLM "${UninstallRegKey}" "DisplayIcon" '"$INSTDIR${SoftwareSubDir}\xyo.ico"'
	WriteRegStr HKLM "${UninstallRegKey}" "UninstallString" '"$INSTDIR\Uninstallers\${UninstallName}.exe"'
	WriteRegDWORD HKLM "${UninstallRegKey}" "NoModify" 1
	WriteRegDWORD HKLM "${UninstallRegKey}" "NoRepair" 1

	; Set output path to the installation directory.
	SetOutPath "$INSTDIR${SoftwareSubDir}"

	; Program files
	File /r "output\*"

	; SDK directory
	ReadEnvStr $PathUserProfile USERPROFILE
	CreateDirectory "$PathUserProfile\SDK.Static\bin"
	CreateDirectory "$PathUserProfile\SDK.Static\include"
	CreateDirectory "$PathUserProfile\SDK.Static\lib"

; Uninstaller
!ifndef INNER
	SetOutPath "$INSTDIR\Uninstallers"
	; this packages the signed uninstaller 
	File "temp\${UninstallName}.exe"
!endif

	; Computing EstimatedSize
	Call GetInstalledSize
	Pop $0
	WriteRegDWORD HKLM "${UninstallRegKey}" "EstimatedSize" "$0"

	; Set to HKLM
	EnVar::SetHKLM

	; Set PATH
	EnVar::Check "PATH" "$INSTDIR${SoftwareSubDir}\bin"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "PATH" "$INSTDIR${SoftwareSubDir}\bin"
		Pop $0
	${EndIf}

	; Set INCLUDE
	EnVar::Check "INCLUDE" "$INSTDIR${SoftwareSubDir}\include"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "INCLUDE" "$INSTDIR${SoftwareSubDir}\include"
		Pop $0
	${EndIf}

	; Set LIB
	EnVar::Check "LIB" "$INSTDIR${SoftwareSubDir}\lib"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "LIB" "$INSTDIR${SoftwareSubDir}\lib"
		Pop $0
	${EndIf}

	; Set XYO_PLATFORM
	EnVar::Delete "XYO_PLATFORM"
	Pop $0
	EnVar::AddValue "XYO_PLATFORM" "win64-msvc-2022.static"
	Pop $0

	; Set to HKCU
	EnVar::SetHKCU
	
	ReadEnvStr $PathUserProfile USERPROFILE
	CreateDirectory "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static"

	; Set PATH
	EnVar::Check "PATH" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\bin"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "PATH" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\bin"
		Pop $0
	${EndIf}

	; Set INCLUDE
	EnVar::Check "INCLUDE" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\include"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "INCLUDE" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\include"
		Pop $0
	${EndIf}

	; Set LIB
	EnVar::Check "LIB" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\lib"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "LIB" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\lib"
		Pop $0
	${EndIf}

	; Set XYO_PLATFORM_PATH
	EnVar::Delete "XYO_PLATFORM_PATH"
	Pop $0
	EnVar::AddValue "XYO_PLATFORM_PATH" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static"
	Pop $0

SectionEnd

;--------------------------------
;Descriptions

;Language strings
LangString DESC_MainSection ${LANG_ENGLISH} "XYO SDK Static"

;Assign language strings to sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
!insertmacro MUI_DESCRIPTION_TEXT ${MainSection} $(DESC_MainSection)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section
!ifdef INNER
Section "Uninstall"

	SetRegView 64

	;--------------------------------
	; Validating $INSTDIR before uninstall

	!macro BadPathsCheck
	StrCpy $R0 $INSTDIR "" -2
	StrCmp $R0 ":\" bad
	StrCpy $R0 $INSTDIR "" -14
	StrCmp $R0 "\Program Files" bad
	StrCpy $R0 $INSTDIR "" -8
	StrCmp $R0 "\Windows" bad
	StrCpy $R0 $INSTDIR "" -6
	StrCmp $R0 "\WinNT" bad
	StrCpy $R0 $INSTDIR "" -9
	StrCmp $R0 "\system32" bad
	StrCpy $R0 $INSTDIR "" -8
	StrCmp $R0 "\Desktop" bad
	StrCpy $R0 $INSTDIR "" -23
	StrCmp $R0 "\Documents and Settings" bad
	StrCpy $R0 $INSTDIR "" -13
	StrCmp $R0 "\My Documents" bad done
	bad:
	  MessageBox MB_OK|MB_ICONSTOP "Install path invalid!"
	  Abort
	done:
	!macroend
 
	ClearErrors
	ReadRegStr $INSTDIR HKLM "${SoftwareRegKey}" "InstallPath"
	IfErrors +2
	StrCmp $INSTDIR "" 0 +2
		StrCpy $INSTDIR "${SoftwareInstallDir}"
 
	# Check that the uninstall isn't dangerous.
	!insertmacro BadPathsCheck
 
	# Does path end with "${SoftwareMainDir}${SoftwareSubDir}"?
	!define CHECK_PATH "${SoftwareMainDir}"
	StrLen $R1 "${CHECK_PATH}"
	StrCpy $R0 "$INSTDIR" "" -$R1
	StrCmp $R0 "${CHECK_PATH}" +3
		MessageBox MB_YESNO|MB_ICONQUESTION "${CHECK_PATH} - $R1 : $R0 - $INSTDIR - Unrecognised uninstall path. Continue anyway?" IDYES +2
		Abort
 
	IfFileExists "$INSTDIR${SoftwareSubDir}\*.*" 0 +2
	IfFileExists "$INSTDIR${SoftwareSubDir}\bin\fabricare.exe" +3
		MessageBox MB_OK|MB_ICONSTOP "Install path invalid!"
		Abort

	;--------------------------------
	; Do Uninstall

	SetOutPath $TEMP

	; Remove registry keys
	DeleteRegKey HKLM "${SoftwareRegKey}"
	DeleteRegKey HKLM "${UninstallRegKey}"

	; Remove files and uninstaller
	RMDir /r "$INSTDIR${SoftwareSubDir}"
	Delete "$INSTDIR\Uninstallers\${UninstallName}.exe"
	RMDir "$INSTDIR\Uninstallers"
	RMDir "$INSTDIR"

	; Set to HKLM
	EnVar::SetHKLM

	; Remove PATH
	EnVar::Check "PATH" "$INSTDIR${SoftwareSubDir}\bin"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "PATH" "$INSTDIR${SoftwareSubDir}\bin"
		Pop $0
	${EndIf}

	; Remove INCLUDE
	EnVar::Check "INCLUDE" "$INSTDIR${SoftwareSubDir}\include"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "INCLUDE" "$INSTDIR${SoftwareSubDir}\include"
		Pop $0
		EnVar::Update HKLM INCLUDE
		ReadEnvStr $0 INCLUDE
		${If} $0 == ""
			EnVar::Delete "INCLUDE"
			Pop $0		
		${EndIf}
	${EndIf}

	; Remove LIB
	EnVar::Check "LIB" "$INSTDIR${SoftwareSubDir}\lib"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "LIB" "$INSTDIR${SoftwareSubDir}\lib"
		Pop $0
		EnVar::Update HKLM LIB
		ReadEnvStr $0 LIB
		${If} $0 == ""
			EnVar::Delete "LIB"
			Pop $0		
		${EndIf}
	${EndIf}

	; Remove XYO_PLATFORM
	EnVar::Delete "XYO_PLATFORM"
	Pop $0

	; Set to HKCU
	EnVar::SetHKCU

	ReadEnvStr $PathUserProfile USERPROFILE

	; Remove PATH
	EnVar::Check "PATH" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\bin"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "PATH" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\bin"
		Pop $0
	${EndIf}

	; Remove INCLUDE
	EnVar::Check "INCLUDE" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\include"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "INCLUDE" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\include"
		Pop $0
		EnVar::Update HKCU INCLUDE
		ReadEnvStr $0 INCLUDE
		${If} $0 == ""
			EnVar::Delete "INCLUDE"
			Pop $0		
		${EndIf}
	${EndIf}

	; Remove LIB
	EnVar::Check "LIB" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\lib"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "LIB" "$PathUserProfile\.xyo-sdk\win64-msvc-2022.static\lib"
		Pop $0
		EnVar::Update HKCU LIB
		ReadEnvStr $0 LIB
		${If} $0 == ""
			EnVar::Delete "LIB"
			Pop $0		
		${EndIf}
	${EndIf}

	; Remove XYO_PLATFORM_PATH
	EnVar::Delete "XYO_PLATFORM_PATH"
	Pop $0

SectionEnd
!endif

;--------------------------------
;Functions

; Return on top of stack the total size of the selected (installed) sections, formated as DWORD
Var GetInstalledSize.total
Function GetInstalledSize
	StrCpy $GetInstalledSize.total 0

	${if} ${SectionIsSelected} ${MainSection}
		SectionGetSize ${MainSection} $0
		IntOp $GetInstalledSize.total $GetInstalledSize.total + $0
	${endif}
 
	IntFmt $GetInstalledSize.total "0x%08X" $GetInstalledSize.total
	Push $GetInstalledSize.total
FunctionEnd

