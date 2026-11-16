; Inno Setup 6 script for De Donkere Nacht Remake (Processing desktop edition)

#ifndef ExportDir
  #define ExportDir "C:\Users\Aik Kuypers\.gemini\antigravity\scratch\DeDonkereNacht-Windows"
#endif

#ifndef OutputDir
  #define OutputDir "C:\Users\Aik Kuypers\.gemini\antigravity\scratch\ddn-release"
#endif

[Setup]
AppId={{8E9D5C42-7B3A-4F1D-9A62-3D2C1B8E4A10}
AppName=De Donkere Nacht Remake
AppVersion=1.0.0
AppVerName=De Donkere Nacht Remake 1.0.0
AppPublisher=Aik Kuypers
AppPublisherURL=https://github.com/aikkuypers2005/De-Donkere-Nacht-Remake
AppSupportURL=https://github.com/aikkuypers2005/De-Donkere-Nacht-Remake
AppUpdatesURL=https://github.com/aikkuypers2005/De-Donkere-Nacht-Remake/releases
DefaultDirName={localappdata}\Programs\De Donkere Nacht Remake
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
LicenseFile=..\LICENSE
SetupIconFile=icon.ico
UninstallDisplayIcon={app}\icon.ico
UninstallDisplayName=De Donkere Nacht Remake
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=DeDonkereNachtRemake-Setup-1.0.0

[Languages]
Name: "nl"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
en.PlayNow=Play De Donkere Nacht Remake now
nl.PlayNow=Play De Donkere Nacht Remake now

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#ExportDir}\DeDonkereNacht.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ExportDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#ExportDir}\lib\*"; DestDir: "{app}\lib"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#ExportDir}\java\*"; DestDir: "{app}\java"; Excludes: "jmods\*,src.zip,ct.sym"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\De Donkere Nacht Remake"; Filename: "{app}\DeDonkereNacht.exe"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"
Name: "{autodesktop}\De Donkere Nacht Remake"; Filename: "{app}\DeDonkereNacht.exe"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\DeDonkereNacht.exe"; WorkingDir: "{app}"; Description: "{cm:PlayNow}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: files; Name: "{app}\save.json"
