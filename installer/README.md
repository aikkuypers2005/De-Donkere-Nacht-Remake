# Windows Installer (Inno Setup 6)

This folder contains the Inno Setup 6 script (`DeDonkereNachtRemake.iss`) and multi-size zombie icon (`icon.ico` at 16x16, 32x32, 48x48, and 256x256) used to build `DeDonkereNachtRemake-Setup-1.0.0.exe`.

## How to rebuild the installer

### 1. Export the Processing sketch for Windows (64-bit)

```powershell
& "C:\Program Files\Processing\Processing.exe" cli `
  --sketch="$PWD\processing\DeDonkereNacht" `
  --output="C:\Users\Aik Kuypers\.gemini\antigravity\scratch\DeDonkereNacht-Windows" `
  --force --variant=windows-amd64 --export
```

*(Optional)* To embed `icon.ico` directly into the exported `DeDonkereNacht.exe` launcher via Processing's bundled Launch4j:

```powershell
$l4jDir = "C:\Program Files\Processing\app\resources\modes\java\application\launch4j"
$expDir = "C:\Users\Aik Kuypers\.gemini\antigravity\scratch\DeDonkereNacht-Windows"
$icoPath = "$PWD\installer\icon.ico"
$jars = Get-ChildItem "$expDir\lib\*.jar" | ForEach-Object { "    <cp>%EXEDIR%\lib\$($_.Name)</cp>" }
$xml = @"
<launch4jConfig>
  <headerType>gui</headerType>
  <dontWrapJar>true</dontWrapJar>
  <chdir>.</chdir>
  <downloadUrl>https://adoptium.net/</downloadUrl>
  <outfile>$expDir\DeDonkereNacht.exe</outfile>
  <icon>$icoPath</icon>
  <classPath>
    <mainClass>DeDonkereNacht</mainClass>
$($jars -join "`r`n")
  </classPath>
  <jre>
    <path>java;%PATH%</path>
    <minVersion>17</minVersion>
    <opt>-Djna.nosys=true</opt>
    <opt>-Djava.library.path="%EXEDIR%\lib"</opt>
  </jre>
</launch4jConfig>
"@
Set-Content -Path "$expDir\launch4j-custom.xml" -Value $xml -Encoding UTF8
& "C:\Program Files\Processing\app\resources\jdk\bin\java.exe" -cp "$l4jDir\launch4j.jar;$l4jDir\lib\xstream.jar" net.sf.launch4j.Main "$expDir\launch4j-custom.xml"
Remove-Item "$expDir\launch4j-custom.xml"
```

### 2. Build the Setup `.exe` with Inno Setup (`ISCC.exe`)

```powershell
& "C:\Users\Aik Kuypers\.gemini\antigravity\scratch\tools\InnoSetup\ISCC.exe" `
  "/DExportDir=C:\Users\Aik Kuypers\.gemini\antigravity\scratch\DeDonkereNacht-Windows" `
  "/DOutputDir=C:\Users\Aik Kuypers\.gemini\antigravity\scratch\ddn-release" `
  "installer\DeDonkereNachtRemake.iss"
```

This outputs `C:\Users\Aik Kuypers\.gemini\antigravity\scratch\ddn-release\DeDonkereNachtRemake-Setup-1.0.0.exe`.
