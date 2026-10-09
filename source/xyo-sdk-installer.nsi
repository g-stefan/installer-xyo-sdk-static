;--------------------------------
; XYO SDK Installer
;
; Created by Grigore Stefan <g_stefan@yahoo.com>
; Public domain (Unlicense) <http://unlicense.org>
; SPDX-FileCopyrightText: 2020-2024 Grigore Stefan <g_stefan@yahoo.com>
; SPDX-License-Identifier: Unlicense
;

;--------------------------------
; Configuration
;
; All names, versions and paths used by this script are defined here.

; Product
!define XYOSDKName "XYO SDK Static"
!define XYOSDKVersion "$%PRODUCT_VERSION%"
!define XYOSDKPlatform "win64-msvc-2026.static"
!define XYOSDKPlatformTitle "Win64-MSVC-2026.Static"
!define XYOSDKTitle "${XYOSDKName} v${XYOSDKVersion} ${XYOSDKPlatformTitle}"
!define XYOSDKPublisher "Grigore Stefan [ github.com/g-stefan ]"

; Code signing
!define SignTool "grigore-stefan.sign"
!define SignName "${XYOSDKName}"

; Build paths (relative to the project root, makensis is run with /NOCD)
!define SourceDir "source"
!define OutputDir "output"
!define TempDir "temp"
!define ReleaseDir "release"
!define ScriptFile "${SourceDir}\${__FILE__}"
!define InstallerFile "${ReleaseDir}\xyo-sdk.v${XYOSDKVersion}.${XYOSDKPlatform}.installer.exe"
!define DummyInstallerFile "${TempDir}\dummy-installer.exe"
!define LicenseFile "${OutputDir}\license.txt"
!define InstallerIcon "${SourceDir}\system-installer.ico"
!define UninstallerIcon "${SourceDir}\system-installer.ico"
!define InstallerWizardBitmap "${SourceDir}\xyo-installer-wizard.bmp"
!define UninstallerWizardBitmap "${SourceDir}\xyo-uninstaller-wizard.bmp"

; Install paths
!define SoftwareMainDir "\XYO\SDK\v${XYOSDKVersion}"
!define SoftwareSubDir "\${XYOSDKPlatform}"
!define SoftwareInstallDir "$PROGRAMFILES64${SoftwareMainDir}${SoftwareSubDir}"
!define SoftwareCheckFile "bin\fabricare.exe"
!define SoftwareIconFile "xyo.ico"
!define UninstallName "Uninstall"

; Registry
!define SoftwareRegKey "Software\XYO\SDK\v${XYOSDKVersion}.${XYOSDKPlatform}"
!define UninstallRegKey "Software\Microsoft\Windows\CurrentVersion\Uninstall\XYO-SDK.v${XYOSDKVersion}.${XYOSDKPlatformTitle}"

; User SDK path (under %USERPROFILE%)
!define UserSDKDir "$PathUserProfile\.fabricare\${XYOSDKPlatform}"

;--------------------------------

!include "MUI2.nsh"
!include "LogicLib.nsh"

; The name of the installer
Name "${XYOSDKTitle}"

; The file to write
OutFile "${InstallerFile}"

Unicode True
RequestExecutionLevel admin
BrandingText "${XYOSDKPublisher}"

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
!define MUI_ICON "${InstallerIcon}"
!define MUI_UNICON "${UninstallerIcon}"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${InstallerWizardBitmap}"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${UninstallerWizardBitmap}"

;--------------------------------
;Pages

!define MUI_COMPONENTSPAGE_SMALLDESC
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${LicenseFile}"
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
	OutFile "${DummyInstallerFile}"           ; not really important where this is
	SetCompress off                           ; for speed
!else
	!echo "Outer invocation"

	; Call makensis again against current file, defining INNER.  This writes an installer for us which, when
	; it is invoked, will just write the uninstaller to some location, and then exit.

	!makensis '/NOCD /DINNER "${ScriptFile}"' = 0

	; So now run that installer we just created as build\temp-installer.exe.  Since it
	; calls quit the return value isn't zero.

	!system 'set __COMPAT_LAYER=RunAsInvoker&"${DummyInstallerFile}"' = 2

	; That will have written an uninstaller binary for us.  Now we sign it with your
	; favorite code signing tool.

	!system '${SignTool} "${SignName}" "${TempDir}\${UninstallName}.exe"' = 0

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

Section "${XYOSDKName} (required)" MainSection

	SectionIn RO
	SetRegView 64

	WriteRegStr HKLM "${SoftwareRegKey}" "InstallPath" "$INSTDIR"

	; Write the uninstall keys for Windows
	WriteRegStr HKLM "${UninstallRegKey}" "DisplayName" "${XYOSDKTitle}"
	WriteRegStr HKLM "${UninstallRegKey}" "Publisher" "${XYOSDKPublisher}"
	WriteRegStr HKLM "${UninstallRegKey}" "DisplayVersion" "${XYOSDKVersion}"
	WriteRegStr HKLM "${UninstallRegKey}" "DisplayIcon" '"$INSTDIR\${SoftwareIconFile}"'
	WriteRegStr HKLM "${UninstallRegKey}" "UninstallString" '"$INSTDIR\${UninstallName}.exe"'
	WriteRegDWORD HKLM "${UninstallRegKey}" "NoModify" 1
	WriteRegDWORD HKLM "${UninstallRegKey}" "NoRepair" 1

	; Set output path to the installation directory.
	SetOutPath "$INSTDIR"

	; Program files
	File /r "${OutputDir}\*"

	; SDK directory
	ReadEnvStr $PathUserProfile USERPROFILE
	CreateDirectory "${UserSDKDir}\bin"
	CreateDirectory "${UserSDKDir}\include"
	CreateDirectory "${UserSDKDir}\lib"

; Uninstaller
!ifndef INNER
	SetOutPath "$INSTDIR"
	; this packages the signed uninstaller
	File "${TempDir}\${UninstallName}.exe"
!endif

	; Computing EstimatedSize
	Call GetInstalledSize
	Pop $0
	WriteRegDWORD HKLM "${UninstallRegKey}" "EstimatedSize" "$0"

	; Set to HKLM
	EnVar::SetHKLM

	; Set PATH
	EnVar::Check "PATH" "$INSTDIR\bin"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "PATH" "$INSTDIR\bin"
		Pop $0
	${EndIf}

	; Set INCLUDE
	EnVar::Check "INCLUDE" "$INSTDIR\include"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "INCLUDE" "$INSTDIR\include"
		Pop $0
	${EndIf}

	; Set LIB
	EnVar::Check "LIB" "$INSTDIR\lib"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "LIB" "$INSTDIR\lib"
		Pop $0
	${EndIf}	

	; Set to HKCU
	EnVar::SetHKCU

	ReadEnvStr $PathUserProfile USERPROFILE
	CreateDirectory "${UserSDKDir}"

	; Set PATH
	EnVar::Check "PATH" "${UserSDKDir}\bin"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "PATH" "${UserSDKDir}\bin"
		Pop $0
	${EndIf}

	; Set INCLUDE
	EnVar::Check "INCLUDE" "${UserSDKDir}\include"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "INCLUDE" "${UserSDKDir}\include"
		Pop $0
	${EndIf}

	; Set LIB
	EnVar::Check "LIB" "${UserSDKDir}\lib"
	Pop $0
	${If} $0 <> 0
		EnVar::AddValue "LIB" "${UserSDKDir}\lib"
		Pop $0
	${EndIf}	

SectionEnd

;--------------------------------
;Descriptions

;Language strings
LangString DESC_MainSection ${LANG_ENGLISH} "${XYOSDKName}"

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

	# Does path end with "${SoftwareSubDir}"?
	!define CHECK_PATH "${SoftwareSubDir}"
	StrLen $R1 "${CHECK_PATH}"
	StrCpy $R0 "$INSTDIR" "" -$R1
	StrCmp $R0 "${CHECK_PATH}" +3
		MessageBox MB_YESNO|MB_ICONQUESTION "${CHECK_PATH} - $R1 : $R0 - $INSTDIR - Unrecognised uninstall path. Continue anyway?" IDYES +2
		Abort

	IfFileExists "$INSTDIR\*.*" 0 +2
	IfFileExists "$INSTDIR\${SoftwareCheckFile}" +3
		MessageBox MB_OK|MB_ICONSTOP "Install path invalid!"
		Abort

	;--------------------------------
	; Do Uninstall

	SetOutPath $TEMP

	; Remove registry keys
	DeleteRegKey HKLM "${SoftwareRegKey}"
	DeleteRegKey HKLM "${UninstallRegKey}"

	; Remove files and uninstaller
	RMDir /r "$INSTDIR"

	; Set to HKLM
	EnVar::SetHKLM

	; Remove PATH
	EnVar::Check "PATH" "$INSTDIR\bin"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "PATH" "$INSTDIR\bin"
		Pop $0
	${EndIf}

	; Remove INCLUDE
	EnVar::Check "INCLUDE" "$INSTDIR\include"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "INCLUDE" "$INSTDIR\include"
		Pop $0
		EnVar::Update HKLM INCLUDE
		ReadEnvStr $0 INCLUDE
		${If} $0 == ""
			EnVar::Delete "INCLUDE"
			Pop $0
		${EndIf}
	${EndIf}

	; Remove LIB
	EnVar::Check "LIB" "$INSTDIR\lib"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "LIB" "$INSTDIR\lib"
		Pop $0
		EnVar::Update HKLM LIB
		ReadEnvStr $0 LIB
		${If} $0 == ""
			EnVar::Delete "LIB"
			Pop $0
		${EndIf}
	${EndIf}	

	; Set to HKCU
	EnVar::SetHKCU

	ReadEnvStr $PathUserProfile USERPROFILE

	; Remove PATH
	EnVar::Check "PATH" "${UserSDKDir}\bin"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "PATH" "${UserSDKDir}\bin"
		Pop $0
	${EndIf}

	; Remove INCLUDE
	EnVar::Check "INCLUDE" "${UserSDKDir}\include"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "INCLUDE" "${UserSDKDir}\include"
		Pop $0
		EnVar::Update HKCU INCLUDE
		ReadEnvStr $0 INCLUDE
		${If} $0 == ""
			EnVar::Delete "INCLUDE"
			Pop $0
		${EndIf}
	${EndIf}

	; Remove LIB
	EnVar::Check "LIB" "${UserSDKDir}\lib"
	Pop $0
	${If} $0 = 0
		EnVar::DeleteValue "LIB" "${UserSDKDir}\lib"
		Pop $0
		EnVar::Update HKCU LIB
		ReadEnvStr $0 LIB
		${If} $0 == ""
			EnVar::Delete "LIB"
			Pop $0
		${EndIf}
	${EndIf}

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

