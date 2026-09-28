; ============================================================================
;  TRoundedEdit - Inno Setup Script v2.3
;  Gera um instalador .exe que:
;    1. Copia fontes Delphi VCL e Lazarus LCL para pasta de instalacao
;    2. Adiciona o caminho ao Library Path de TODAS as versoes do Delphi
;       encontradas no registro (Win32, Win64)
;    3. Remove os caminhos ao desinstalar
;
;  Pre-requisito: Inno Setup 6.x  ->  https://jrsoftware.org/isinfo.php
;  Compilar: Abra este .iss no Inno Setup e pressione F9
; ============================================================================

#define AppName      "TRoundedEdit"
#define AppVersion   "2.3"
#define AppPublisher "AntiGravity"
#define AppURL       "https://github.com/mabreu2022/editcantosredondos"

[Setup]
AppId={{C7D3A1F2-84B0-4E5C-9F21-3A6E8B042D77}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} v{#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppPublisher}\{#AppName}
DefaultGroupName={#AppPublisher}\{#AppName}
AllowNoIcons=yes
OutputDir=Output
OutputBaseFilename=TRoundedEdit_Setup_v{#AppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ShowLanguageDialog=auto
UninstallDisplayIcon={app}\Delphi\RoundedEdit.pas

[Languages]
Name: "pt"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full";    Description: "Instalacao completa (Delphi + Lazarus)"
Name: "delphi";  Description: "Somente Delphi VCL"
Name: "lazarus"; Description: "Somente Lazarus LCL"
Name: "custom";  Description: "Personalizada"; Flags: iscustom

[Components]
Name: "delphi";  Description: "Componente Delphi VCL (RoundedEdit.pas)"; Types: full delphi
Name: "lazarus"; Description: "Componente Lazarus LCL (RoundedEditLaz.pas)"; Types: full lazarus

[Files]
; Delphi VCL
Source: "..\RoundedEdit.pas";      DestDir: "{app}\Delphi"; Components: delphi; Flags: ignoreversion
Source: "..\RoundedEditPkg.dpk";   DestDir: "{app}\Delphi"; Components: delphi; Flags: ignoreversion
Source: "..\RoundedEditPkg.dproj"; DestDir: "{app}\Delphi"; Components: delphi; Flags: ignoreversion

; Lazarus LCL
Source: "..\LazarusVersion\RoundedEditLaz.pas";    DestDir: "{app}\Lazarus"; Components: lazarus; Flags: ignoreversion
Source: "..\LazarusVersion\RoundedEditPkgLaz.lpk"; DestDir: "{app}\Lazarus"; Components: lazarus; Flags: ignoreversion

; Docs
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Fontes Delphi";  Filename: "{app}\Delphi"
Name: "{group}\Fontes Lazarus"; Filename: "{app}\Lazarus"
Name: "{group}\README";         Filename: "{app}\README.md"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"

[Code]
// --------------------------------------------------------------------------
//  Variaveis globais
// --------------------------------------------------------------------------
const
  EMBARCADERO_KEY = 'Software\Embarcadero\BDS';

var
  DelphiFoundCount: Integer;
  DelphiVersionsMsg: string;

// --------------------------------------------------------------------------
//  Retorna nome amigavel da versao BDS
// --------------------------------------------------------------------------
function GetDelphiName(const BDSVersion: string): string;
begin
  if      BDSVersion = '15.0' then Result := 'Delphi 10.2 Tokyo'
  else if BDSVersion = '16.0' then Result := 'Delphi 10.3 Rio'
  else if BDSVersion = '17.0' then Result := 'Delphi 10.4 Sydney'
  else if BDSVersion = '18.0' then Result := 'Delphi 11 Alexandria'
  else if BDSVersion = '19.0' then Result := 'Delphi 11.1'
  else if BDSVersion = '20.0' then Result := 'Delphi 11.2'
  else if BDSVersion = '21.0' then Result := 'Delphi 11.3'
  else if BDSVersion = '22.0' then Result := 'Delphi 11.x'
  else if BDSVersion = '23.0' then Result := 'Delphi 12 Athens'
  else if BDSVersion = '24.0' then Result := 'Delphi 13'
  else if BDSVersion = '25.0' then Result := 'Delphi 14'
  else Result := 'Delphi (BDS ' + BDSVersion + ')';
end;

// --------------------------------------------------------------------------
//  Adiciona caminho ao SearchPath de uma plataforma
// --------------------------------------------------------------------------
function AddPathToLibrary(const BDSVersion, Platform, NewPath: string): Boolean;
var
  RegKey, CurrentPath: string;
begin
  Result := False;
  RegKey := EMBARCADERO_KEY + '\' + BDSVersion + '\Library\' + Platform;
  if not RegKeyExists(HKCU, RegKey) then Exit;

  if not RegQueryStringValue(HKCU, RegKey, 'SearchPath', CurrentPath) then
    CurrentPath := '';

  if Pos(Lowercase(NewPath), Lowercase(CurrentPath)) > 0 then
  begin
    Result := True;
    Exit;
  end;

  if (Length(CurrentPath) > 0) and (CurrentPath[Length(CurrentPath)] <> ';') then
    CurrentPath := CurrentPath + ';';
  CurrentPath := CurrentPath + NewPath;
  Result := RegWriteStringValue(HKCU, RegKey, 'SearchPath', CurrentPath);
end;

// --------------------------------------------------------------------------
//  Varre BDS 12..30 e atualiza Library Path em todas as versoes encontradas
// --------------------------------------------------------------------------
procedure UpdateAllDelphiPaths(const SourcePath: string);
var
  i, j: Integer;
  BDSVersion, Platform, DelphiName: string;
  Platforms: array[0..1] of string;
  Updated: Boolean;
begin
  Platforms[0] := 'Win32';
  Platforms[1] := 'Win64';
  DelphiFoundCount := 0;
  DelphiVersionsMsg := '';

  for i := 12 to 30 do
  begin
    BDSVersion := IntToStr(i) + '.0';
    if not RegKeyExists(HKCU, EMBARCADERO_KEY + '\' + BDSVersion) then Continue;

    DelphiName := GetDelphiName(BDSVersion);
    Updated := False;
    for j := 0 to 1 do
    begin
      Platform := Platforms[j];
      if AddPathToLibrary(BDSVersion, Platform, SourcePath) then
        Updated := True;
    end;

    if Updated then
    begin
      Inc(DelphiFoundCount);
      DelphiVersionsMsg := DelphiVersionsMsg + #13#10 + '  [OK] ' + DelphiName;
    end;
  end;
end;

// --------------------------------------------------------------------------
//  Remove caminhos do Library Path ao desinstalar
// --------------------------------------------------------------------------
procedure RemoveFromLibraryPath(const RemovePath: string);
var
  i, j, Idx: Integer;
  BDSVersion, Platform, RegKey, CurrentPath: string;
  Platforms: array[0..1] of string;
begin
  Platforms[0] := 'Win32';
  Platforms[1] := 'Win64';

  for i := 12 to 30 do
  begin
    BDSVersion := IntToStr(i) + '.0';
    if not RegKeyExists(HKCU, EMBARCADERO_KEY + '\' + BDSVersion) then Continue;

    for j := 0 to 1 do
    begin
      Platform := Platforms[j];
      RegKey   := EMBARCADERO_KEY + '\' + BDSVersion + '\Library\' + Platform;
      if not RegQueryStringValue(HKCU, RegKey, 'SearchPath', CurrentPath) then Continue;

      Idx := Pos(Lowercase(RemovePath + ';'), Lowercase(CurrentPath));
      if Idx > 0 then Delete(CurrentPath, Idx, Length(RemovePath) + 1)
      else
      begin
        Idx := Pos(Lowercase(';' + RemovePath), Lowercase(CurrentPath));
        if Idx > 0 then Delete(CurrentPath, Idx, Length(RemovePath) + 1)
        else
        begin
          Idx := Pos(Lowercase(RemovePath), Lowercase(CurrentPath));
          if Idx > 0 then Delete(CurrentPath, Idx, Length(RemovePath));
        end;
      end;
      RegWriteStringValue(HKCU, RegKey, 'SearchPath', CurrentPath);
    end;
  end;
end;

// --------------------------------------------------------------------------
//  Pos-instalacao: adiciona Library Path e exibe resumo
// --------------------------------------------------------------------------
procedure CurStepChanged(CurStep: TSetupStep);
var
  Msg, DelphiDir: string;
begin
  if CurStep <> ssPostInstall then Exit;

  Msg := 'Instalacao concluida!' + #13#10 + #13#10;

  if IsComponentSelected('delphi') then
  begin
    DelphiDir := ExpandConstant('{app}\Delphi');
    UpdateAllDelphiPaths(DelphiDir);

    Msg := Msg + 'Delphi VCL instalado em:' + #13#10;
    Msg := Msg + '  ' + DelphiDir + #13#10 + #13#10;

    if DelphiFoundCount > 0 then
    begin
      Msg := Msg + 'Library Path adicionado em:' + DelphiVersionsMsg + #13#10 + #13#10;
      Msg := Msg + 'Proximos passos no Delphi:' + #13#10;
      Msg := Msg + '  1. Abra RoundedEditPkg.dproj' + #13#10;
      Msg := Msg + '  2. Clique em Build > Install' + #13#10;
      Msg := Msg + '  3. O componente aparecera na aba AntiGravity';
    end
    else
    begin
      Msg := Msg + 'ATENCAO: Nenhuma instalacao do Delphi encontrada.' + #13#10;
      Msg := Msg + 'Adicione manualmente ao Library Path:' + #13#10;
      Msg := Msg + '  Tools > Options > Library Path > ...' + #13#10;
      Msg := Msg + '  ' + DelphiDir;
    end;
  end;

  if IsComponentSelected('lazarus') then
  begin
    Msg := Msg + #13#10 + #13#10;
    Msg := Msg + 'Lazarus LCL instalado em:' + #13#10;
    Msg := Msg + '  ' + ExpandConstant('{app}\Lazarus') + #13#10 + #13#10;
    Msg := Msg + 'Proximos passos no Lazarus:' + #13#10;
    Msg := Msg + '  1. Package > Open Package File > RoundedEditPkgLaz.lpk' + #13#10;
    Msg := Msg + '  2. Compile > Use > Install';
  end;

  MsgBox(Msg, mbInformation, MB_OK);
end;

// --------------------------------------------------------------------------
//  Desinstalacao: remove do Library Path
// --------------------------------------------------------------------------
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RemoveFromLibraryPath(ExpandConstant('{app}\Delphi'));
end;
