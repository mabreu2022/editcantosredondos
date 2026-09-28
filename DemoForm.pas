unit DemoForm;

{
  Formulario de demonstracao do TRoundedEdit
  Compile e execute diretamente para ver os exemplos em acao
}

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  RoundedEdit;

type
  TFormDemo = class(TForm)
  private
    FPanel      : TPanel;
    FTitle      : TLabel;
    FEdit1      : TRoundedEdit;
    FEdit2      : TRoundedEdit;
    FEdit3      : TRoundedEdit;
    FEdit4      : TRoundedEdit;
    FLbl1       : TLabel;
    FLbl2       : TLabel;
    FLbl3       : TLabel;
    FLbl4       : TLabel;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  FormDemo: TFormDemo;

implementation

constructor TFormDemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Caption    := 'Demo - TRoundedEdit (AntiGravity)';
  Width      := 480;
  Height     := 460;
  Position   := poScreenCenter;
  Color      := $00F5F5F5;

  // Painel de fundo
  FPanel             := TPanel.Create(Self);
  FPanel.Parent      := Self;
  FPanel.Align       := alClient;
  FPanel.BevelOuter  := bvNone;
  FPanel.Color       := $00F5F5F5;
  FPanel.Padding.SetBounds(32, 32, 32, 32);

  // Titulo
  FTitle             := TLabel.Create(Self);
  FTitle.Parent      := FPanel;
  FTitle.Caption     := 'TRoundedEdit - Demonstracao';
  FTitle.Font.Size   := 14;
  FTitle.Font.Style  := [fsBold];
  FTitle.Font.Color  := $00333333;
  FTitle.Top         := 16;
  FTitle.Left        := 32;

  // ---- Exemplo 1: padrao ----
  FLbl1            := TLabel.Create(Self);
  FLbl1.Parent     := FPanel;
  FLbl1.Caption    := 'Padrao (cinza / azul no foco):';
  FLbl1.Top        := 70;
  FLbl1.Left       := 32;
  FLbl1.Font.Size  := 9;
  FLbl1.Font.Color := $00555555;

  FEdit1                    := TRoundedEdit.Create(Self);
  FEdit1.Parent             := FPanel;
  FEdit1.Left               := 32;
  FEdit1.Top                := 90;
  FEdit1.Width              := 380;
  FEdit1.Height             := 36;
  FEdit1.BorderRadius       := 10;
  FEdit1.BorderWidth        := 2;
  FEdit1.BorderColor        := $00CCCCCC;
  FEdit1.BorderColorFocused := $004A90D9;
  FEdit1.PlaceholderText    := 'Digite seu nome...';
  FEdit1.Font.Size          := 10;

  // ---- Exemplo 2: raio maior ----
  FLbl2            := TLabel.Create(Self);
  FLbl2.Parent     := FPanel;
  FLbl2.Caption    := 'Raio grande (pill-style):';
  FLbl2.Top        := 150;
  FLbl2.Left       := 32;
  FLbl2.Font.Size  := 9;
  FLbl2.Font.Color := $00555555;

  FEdit2                    := TRoundedEdit.Create(Self);
  FEdit2.Parent             := FPanel;
  FEdit2.Left               := 32;
  FEdit2.Top                := 170;
  FEdit2.Width              := 380;
  FEdit2.Height             := 40;
  FEdit2.BorderRadius       := 20;
  FEdit2.BorderWidth        := 2;
  FEdit2.BorderColor        := $00AAAAAA;
  FEdit2.BorderColorFocused := $0027AE60;
  FEdit2.FillColor          := $00FFFFFF;
  FEdit2.PlaceholderText    := 'Buscar...';
  FEdit2.Font.Size          := 10;

  // ---- Exemplo 3: borda grossa colorida ----
  FLbl3            := TLabel.Create(Self);
  FLbl3.Parent     := FPanel;
  FLbl3.Caption    := 'Borda grossa com cor personalizada:';
  FLbl3.Top        := 235;
  FLbl3.Left       := 32;
  FLbl3.Font.Size  := 9;
  FLbl3.Font.Color := $00555555;

  FEdit3                    := TRoundedEdit.Create(Self);
  FEdit3.Parent             := FPanel;
  FEdit3.Left               := 32;
  FEdit3.Top                := 255;
  FEdit3.Width              := 380;
  FEdit3.Height             := 36;
  FEdit3.BorderRadius       := 8;
  FEdit3.BorderWidth        := 3;
  FEdit3.BorderColor        := $00E67E22;
  FEdit3.BorderColorFocused := $00E74C3C;
  FEdit3.PlaceholderText    := 'E-mail...';
  FEdit3.Font.Size          := 10;

  // ---- Exemplo 4: fundo colorido ----
  FLbl4            := TLabel.Create(Self);
  FLbl4.Parent     := FPanel;
  FLbl4.Caption    := 'Fundo colorido (claro / foco mais claro):';
  FLbl4.Top        := 315;
  FLbl4.Left       := 32;
  FLbl4.Font.Size  := 9;
  FLbl4.Font.Color := $00555555;

  FEdit4                    := TRoundedEdit.Create(Self);
  FEdit4.Parent             := FPanel;
  FEdit4.Left               := 32;
  FEdit4.Top                := 335;
  FEdit4.Width              := 380;
  FEdit4.Height             := 36;
  FEdit4.BorderRadius       := 10;
  FEdit4.BorderWidth        := 2;
  FEdit4.BorderColor        := $00C0392B;
  FEdit4.BorderColorFocused := $00922B21;
  FEdit4.FillColor          := $00FADBD8;
  FEdit4.FillColorFocused   := $00F5B7B1;
  FEdit4.PlaceholderText    := 'Senha...';
  FEdit4.PasswordChar       := '*';
  FEdit4.Font.Size          := 10;
end;

end.
