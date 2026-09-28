unit RoundedEdit;

{
  TRoundedEdit - Componente Edit com cantos arredondados para Delphi VCL
  ========================================================================
  Versao : 2.3
  Autor  : AntiGravity

  Correcoes:
    - FText: campo interno que armazena o texto com seguranca
    - Loaded: sincroniza FEdit.Text apos o DFM ser carregado
    - FUserOnChange: preserva o handler do usuario sem perder o interno
    - Design time: FEdit oculto, Paint desenha tudo
    - Run time   : FEdit visivel e centralizado verticalmente
}

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.Graphics,
  Vcl.Forms,
  Winapi.Windows,
  Winapi.Messages;

type
  TRoundedEdit = class(TCustomControl)
  private
    FEdit               : TEdit;

    { Campo que guarda o texto com seguranca (sync via Loaded) }
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

    { Wrappers TEdit - GetText/SetText ficam em 'protected override'
      pois TControl os declara como protected virtual }
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
    procedure UpdateEditBounds;
    procedure SyncEditColor;
    function  CalcEditHeight: Integer;

    procedure EditEnter(Sender: TObject);
    procedure EditExit(Sender: TObject);
    procedure EditChange(Sender: TObject);

  protected
    { GetText/SetText como protected override: evita conflito de vtable
      com TControl.GetText/SetText (protected virtual) no Delphi 13+ }
    function  GetText: TCaption; override;
    procedure SetText(const Value: TCaption); override;

    procedure Loaded; override;
    procedure Paint; override;
    procedure Resize; override;
    procedure SetEnabled(Value: Boolean); override;

    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure WMSetFocus(var Msg: TWMSetFocus); message WM_SETFOCUS;

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

  FEdit             := TEdit.Create(Self);
  FEdit.Parent      := Self;
  FEdit.BorderStyle := bsNone;
  FEdit.Color       := FFillColor;
  FEdit.TabStop     := False;
  FEdit.ParentFont  := True;
  FEdit.OnEnter     := EditEnter;
  FEdit.OnExit      := EditExit;
  FEdit.OnChange    := EditChange;

  { Design time: FEdit oculto (Paint desenha tudo).
    Run time   : FEdit visivel para edicao real. }
  FEdit.Visible := not (csDesigning in ComponentState);

  UpdateEditBounds;
end;

{ ---------------------------------------------------------------------------- }
{  Loaded - chamado APOS o DFM ser totalmente carregado                        }
{ ---------------------------------------------------------------------------- }

procedure TRoundedEdit.Loaded;
begin
  inherited;
  { Garante que FEdit.Text reflete o valor lido do DFM }
  if Assigned(FEdit) then
  begin
    FEdit.Text := FText;
    SyncEditColor;
  end;
  UpdateEditBounds;
  Invalidate;
end;

{ ---------------------------------------------------------------------------- }
{  Calculo de altura do texto                                                  }
{ ---------------------------------------------------------------------------- }

function TRoundedEdit.CalcEditHeight: Integer;
var
  TM : TTextMetric;
  DC : HDC;
begin
  DC := GetDC(0);
  try
    SelectObject(DC, Font.Handle);
    GetTextMetrics(DC, TM);
    Result := TM.tmHeight + TM.tmExternalLeading + 2;
  finally
    ReleaseDC(0, DC);
  end;
  if Result < 16 then Result := 16;
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
{  Paint                                                                       }
{ ---------------------------------------------------------------------------- }

procedure TRoundedEdit.Paint;
var
  R         : TRect;
  BorderClr : TColor;
  FillClr   : TColor;
  TextR     : TRect;
  Pad       : Integer;
  HasText   : Boolean;
  DrawStr   : string;
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

  { Texto e Placeholder }
  Pad     := FBorderWidth + 6;
  TextR   := Rect(Pad, 0, R.Right - Pad, R.Bottom);
  HasText := FText <> '';

  Canvas.Brush.Style := bsClear;

  if csDesigning in ComponentState then
  begin
    { Design time: desenha texto ou placeholder via Paint }
    Canvas.Font.Assign(Font);
    if HasText then
    begin
      Canvas.Font.Color := Font.Color;
      DrawStr := FText;
      if FEdit.PasswordChar <> #0 then
        DrawStr := StringOfChar(FEdit.PasswordChar, Length(DrawStr));
      DrawText(Canvas.Handle, PChar(DrawStr), -1, TextR,
               DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
    end
    else if FPlaceholderText <> '' then
    begin
      Canvas.Font.Color := FPlaceholderColor;
      DrawText(Canvas.Handle, PChar(FPlaceholderText), -1, TextR,
               DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
    end;
  end
  else
  begin
    { Run time: desenha placeholder quando vazio e sem foco }
    if (not HasText) and (FPlaceholderText <> '') and (not FFocused) then
    begin
      Canvas.Font.Assign(Font);
      Canvas.Font.Color := FPlaceholderColor;
      DrawText(Canvas.Handle, PChar(FPlaceholderText), -1, TextR,
               DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
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

procedure TRoundedEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  if Assigned(FEdit) then FEdit.Font.Assign(Font);
  UpdateEditBounds;
  Invalidate;
end;

procedure TRoundedEdit.WMSetFocus(var Msg: TWMSetFocus);
begin
  inherited;
  if Assigned(FEdit) and FEdit.CanFocus then
    FEdit.SetFocus;
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
  { Sincroniza FText com o que o usuario digitou }
  FText := FEdit.Text;
  if FPlaceholderText <> '' then Invalidate;
  { Dispara o handler do usuario (se houver) }
  if Assigned(FUserOnChange) then FUserOnChange(Self);
end;

{ ---------------------------------------------------------------------------- }
{  Wrappers TEdit                                                               }
{ ---------------------------------------------------------------------------- }

function TRoundedEdit.GetText: TCaption;
begin
  { Retorna FText (campo interno seguro) }
  Result := FText;
end;

procedure TRoundedEdit.SetText(const Value: TCaption);
begin
  if FText <> Value then
  begin
    FText := Value;
    if Assigned(FEdit) then
    begin
      { Bloqueia o EditChange para evitar loop }
      FEdit.OnChange := nil;
      FEdit.Text     := Value;
      FEdit.OnChange := EditChange;
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

{ OnChange usa FUserOnChange para nao sobrescrever EditChange }
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
