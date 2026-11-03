; Duskrail - modern Inno Setup 6 installer
; Build: ISCC.exe /DAppVersion=alpha1.0 Duskrail.iss
; Requires Inno Setup 6.7+ for dynamic dark mode and custom backgrounds.

#define AppName "Duskrail"
#define AppNameCN "暮轨"
#define AppPublisher "Duskrail Studio"
#define AppExeName "Duskrail.exe"
#define AppCopyright "Copyright (C) 2026 Duskrail Studio"
#define ProjectRoot AddBackslash(SourcePath) + "..\.."
#define SourceDir ProjectRoot + "\train-sim\build\windows"
#define OutputDir ProjectRoot + "\dist"
#define AssetsDir AddBackslash(SourcePath) + "assets"
#define LangFile AddBackslash(SourcePath) + "ChineseSimplified.isl"
#define LicenseFile AddBackslash(SourcePath) + "LICENSE.txt"

#ifndef AppVersion
  #define AppVersion "alpha1.0"
#endif
#ifndef AppVersionNumeric
  #define AppVersionNumeric "0.1.0.0"
#endif

[Setup]
AppId={{3FBCBFBC-6E4E-4315-95E9-743096164988}
AppName={#AppName} {#AppNameCN}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppNameCN} {#AppVersion}
AppPublisher={#AppPublisher}
AppCopyright={#AppCopyright}
DefaultDirName={localappdata}\Programs\Duskrail
DefaultGroupName=Duskrail
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename=Duskrail-Setup-{#AppVersion}
SetupIconFile={#AssetsDir}\Duskrail.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName} {#AppNameCN}
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes
WizardStyle=modern dynamic
WizardSizePercent=120
DisableWelcomePage=no
LicenseFile={#LicenseFile}
WizardImageFile={#AssetsDir}\wizard-large-202.png,{#AssetsDir}\wizard-large-269.png,{#AssetsDir}\wizard-large-336.png,{#AssetsDir}\wizard-large-403.png,{#AssetsDir}\wizard-large-430.png,{#AssetsDir}\wizard-large-498.png,{#AssetsDir}\wizard-large-534.png
WizardImageFileDynamicDark={#AssetsDir}\wizard-large-202.png,{#AssetsDir}\wizard-large-269.png,{#AssetsDir}\wizard-large-336.png,{#AssetsDir}\wizard-large-403.png,{#AssetsDir}\wizard-large-430.png,{#AssetsDir}\wizard-large-498.png,{#AssetsDir}\wizard-large-534.png
WizardSmallImageFile={#AssetsDir}\wizard-small-58.png,{#AssetsDir}\wizard-small-77.png,{#AssetsDir}\wizard-small-97.png,{#AssetsDir}\wizard-small-116.png,{#AssetsDir}\wizard-small-124.png,{#AssetsDir}\wizard-small-143.png,{#AssetsDir}\wizard-small-159.png
WizardSmallImageFileDynamicDark={#AssetsDir}\wizard-small-58.png,{#AssetsDir}\wizard-small-77.png,{#AssetsDir}\wizard-small-97.png,{#AssetsDir}\wizard-small-116.png,{#AssetsDir}\wizard-small-124.png,{#AssetsDir}\wizard-small-143.png,{#AssetsDir}\wizard-small-159.png
WizardImageStretch=yes
WizardSmallImageBackColor=#0B1220
WizardSmallImageBackColorDynamicDark=#0B1220
WizardImageBackColor=#0B1220
WizardImageBackColorDynamicDark=#0B1220
WizardBackImageFile={#AssetsDir}\back-light-596.png,{#AssetsDir}\back-light-796.png,{#AssetsDir}\back-light-994.png,{#AssetsDir}\back-light-1193.png,{#AssetsDir}\back-light-1272.png,{#AssetsDir}\back-light-1471.png,{#AssetsDir}\back-light-1630.png
WizardBackImageFileDynamicDark={#AssetsDir}\back-dark-596.png,{#AssetsDir}\back-dark-796.png,{#AssetsDir}\back-dark-994.png,{#AssetsDir}\back-dark-1193.png,{#AssetsDir}\back-dark-1272.png,{#AssetsDir}\back-dark-1471.png,{#AssetsDir}\back-dark-1630.png
WizardBackColor=#F7F8FA
WizardBackColorDynamicDark=#0A0F16
DisableReadyPage=yes
DisableStartupPrompt=yes
DisableDirPage=auto
UsePreviousAppDir=yes
CloseApplications=yes
RestartApplications=no
SetupLogging=yes
ArchitecturesAllowed=x64compatible
MinVersion=10.0
VersionInfoVersion={#AppVersionNumeric}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription=Duskrail 暮轨 安装程序
VersionInfoProductName={#AppName} {#AppNameCN}
VersionInfoCopyright={#AppCopyright}

[Languages]
Name: "chs"; MessagesFile: "{#LangFile}"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务："; Flags: checkedonce

[Files]
Source: "{#SourceDir}\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\Duskrail.pck"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\Duskrail.console.exe"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\*.license.txt"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\3rd-party-licenses.md"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\README.txt"; DestDir: "{app}"; Flags: ignoreversion

[InstallDelete]
; Remove leftovers from the previous NSIS installer; user data is kept.
Type: files; Name: "{group}\Duskrail.lnk"
Type: files; Name: "{group}\卸载 Duskrail.lnk"
Type: files; Name: "{autodesktop}\Duskrail.lnk"
Type: files; Name: "{app}\Uninstall.exe"

[Icons]
Name: "{group}\Duskrail 暮轨"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Comment: "启动 Duskrail 暮轨"
Name: "{group}\说明文档"; Filename: "{app}\README.txt"; IconFilename: "{app}\{#AppExeName}"; Comment: "查看操作说明"
Name: "{group}\卸载 Duskrail 暮轨"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Duskrail 暮轨"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "启动 Duskrail 暮轨"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: dirifempty; Name: "{app}"

[Code]
var
  WarningPage: TWizardPage;
  WarningText: TNewStaticText;
  WarningKnown: TNewRadioButton;
  WarningUnknown: TNewRadioButton;
  WarningHint: TNewStaticText;

procedure WarningChoiceChanged(Sender: TObject);
begin
  if WarningKnown = nil then
    Exit;
  WizardForm.NextButton.Enabled := WarningKnown.Checked;
  if WarningUnknown.Checked then
    WarningHint.Caption := '你选择了“我不知晓”。请关闭安装程序，或在了解风险后改选“我已知晓”。'
  else
    WarningHint.Caption := '';
end;

procedure InitializeWizard();
begin
  WizardForm.WelcomeLabel1.Caption := '安装 Duskrail 暮轨';
  WizardForm.WelcomeLabel2.Caption :=
    '一款以中国铁路为背景的 3D 铁路运输模拟游戏。' + #13#10 + #13#10 +
    '安装到当前用户目录，无需管理员权限。' + #13#10 + #13#10 +
    '版本 {#AppVersion} · Windows 64 位';

  WizardForm.FinishedHeadingLabel.Caption := 'Duskrail 暮轨 安装完成';
  WizardForm.FinishedLabel.Caption :=
    '感谢安装。桌面与开始菜单快捷方式已创建。' + #13#10 + #13#10 +
    '祝你在暮色中一路顺风。';

  WizardForm.NextButton.Caption := '下一步';
  WizardForm.BackButton.Caption := '上一步';
  WizardForm.CancelButton.Caption := '取消';

  WarningPage := CreateCustomPage(wpLicense, '光敏性癫痫警告',
    '请阅读以下安全提示，选择“我已知晓”后继续安装。');

  WarningText := TNewStaticText.Create(WarningPage);
  WarningText.Parent := WarningPage.Surface;
  WarningText.Left := 0;
  WarningText.Top := 0;
  WarningText.Width := WarningPage.SurfaceWidth;
  WarningText.Height := WarningPage.SurfaceHeight - 118;
  WarningText.AutoSize := False;
  WarningText.WordWrap := True;
  WarningText.Caption :=
    '本游戏包含闪烁灯光、快速变化的画面和高对比度场景。' + #13#10 + #13#10 +
    '部分人群在接触这类内容时可能出现光敏性癫痫发作。若你或家人有癫痫史，请在游玩前咨询医生。' + #13#10 + #13#10 +
    '游戏中如出现头晕、视力模糊、肌肉抽搐或意识模糊，请立即停止游戏并就医。建议在光线充足的环境中游玩，并适当降低屏幕亮度。';

  WarningKnown := TNewRadioButton.Create(WarningPage);
  WarningKnown.Parent := WarningPage.Surface;
  WarningKnown.Left := 0;
  WarningKnown.Top := WarningText.Top + WarningText.Height + 10;
  WarningKnown.Width := WarningPage.SurfaceWidth;
  WarningKnown.Caption := '我已知晓，继续安装';
  WarningKnown.OnClick := @WarningChoiceChanged;

  WarningUnknown := TNewRadioButton.Create(WarningPage);
  WarningUnknown.Parent := WarningPage.Surface;
  WarningUnknown.Left := 0;
  WarningUnknown.Top := WarningKnown.Top + 30;
  WarningUnknown.Width := WarningPage.SurfaceWidth;
  WarningUnknown.Caption := '我不知晓';
  WarningUnknown.OnClick := @WarningChoiceChanged;

  WarningHint := TNewStaticText.Create(WarningPage);
  WarningHint.Parent := WarningPage.Surface;
  WarningHint.Left := 0;
  WarningHint.Top := WarningUnknown.Top + 34;
  WarningHint.Width := WarningPage.SurfaceWidth;
  WarningHint.Height := 34;
  WarningHint.AutoSize := False;
  WarningHint.WordWrap := True;
  WarningHint.Font.Color := clRed;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = WarningPage.ID then
  begin
    WizardForm.NextButton.Caption := '下一步';
    WizardForm.NextButton.Enabled := WarningKnown.Checked;
  end
  else
  begin
    WizardForm.NextButton.Enabled := True;
    if CurPageID = wpFinished then
      WizardForm.NextButton.Caption := '完成'
    else
      WizardForm.NextButton.Caption := '下一步';
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Old NSIS uninstall entries would otherwise leave a duplicate app in
    // Windows Settings.
    RegDeleteKeyIncludingSubkeys(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\Duskrail');
    RegDeleteKeyIncludingSubkeys(HKCU, 'Software\Duskrail');
  end;
end;
