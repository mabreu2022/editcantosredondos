unit RoundedEditLaz;

{
  TRoundedEdit - Componente Edit com cantos arredondados para Lazarus LCL
  ========================================================================
  Versao : 1.0
  Autor  : AntiGravity

  Compatibilidade: Lazarus 2.x / 3.x (LCL), Windows / Linux / macOS

  Diferencas em relacao a versao Delphi VCL:
    - Usa LCLIntf / LCLType em vez de Winapi.Windows
    - Sem prefixo Vcl. nas units (Controls, StdCtrls, Graphics, Forms)
    - Foco gerenciado via DoEnter/DoExit (mais portatil que WM_SETFOCUS)
    - Texto desenhado via Canvas.TextRect com TTextStyle (cross-platform)
    - Altura do texto calculada via Canvas.TextHeight

  Como instalar no Lazarus:
    1. Abra o Lazarus
    2. Menu Package > Open Package File (.lpk)
    3. Selecione RoundedEditPkgLaz.lpk
    4. Na janela do pacote clique em Compile e depois Install
    5. O IDE sera reiniciado com o componente na aba AntiGravity

  Propriedades:
    Text, PasswordChar, MaxLength, ReadOnly, CharCase
    BorderColor, BorderColorFocused, BorderWidth, BorderRadius
    FillColor, FillColorFocused, PlaceholderText, PlaceholderColor
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  Controls, StdCtrls, Graphics, Forms,
  LCLIntf, LCLType, LMessages;

type
  TRoundedEdit = class(TCustomControl)
  private
    FEdit               : TEdit;
    FText               : string;
    FUserOnChange       : TNotifyEvent;

    FBorderColor        : TColor;
    FBorderColorFocused : TColor;
    FBorderWidth        : Integer;
    FBorderRadius       : Integer;
    FFillColor          : TColor;
    FFillColorFocused   : TColor;
    FPlaceholderText    : string;
    FPlaceholderColor   : TColor;
    FFocused            : Boolean;

    { Wrappers TEdit }
    function  GetText: string;
    procedure SetText(const Value: string);
    function  GetPasswordChar: Char;
    procedure SetPasswordChar(Value: Char);
    function  GetMaxLength: Integer;
    procedure SetMaxLength(Value: Integer);
    function  GetReadOnly: Boolean;
    procedure SetReadOnly(Value: Boolean);
    function  GetCharCase: TEditCharCase;
    procedure SetCharCase(Value: TEditCharCase);
    function  GetOnChange: TNotifyEvent;
    procedure SetOnChange(Value: TNotifyEvent);
    function  GetOnKeyDown: TKeyEvent;
    procedure SetOnKeyDown(Value: TKeyEvent);
    function  GetOnKeyUp: TKeyEvent;
    procedure SetOnKeyUp(Value: TKeyEvent);
    function  GetOnKeyPress: TKeyPressEvent;
    procedure SetOnKeyPress(Value: TKeyPressEvent);

    { Setters visuais }
    procedure SetBorderColor(const Value: TColor);
    procedure SetBorderColorFocused(const Value: TColor);
    procedure SetBorderWidth(const Value: Integer);
    procedure SetBorderRadius(const Value: Integer);
    procedure SetFillColor(const Value: TColor);
    procedure SetFillColorFocused(const Value: TColor);
    procedure SetPlaceholderText(const Value: string);
    procedure SetPlaceholderColor(const Value: TColor);

    { Interno }
    function  CalcEditHeight: Integer;
    procedure UpdateEditBounds;
    procedure SyncEditColor;

    procedure EditEnter(Sender: TObject);
    procedure EditExit(Sender: TObject);
    procedure EditChange(Sender: TObject);

  protected
    procedure Loaded; override;
    procedure CreateWnd; override;
    procedure Paint; override;
    procedure Resize; override;
    procedure SetEnabled(Value: Boolean); override;

    { LCL: DoEnter/DoExit sao mais portaveis que WM_SETFOCUS }
    procedure DoEnter; override;
    procedure DoExit; override;

    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;

  public
    constructor Create(AOwner: TComponent); override;
    procedure SetFocus; override;

    property InnerEdit: TEdit read FEdit;

  published
    property Text         : string        read GetText        write SetText;
    property PasswordChar : Char          read GetPasswordChar write SetPasswordChar default #0;
    property MaxLength    : Integer       read GetMaxLength    write SetMaxLength    default 0;
    property ReadOnly     : Boolean       read GetReadOnly     write SetReadOnly     default False;
    property CharCase     : TEditCharCase read GetCharCase     write SetCharCase     default ecNormal;

    property BorderColor        : TColor  read FBorderColor        write SetBorderColor        default clSilver;
    property BorderColorFocused : TColor  read FBorderColorFocused write SetBorderColorFocused default clHighlight;
    property BorderWidth        : Integer read FBorderWidth         write SetBorderWidth         default 2;
    property BorderRadius       : Integer read FBorderRadius        write SetBorderRadius        default 8;
    property FillColor          : TColor  read FFillColor          write SetFillColor          default clWhite;
    property FillColorFocused   : TColor  read FFillColorFocused   write SetFillColorFocused   default clWhite;
    property PlaceholderText    : string  read FPlaceholderText    write SetPlaceholderText;
    property PlaceholderColor   : TColor  read FPlaceholderColor   write SetPlaceholderColor   default clGrayText;

    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property Hint;
    property ParentFont;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;

    property OnChange   : TNotifyEvent   read GetOnChange    write SetOnChange;
    property OnKeyDown  : TKeyEvent      read GetOnKeyDown   write SetOnKeyDown;
    property OnKeyUp    : TKeyEvent      read GetOnKeyUp     write SetOnKeyUp;
    property OnKeyPress : TKeyPressEvent read GetOnKeyPress  write SetOnKeyPress;

    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AntiGravity', [TRoundedEdit]);
end;

{ ---------------------------------------------------------------------------- }
{  Constructor                                                                  }
{ ---------------------------------------------------------------------------- }

constructor TRoundedEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOpaque];

  FBorderColor        := clSilver;
  FBorderColorFocused := clHighlight;
  FBorderWidth        := 2;
  FBorderRadius       := 8;
  FFillColor          := clWhite;
  FFillColorFocused   := clWhite;
  FPlaceholderText    := '';
  FPlaceholderColor   := clGrayText;
  FFocused            := False;
  FText               := '';

  TabStop := True;
  Width   := 200;
  Height  := 36;

  { Cria o edit interno SEM definir Parent aqui!
    No Lazarus, setar Parent no constructor (sem handle) causa
    erro 'Controle nao tem janela pai'. O Parent sera definido
    em CreateWnd, apos o handle do container existir. }
  FEdit             := TEdit.Create(Self);
  FEdit.BorderStyle := bsNone;
  FEdit.Color       := FFillColor;
  FEdit.TabStop     := False;
  FEdit.ParentFont  := True;
  FEdit.OnEnter     := @EditEnter;
  FEdit.OnExit      := @EditExit;
  FEdit.OnChange    := @EditChange;
  FEdit.Visible     := not (csDesigning in ComponentState);
end;

{ ---------------------------------------------------------------------------- }
{  CreateWnd - seguro para configurar FEdit apos o handle existir             }
{ ---------------------------------------------------------------------------- }

procedure TRoundedEdit.CreateWnd;
begin
  inherited CreateWnd;
  { Agora Self tem handle: podemos setar o Parent do FEdit com seguranca }
  if Assigned(FEdit) and (FEdit.Parent = nil) then
  begin
    FEdit.Parent  := Self;
    FEdit.Visible := not (csDesigning in ComponentState);
    FEdit.Text    := FText;
    SyncEditColor;
    UpdateEditBounds;
  end;
end;

{ ---------------------------------------------------------------------------- }
{  Loaded - apos LFM ser carregado                                             }
{ ---------------------------------------------------------------------------- }

procedure TRoundedEdit.Loaded;
begin
  inherited;
  if Assigned(FEdit) then
  begin
    FEdit.Text := FText;
    SyncEditColor;
  end;
  UpdateEditBounds;
  Invalidate;
end;

{ ---------------------------------------------------------------------------- }
{  Calculo de altura do texto (cross-platform via Canvas)                      }
{ ---------------------------------------------------------------------------- }

function TRoundedEdit.CalcEditHeight: Integer;
begin
  { Usa Font.Height direto: seguro mesmo sem handle (nao usa Canvas) }
  Result := Abs(Font.Height);
  if Result <= 0 then Result := 13;
  Inc(Result, 6);
  if Result < 18 then Result := 18;
end;

{ ---------------------------------------------------------------------------- }
{  Posicionamento do FEdit interno                                              }
{ ---------------------------------------------------------------------------- }

procedure TRoundedEdit.UpdateEditBounds;
var
  HPad, VPos, EditH: Integer;
begin
  if not Assigned(FEdit) then Exit;

  HPad  := FBorderWidth + 6;
  EditH := CalcEditHeight;

  VPos := (Height - EditH) div 2;
  if VPos < FBorderWidth + 2 then
    VPos := FBorderWidth + 2;

  FEdit.SetBounds(HPad, VPos, Width - HPad * 2, EditH);
end;

procedure TRoundedEdit.SyncEditColor;
begin
  if not Assigned(FEdit) then Exit;
  if FFocused then
    FEdit.Color := FFillColorFocused
  else
    FEdit.Color := FFillColor;
end;

{ ---------------------------------------------------------------------------- }
{  Paint - cross-platform via LCL Canvas                                       }
{ ---------------------------------------------------------------------------- }

procedure TRoundedEdit.Paint;
var
  R         : TRect;
  TextR     : TRect;
  BorderClr : TColor;
  FillClr   : TColor;
  Pad       : Integer;
  HasText   : Boolean;
  DrawStr   : string;
  TS        : TTextStyle;
begin
  R := ClientRect;

  if FFocused then
  begin
    BorderClr := FBorderColorFocused;
    FillClr   := FFillColorFocused;
  end
  else
  begin
    BorderClr := FBorderColor;
    FillClr   := FFillColor;
  end;

  { Fundo arredondado }
  Canvas.Pen.Color   := FillClr;
  Canvas.Pen.Width   := 1;
  Canvas.Brush.Color := FillClr;
  Canvas.Brush.Style := bsSolid;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom,
                   FBorderRadius * 2, FBorderRadius * 2);

  { Borda arredondada }
  Canvas.Pen.Color   := BorderClr;
  Canvas.Pen.Width   := FBorderWidth;
  Canvas.Brush.Style := bsClear;
  Canvas.RoundRect(
    R.Left + (FBorderWidth div 2),
    R.Top  + (FBorderWidth div 2),
    R.Right  - (FBorderWidth div 2),
    R.Bottom - (FBorderWidth div 2),
    FBorderRadius * 2,
    FBorderRadius * 2
  );

  { Configuracao de estilo de texto (cross-platform LCL) }
  TS            := Canvas.TextStyle;
  TS.SingleLine := True;
  TS.Layout     := tlCenter;    { centraliza verticalmente }
  TS.Alignment  := taLeftJustify;
  TS.EndEllipsis:= True;
  TS.Opaque     := False;

  Pad     := FBorderWidth + 6;
  TextR   := Rect(Pad, 0, R.Right - Pad, R.Bottom);
  HasText := FText <> '';

  Canvas.Brush.Style := bsClear;

  if csDesigning in ComponentState then
  begin
    { Design time: Paint desenha texto ou placeholder }
    Canvas.Font.Assign(Font);
    if HasText then
    begin
      Canvas.Font.Color := Font.Color;
      DrawStr := FText;
      if FEdit.PasswordChar <> #0 then
        DrawStr := StringOfChar(FEdit.PasswordChar, Length(DrawStr));
      Canvas.TextRect(TextR, TextR.Left, TextR.Top, DrawStr, TS);
    end
    else if FPlaceholderText <> '' then
    begin
      Canvas.Font.Color := FPlaceholderColor;
      Canvas.TextRect(TextR, TextR.Left, TextR.Top, FPlaceholderText, TS);
    end;
  end
  else
  begin
    { Run time: apenas placeholder quando vazio e sem foco }
    if (not HasText) and (FPlaceholderText <> '') and (not FFocused) then
    begin
      Canvas.Font.Assign(Font);
      Canvas.Font.Color := FPlaceholderColor;
      Canvas.TextRect(TextR, TextR.Left, TextR.Top, FPlaceholderText, TS);
    end;
  end;
end;

{ ---------------------------------------------------------------------------- }
{  Eventos protegidos                                                          }
{ ---------------------------------------------------------------------------- }

procedure TRoundedEdit.Resize;
begin
  inherited;
  UpdateEditBounds;
end;

procedure TRoundedEdit.SetEnabled(Value: Boolean);
begin
  inherited;
  if Assigned(FEdit) then FEdit.Enabled := Value;
end;

{ LCL: DoEnter/DoExit sao o jeito portatil de tratar foco }
procedure TRoundedEdit.DoEnter;
begin
  inherited;
  if Assigned(FEdit) and FEdit.CanFocus then
    FEdit.SetFocus;
end;

procedure TRoundedEdit.DoExit;
begin
  inherited;
end;

procedure TRoundedEdit.CMFontChanged(var Message: TLMessage);
begin
  inherited;
  if Assigned(FEdit) then FEdit.Font.Assign(Font);
  UpdateEditBounds;
  Invalidate;
end;

procedure TRoundedEdit.SetFocus;
begin
  if Assigned(FEdit) and FEdit.CanFocus then
    FEdit.SetFocus
  else
    inherited;
end;

{ ---------------------------------------------------------------------------- }
{  Eventos do FEdit                                                             }
{ ---------------------------------------------------------------------------- }

procedure TRoundedEdit.EditEnter(Sender: TObject);
begin
  FFocused := True;
  SyncEditColor;
  Invalidate;
  if Assigned(OnEnter) then OnEnter(Self);
end;

procedure TRoundedEdit.EditExit(Sender: TObject);
begin
  FFocused := False;
  SyncEditColor;
  Invalidate;
  if Assigned(OnExit) then OnExit(Self);
end;

procedure TRoundedEdit.EditChange(Sender: TObject);
begin
  FText := FEdit.Text;
  if FPlaceholderText <> '' then Invalidate;
  if Assigned(FUserOnChange) then FUserOnChange(Self);
end;

{ ---------------------------------------------------------------------------- }
{  Wrappers TEdit                                                               }
{ ---------------------------------------------------------------------------- }

function TRoundedEdit.GetText: string;
begin Result := FText; end;

procedure TRoundedEdit.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    if Assigned(FEdit) then
    begin
      FEdit.OnChange := nil;
      FEdit.Text     := Value;
      FEdit.OnChange := @EditChange;
    end;
    Invalidate;
  end;
end;

function TRoundedEdit.GetPasswordChar: Char;
begin Result := FEdit.PasswordChar; end;

procedure TRoundedEdit.SetPasswordChar(Value: Char);
begin FEdit.PasswordChar := Value; Invalidate; end;

function TRoundedEdit.GetMaxLength: Integer;
begin Result := FEdit.MaxLength; end;

procedure TRoundedEdit.SetMaxLength(Value: Integer);
begin FEdit.MaxLength := Value; end;

function TRoundedEdit.GetReadOnly: Boolean;
begin Result := FEdit.ReadOnly; end;

procedure TRoundedEdit.SetReadOnly(Value: Boolean);
begin FEdit.ReadOnly := Value; end;

function TRoundedEdit.GetCharCase: TEditCharCase;
begin Result := FEdit.CharCase; end;

procedure TRoundedEdit.SetCharCase(Value: TEditCharCase);
begin FEdit.CharCase := Value; end;

function TRoundedEdit.GetOnChange: TNotifyEvent;
begin Result := FUserOnChange; end;

procedure TRoundedEdit.SetOnChange(Value: TNotifyEvent);
begin FUserOnChange := Value; end;

function TRoundedEdit.GetOnKeyDown: TKeyEvent;
begin Result := FEdit.OnKeyDown; end;

procedure TRoundedEdit.SetOnKeyDown(Value: TKeyEvent);
begin FEdit.OnKeyDown := Value; end;

function TRoundedEdit.GetOnKeyUp: TKeyEvent;
begin Result := FEdit.OnKeyUp; end;

procedure TRoundedEdit.SetOnKeyUp(Value: TKeyEvent);
begin FEdit.OnKeyUp := Value; end;

function TRoundedEdit.GetOnKeyPress: TKeyPressEvent;
begin Result := FEdit.OnKeyPress; end;

procedure TRoundedEdit.SetOnKeyPress(Value: TKeyPressEvent);
begin FEdit.OnKeyPress := Value; end;

{ ---------------------------------------------------------------------------- }
{  Setters visuais                                                              }
{ ---------------------------------------------------------------------------- }

procedure TRoundedEdit.SetBorderColor(const Value: TColor);
begin
  if FBorderColor <> Value then begin FBorderColor := Value; Invalidate; end;
end;

procedure TRoundedEdit.SetBorderColorFocused(const Value: TColor);
begin
  if FBorderColorFocused <> Value then begin FBorderColorFocused := Value; Invalidate; end;
end;

procedure TRoundedEdit.SetBorderWidth(const Value: Integer);
begin
  if FBorderWidth <> Value then
  begin FBorderWidth := Value; UpdateEditBounds; Invalidate; end;
end;

procedure TRoundedEdit.SetBorderRadius(const Value: Integer);
begin
  if FBorderRadius <> Value then begin FBorderRadius := Value; Invalidate; end;
end;

procedure TRoundedEdit.SetFillColor(const Value: TColor);
begin
  if FFillColor <> Value then
  begin FFillColor := Value; SyncEditColor; Invalidate; end;
end;

procedure TRoundedEdit.SetFillColorFocused(const Value: TColor);
begin
  if FFillColorFocused <> Value then
  begin FFillColorFocused := Value; SyncEditColor; Invalidate; end;
end;

procedure TRoundedEdit.SetPlaceholderText(const Value: string);
begin
  if FPlaceholderText <> Value then begin FPlaceholderText := Value; Invalidate; end;
end;

procedure TRoundedEdit.SetPlaceholderColor(const Value: TColor);
begin
  if FPlaceholderColor <> Value then begin FPlaceholderColor := Value; Invalidate; end;
end;

end.
