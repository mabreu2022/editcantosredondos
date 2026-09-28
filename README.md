# TRoundedEdit — Edit com Cantos Arredondados

Componente `TRoundedEdit` para **Delphi VCL** e **Lazarus LCL** que substitui o `TEdit` padrão com cantos arredondados, borda colorida configurável, cor de foco e suporte a placeholder.

---

## ✨ Funcionalidades

- Borda com cantos arredondados (raio configurável)
- Cor de borda diferente no estado normal e com foco
- Preenchimento de fundo personalizado (normal e foco)
- Texto placeholder com cor customizável
- Texto centralizado verticalmente em qualquer altura
- Suporte a PasswordChar, MaxLength, ReadOnly, CharCase
- Funciona em **design time** (texto e placeholder visíveis no IDE)
- Versão **Delphi VCL** e **Lazarus LCL** (cross-platform)

---

## 📁 Estrutura

```
EditCantosRedondos/
├── RoundedEdit.pas          ← Componente Delphi VCL (v2.2)
├── RoundedEditPkg.dpk       ← Pacote Delphi (Design Time)
├── RoundedEditPkg.dproj     ← Projeto Delphi
├── DemoForm.pas             ← Formulário de demonstração
└── LazarusVersion/
    ├── RoundedEditLaz.pas   ← Componente Lazarus LCL (v1.0)
    └── RoundedEditPkgLaz.lpk ← Pacote Lazarus (Design Time)
```

---

## 🔧 Propriedades

| Propriedade | Tipo | Padrão | Descrição |
|---|---|---|---|
| `Text` | `string` | `''` | Texto do campo |
| `BorderRadius` | `Integer` | `8` | Raio dos cantos (px) |
| `BorderWidth` | `Integer` | `2` | Espessura da borda (px) |
| `BorderColor` | `TColor` | `clSilver` | Cor da borda normal |
| `BorderColorFocused` | `TColor` | `clHighlight` | Cor da borda com foco |
| `FillColor` | `TColor` | `clWhite` | Cor de fundo |
| `FillColorFocused` | `TColor` | `clWhite` | Cor de fundo com foco |
| `PlaceholderText` | `string` | `''` | Texto de dica |
| `PlaceholderColor` | `TColor` | `clGrayText` | Cor do placeholder |
| `PasswordChar` | `Char` | `#0` | Caractere de máscara |
| `MaxLength` | `Integer` | `0` | Limite de caracteres |
| `ReadOnly` | `Boolean` | `False` | Somente leitura |
| `CharCase` | `TEditCharCase` | `ecNormal` | Caixa do texto |

---

## 🚀 Instalação — Delphi

1. Abra o Delphi → **Component → Install Component**  
2. Clique em **Browse** → selecione `RoundedEdit.pas`  
3. Clique em **OK** → **Yes** para compilar  
4. O componente aparece na aba **AntiGravity**

Ou abra `RoundedEditPkg.dproj` → **Build** → **Install**.

## 🚀 Instalação — Lazarus

1. **Package → Open Package File (.lpk)**  
2. Selecione `LazarusVersion/RoundedEditPkgLaz.lpk`  
3. Clique em **Compile** → **Use → Install**  
4. O IDE reinicia com o componente na aba **AntiGravity**

---

## 📄 Licença

MIT — livre para uso pessoal e comercial.
