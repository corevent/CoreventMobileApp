// All additional views are native layers, using the same local design system.
// Sample data only: no API requests, checkout links or usable ticket payloads.
async function renderAdditionalScreens(ctx) {
  const {
    options,
    model,
    nodes,
    library,
    stage,
    paint,
    fill,
    border,
    radius,
    al,
    comp,
    append,
    text,
    pad,
    prop,
    bindComponentProperties,
    base64Bytes,
    icon,
    setText,
    gap,
    divider,
    avatar,
    phone,
    viewport,
    footer,
    section,
    card,
    startGroup,
    backgrounds,
  } = ctx;
  const event = MOCKUP_DATA.events[0];
  const email = "lucas@exemplo.com";
  const logoHash = figma.createImage(base64Bytes(MOCKUP_ASSETS.logo)).hash;
  const inventory = [];
  function screen(label, source, route = "") {
    inventory.push({
      label,
      source: "lib/features/" + source + ".dart",
      route,
    });
    return phone(-1, label, "lib/features/" + source + ".dart", route);
  }
  function label(
    parent,
    value,
    size = 14,
    weight = "Regular",
    color = "textPrimary",
    center = false,
  ) {
    const n = append(
      parent,
      text(
        value,
        size,
        weight,
        color,
        parent.width - parent.paddingLeft - parent.paddingRight,
      ),
      true,
    );
    if (center) n.textAlignHorizontal = "CENTER";
    return n;
  }
  function fixed(n, w, h) {
    n.resize(w, h);
    n.primaryAxisSizingMode = "FIXED";
    n.counterAxisSizingMode = "FIXED";
    return n;
  }
  function systemFooter(s) {
    const row = fixed(al("Navegação Android", "HORIZONTAL", 390), 390, 24);
    row.primaryAxisAlignItems = row.counterAxisAlignItems = "CENTER";
    const line = fixed(al("Indicador de gesto", "VERTICAL", 104), 104, 4);
    fill(line, "textPrimary");
    line.cornerRadius = 2;
    append(row, line);
    append(s, row);
  }
  function logo(parent, width = 170) {
    const n = stage(figma.createRectangle());
    n.name = "Corevent · Logo original";
    n.resize(width, width / MOCKUP_ASSETS.logoRatio);
    n.fills = [{ type: "IMAGE", imageHash: logoHash, scaleMode: "FIT" }];
    append(parent, n);
    return n;
  }
  function iconRow(parent, glyph, value, color = "textSecondary", size = 14) {
    const row = al(
      value,
      "HORIZONTAL",
      parent.width - parent.paddingLeft - parent.paddingRight,
      12,
    );
    row.counterAxisAlignItems = "CENTER";
    append(row, icon(glyph, 20, "primaryDark"));
    append(row, text(value, size, "Medium", color, row.width - 32), true);
    append(parent, row, true);
    return row;
  }
  function panel(parent, name, padding = 16) {
    const n = al(
      name,
      "VERTICAL",
      parent.width - parent.paddingLeft - parent.paddingRight,
      0,
    );
    pad(n, padding);
    fill(n);
    border(n);
    radius(n, "card");
    append(parent, n, true);
    return n;
  }
  function variants(name, items, x, y) {
    const set = stage(figma.combineAsVariants(items, library));
    set.name = name;
    set.layoutMode = "VERTICAL";
    set.primaryAxisSizingMode = set.counterAxisSizingMode = "AUTO";
    set.itemSpacing = 16;
    pad(set, 16);
    set.x = x;
    set.y = y;
    return set;
  }
  function props(instance, values) {
    const output = {};
    for (const [key, value] of Object.entries(values)) {
      const actual = Object.keys(instance.componentProperties).find(
        (k) => k.split("#")[0] === key,
      );
      if (!actual) throw new Error("Propriedade ausente: " + key);
      output[actual] = value;
    }
    instance.setProperties(output);
  }
  const buttons = {};
  for (const state of ["Default", "Disabled", "Loading"]) {
    const c = fixed(comp("State=" + state, "HORIZONTAL", 342, 8), 342, 56);
    radius(c, "button");
    fill(c, state === "Default" ? "primary" : "backgroundSecondary");
    c.primaryAxisAlignItems = c.counterAxisAlignItems = "CENTER";
    if (state === "Loading") {
      const spinner = stage(figma.createEllipse());
      spinner.name = "Envio em andamento";
      spinner.resize(22, 22);
      spinner.arcData = {
        startingAngle: 0,
        endingAngle: Math.PI * 1.6,
        innerRadius: 0.8,
      };
      fill(spinner);
      append(c, spinner);
    }
    const t = append(
      c,
      text(
        state === "Loading" ? "Enviando…" : "Continuar",
        15,
        "ExtraBold",
        state === "Default" ? "surface" : "textSecondary",
      ),
    );
    prop(c, t, "Label");
    t.visible = state !== "Loading";
    buttons[state] = c;
  }
  variants("CoreventButton", Object.values(buttons), 100, 1200);
  const fields = {};
  for (const state of ["Default", "Focused", "Error", "Disabled"]) {
    const c = comp("State=" + state, "VERTICAL", 342, 8);
    const t = append(c, text("E-mail", 14, "Bold"));
    prop(c, t, "Label");
    const box = fixed(al("Input", "HORIZONTAL", 342, 8), 342, 56);
    pad(box, 14, 16);
    box.counterAxisAlignItems = "CENTER";
    fill(box, state === "Disabled" ? "background" : "surface");
    radius(box, "field");
    box.strokes = [
      paint(
        state === "Error"
          ? "error"
          : state === "Focused"
            ? "primary"
            : "backgroundSecondary",
      ),
    ];
    box.strokeWeight = state === "Focused" ? 1.5 : 1;
    // Figma only accepts references on layers already inside the component.
    append(c, box, true);
    const value = append(
      box,
      text("seu@email.com", 16, "Regular", "textSecondary", 270),
      true,
    );
    prop(c, value, "Value");
    const eye = append(box, icon("eye-off-line", 24));
    const password = c.addComponentProperty("Password", "BOOLEAN", false);
    bindComponentProperties(c, eye, { visible: password });
    eye.visible = false;
    if (state === "Error") {
      const e = append(
        c,
        text("Informe um e-mail válido.", 12, "Regular", "error", 342),
        true,
      );
      prop(c, e, "Error");
    }
    fields[state] = c;
  }
  variants("CoreventField", Object.values(fields), 500, 1200);
  const selections = {};
  for (const selected of [false, true]) {
    const c = comp("Selected=" + selected, "HORIZONTAL", 342, 16);
    pad(c, 16);
    fill(c, selected ? "orangeSoft" : "surface");
    radius(c, "card");
    c.strokes = [paint(selected ? "primary" : "backgroundSecondary")];
    c.counterAxisAlignItems = "CENTER";
    append(c, icon("user-line", 24, selected ? "primary" : "textSecondary"));
    const copy = al("Descrição", "VERTICAL", 270, 4);
    append(c, copy, true);
    prop(c, append(copy, text("Pessoa Física", 14, "ExtraBold")), "Title");
    prop(
      c,
      append(copy, text("Usar CPF", 14, "Regular", "textSecondary")),
      "Subtitle",
    );
    selections[String(selected)] = c;
  }
  variants("CoreventSelectionCard", Object.values(selections), 900, 1200);
  const badgeComponent = comp("StatusBadge", "HORIZONTAL", 100);
  badgeComponent.primaryAxisSizingMode = badgeComponent.counterAxisSizingMode =
    "AUTO";
  pad(badgeComponent, 7, 10);
  fill(badgeComponent, "orangeSoft");
  badgeComponent.cornerRadius = 8;
  prop(
    badgeComponent,
    append(badgeComponent, text("Válido", 12, "ExtraBold", "primaryDark")),
    "Label",
  );
  library.appendChild(badgeComponent);
  badgeComponent.x = 1400;
  badgeComponent.y = 1220;
  function button(parent, value, state = "Default") {
    const n = stage(buttons[state].createInstance());
    props(n, { Label: value });
    append(parent, n, true);
    return n;
  }
  function action(parent, value, color = "primary", align = "CENTER") {
    const n = fixed(
      al(
        value,
        "HORIZONTAL",
        parent.width - parent.paddingLeft - parent.paddingRight,
      ),
      parent.width - parent.paddingLeft - parent.paddingRight,
      48,
    );
    n.primaryAxisAlignItems =
      align === "CENTER" ? "CENTER" : align === "MAX" ? "MAX" : "MIN";
    n.counterAxisAlignItems = "CENTER";
    append(n, text(value, 14, "Bold", color));
    append(parent, n, true);
    return n;
  }
  function field(
    parent,
    name,
    value,
    password = false,
    state = "Default",
    error = "Informe um e-mail válido.",
  ) {
    const n = stage(fields[state].createInstance());
    const values = { Label: name, Value: value, Password: password };
    if (state === "Error") values["Error"] = error;
    props(n, values);
    append(parent, n, true);
    gap(parent, 16);
    return n;
  }
  function badge(
    parent,
    value,
    color = "primaryDark",
    background = "orangeSoft",
  ) {
    const n = stage(badgeComponent.createInstance());
    props(n, { Label: value });
    fill(n, background);
    n.findAllWithCriteria({ types: ["TEXT"] }).forEach(
      (t) => (t.fills = [paint(color)]),
    );
    append(parent, n);
    return n;
  }
  function heading(parent, title, description = "", size = 30) {
    label(parent, title, size, "ExtraBold");
    if (description) {
      gap(parent, 8);
      label(parent, description, 16, "Regular", "textSecondary");
    }
    gap(parent, 32);
  }
  function topLogo(parent) {
    const row = fixed(al("Voltar e logo", "HORIZONTAL", 342), 342, 48);
    row.counterAxisAlignItems = "CENTER";
    const back = fixed(al("Voltar", "HORIZONTAL", 48), 48, 48);
    back.primaryAxisAlignItems = back.counterAxisAlignItems = "CENTER";
    append(back, icon("arrow-left-line", 24, "textPrimary"));
    append(row, back);
    const center = al("Marca", "HORIZONTAL", 246);
    center.primaryAxisAlignItems = "CENTER";
    center.counterAxisAlignItems = "CENTER";
    append(row, center, true);
    logo(center, 28 * MOCKUP_ASSETS.logoRatio);
    append(row, fixed(al("Equilíbrio", "HORIZONTAL", 48), 48, 48));
    append(parent, row, true);
  }
  function appBar(parent, title) {
    const row = fixed(
      al(title + " · Barra superior", "HORIZONTAL", 390, 8),
      390,
      56,
    );
    pad(row, 4, 12);
    row.counterAxisAlignItems = "CENTER";
    append(row, icon("arrow-left-line", 24, "textPrimary"));
    append(row, text(title, 20, "Bold", "textPrimary", 322), true);
    row.strokes = [paint("backgroundSecondary")];
    row.strokeBottomWeight = 1;
    row.strokeTopWeight = row.strokeLeftWeight = row.strokeRightWeight = 0;
    append(parent, row);
    return row;
  }
  function auth(labelText, source, route, title, description) {
    const s = screen(labelText, "auth/presentation/" + source, route);
    fill(s, "background");
    const c = viewport(s);
    pad(c, 24);
    topLogo(c);
    gap(c, 48);
    heading(c, title, description);
    systemFooter(s);
    return { s, c };
  }
  function requirements(parent) {
    const labels = [
      "8 caracteres ou mais",
      "Uma letra maiúscula",
      "Uma letra minúscula",
      "Um número",
      "Um símbolo",
    ];
    for (const group of [
      labels.slice(0, 1),
      labels.slice(1, 3),
      labels.slice(3),
    ]) {
      const row = al("Requisitos de senha", "HORIZONTAL", 342, 8);
      for (const value of group) {
        const n = al(value, "HORIZONTAL", 160, 5);
        n.primaryAxisSizingMode = n.counterAxisSizingMode = "AUTO";
        pad(n, 7, 10);
        n.cornerRadius = 999;
        fill(n, "backgroundSecondary");
        append(n, icon("checkbox-blank-circle-line", 14));
        append(n, text(value, 12, "SemiBold", "textSecondary"));
        append(row, n);
      }
      append(parent, row, true);
      gap(parent, 8);
    }
    gap(parent, 16);
  }
  function dob(parent) {
    label(parent, "Data de nascimento", 14, "Bold");
    gap(parent, 8);
    const row = al("Dia, mês e ano", "HORIZONTAL", 342, 8);
    for (const [name, value, width] of [
      ["Dia", "DD", 81.5],
      ["Mês", "MM", 81.5],
      ["Ano", "AAAA", 163],
    ]) {
      const n = al(name, "VERTICAL", width, 2);
      pad(n, 8, 12);
      fill(n);
      border(n);
      radius(n, "field");
      label(n, name, 11, "Regular", "textSecondary", true);
      label(n, value, 16, "Regular", "textSecondary", true);
      append(row, n);
    }
    append(parent, row, true);
  }
  function stickyButton(s, value, secondary = "") {
    const f = al("Ações fixas", "VERTICAL", 390);
    pad(f, 16, 24);
    fill(f, "background");
    f.strokes = [paint("backgroundSecondary")];
    f.strokeTopWeight = 1;
    f.strokeBottomWeight = f.strokeLeftWeight = f.strokeRightWeight = 0;
    button(f, value);
    if (secondary) action(f, secondary);
    append(s, f);
    systemFooter(s);
  }
  function progress(parent, step) {
    label(parent, "Etapa " + step + " de 4", 13, "Bold", "textSecondary");
    gap(parent, 8);
    const row = al("Progresso", "HORIZONTAL", 342, 6);
    for (let i = 0; i < 4; i++) {
      const bar = fixed(al("Etapa " + (i + 1), "VERTICAL", 81), 81, 5);
      fill(bar, i < step ? "primary" : "backgroundSecondary");
      bar.cornerRadius = 5;
      append(row, bar);
    }
    append(parent, row, true);
  }
  function illustration(parent) {
    const art = fixed(
      al("Ilustração de ingresso · editável", "VERTICAL", 250),
      250,
      250,
    );
    const circle = stage(figma.createEllipse());
    circle.resize(205, 205);
    fill(circle, "pinkSoft");
    append(art, circle);
    circle.layoutPositioning = "ABSOLUTE";
    circle.x = circle.y = 22.5;
    const ticket = fixed(
      al("Ingresso ilustrado", "VERTICAL", 155, 0),
      155,
      165,
    );
    pad(ticket, 22);
    fill(ticket);
    border(ticket);
    ticket.cornerRadius = 24;
    const glyph = al("Banner do ingresso", "HORIZONTAL", 111);
    fill(glyph, "orangeSoft");
    glyph.cornerRadius = 16;
    glyph.primaryAxisAlignItems = glyph.counterAxisAlignItems = "CENTER";
    append(ticket, glyph, true);
    glyph.layoutSizingVertical = "FILL";
    append(glyph, icon("ticket-fill", 60, "primary"));
    gap(ticket, 16);
    for (const [w, h, color] of [
      [90, 12, "textPrimary"],
      [60, 8, "backgroundSecondary"],
    ]) {
      const bar = fixed(al("Linha decorativa", "VERTICAL", w), w, h);
      fill(bar, color);
      bar.cornerRadius = Number(h) / 2;
      append(ticket, bar);
      if (h === 12) gap(ticket, 9);
    }
    append(art, ticket);
    ticket.layoutPositioning = "ABSOLUTE";
    ticket.x = 48;
    ticket.y = 44;
    ticket.rotation = 6.9;
    for (const [x, y, glyphName] of [
      [194, 50, "heart-fill"],
      [1, 148, "ticket-fill"],
    ]) {
      const b = fixed(al("Badge de ilustração", "HORIZONTAL", 52), 52, 52);
      fill(b);
      border(b);
      b.cornerRadius = 26;
      b.primaryAxisAlignItems = b.counterAxisAlignItems = "CENTER";
      append(b, icon(glyphName, 24, "pink"));
      append(art, b);
      b.layoutPositioning = "ABSOLUTE";
      b.x = x;
      b.y = y;
    }
    const wrap = al(
      "Ilustração central",
      "HORIZONTAL",
      parent.width - parent.paddingLeft - parent.paddingRight,
    );
    wrap.primaryAxisAlignItems = "CENTER";
    append(wrap, art);
    append(parent, wrap, true);
  }

  startGroup(
    "02 · Entrada e autenticação",
    "Splash, Welcome, login, cadastro em quatro etapas e recuperação · Campos e ações editáveis",
  );
  const splash = screen(
    "Splash",
    "auth/presentation/authenticated_page",
    "/loading",
  );
  fill(splash, "background");
  const splashCenter = al("Somente a logo", "HORIZONTAL", 390);
  splashCenter.primaryAxisAlignItems = splashCenter.counterAxisAlignItems =
    "CENTER";
  append(splash, splashCenter, true);
  splashCenter.layoutSizingVertical = "FILL";
  logo(splashCenter, 220);
  systemFooter(splash);
  const welcome = screen("Welcome", "welcome/presentation/welcome_page", "/");
  fill(welcome, "background");
  const wc = viewport(welcome);
  pad(wc, 28, 24);
  logo(wc, 180);
  gap(wc, 54);
  illustration(wc);
  gap(wc, 46);
  const welcomeTitle = label(
    wc,
    "Descubra eventos incríveis perto de você.",
    30,
    "ExtraBold",
    "textPrimary",
    true,
  );
  welcomeTitle.setRangeFills(9, 25, [paint("primary")]);
  gap(wc, 18);
  label(
    wc,
    "Encontre experiências para viver e garanta seu ingresso de forma rápida e segura.",
    16,
    "Regular",
    "textSecondary",
    true,
  );
  gap(wc, 46);
  button(wc, "Criar conta");
  gap(wc, 12);
  action(wc, "Já tenho uma conta");
  systemFooter(welcome);
  function login(error = false, busy = false, notice = false) {
    const view = auth(
      error
        ? "Login · erro"
        : busy
          ? "Login · enviando"
          : notice
            ? "Login · senha redefinida"
            : "Login",
      "login_page",
      "/login",
      "Bem-vindo de volta!",
      "Sentimos sua falta. Entre para continuar explorando.",
    );
    if (notice) {
      const n = panel(view.c, "Senha redefinida", 12);
      label(
        n,
        "Senha redefinida. Entre com sua nova senha.",
        14,
        "Regular",
        "success",
      );
      gap(view.c, 16);
    }
    field(
      view.c,
      "E-mail",
      busy || error ? email : "seu@email.com",
      false,
      busy ? "Disabled" : "Default",
    );
    field(
      view.c,
      "Senha",
      busy || error ? "••••••••" : "Sua senha",
      true,
      busy ? "Disabled" : "Default",
    );
    action(view.c, "Esqueceu a senha?", "primary", "MAX");
    gap(view.c, 20);
    if (error) {
      label(view.c, "E-mail ou senha incorretos.", 14, "Regular", "error");
      gap(view.c, 16);
    }
    button(view.c, busy ? "Entrando…" : "Entrar", busy ? "Loading" : "Default");
    gap(view.c, 16);
    action(view.c, "Não possui conta? Cadastre-se");
    return view.s;
  }
  const loginBase = login();
  login(true);
  login(false, true);
  const titles = [
    "Conte-nos sobre você",
    "Pessoa ou empresa?",
    "Seu documento",
    "Credenciais de acesso",
  ];
  const descriptions = [
    "Vamos começar com o básico para criar seu perfil.",
    "Selecione o tipo da sua conta.",
    "Informe o documento da sua conta.",
    "Informe seu e-mail e crie uma senha para entrar no app.",
  ];
  function register(step, company = false) {
    const s = screen(
      "Cadastro · " +
        step +
        "/4" +
        (step === 2 || step === 3 ? (company ? " · PJ" : " · PF") : ""),
      "auth/presentation/register_page",
      "/register",
    );
    fill(s, "background");
    const top = al("Topo fixo · cadastro", "VERTICAL", 390);
    pad(top, 24);
    top.paddingBottom = 16;
    topLogo(top);
    gap(top, 24);
    progress(top, step);
    append(s, top);
    const c = viewport(s);
    pad(c, 24);
    heading(c, titles[step - 1], descriptions[step - 1]);
    if (step === 1) {
      field(c, "Nome completo", "Seu nome completo");
      dob(c);
    }
    if (step === 2) {
      for (const [isCompany, title, sub, glyph] of [
        [false, "Pessoa Física", "Usar CPF", "user-line"],
        [true, "Pessoa Jurídica", "Usar CNPJ", "building-2-line"],
      ]) {
        const n = stage(
          selections[String(isCompany === company)].createInstance(),
        );
        props(n, { Title: title, Subtitle: sub });
        const ico = n.findAllWithCriteria({ types: ["INSTANCE"] })[0];
        ico.swapComponent(nodes[model.components.icons[String(glyph)]]);
        ico
          .findAllWithCriteria({ types: ["VECTOR"] })
          .forEach(
            (v) =>
              (v.fills = [
                paint(isCompany === company ? "primary" : "textSecondary"),
              ]),
          );
        append(c, n, true);
        gap(c, 12);
      }
    }
    if (step === 3)
      field(
        c,
        company ? "CNPJ" : "CPF",
        company ? "00.000.000/0001-00" : "000.000.000-00",
      );
    if (step === 4) {
      field(c, "E-mail", "seu@email.com");
      field(c, "Senha", "Mínimo 8 caracteres", true);
      requirements(c);
      field(c, "Confirmar senha", "Repita a senha", true);
    }
    stickyButton(s, step === 4 ? "Finalizar" : "Próximo");
    return s;
  }
  register(1);
  register(2);
  register(2, true);
  register(3);
  register(3, true);
  register(4);
  function verification(reset = false, error = false) {
    const { s, c } = auth(
      "Verificação · " +
        (reset ? "recuperação" : "cadastro") +
        (error ? " · código inválido" : ""),
      "verification_page",
      reset ? "/verify/reset" : "/verify/register",
      "Verifique seu e-mail",
      "Enviamos um código de 6 dígitos para " + email + ".",
    );
    label(c, "Código de verificação", 14, "Bold");
    gap(c, 8);
    const row = al("Código de seis dígitos", "HORIZONTAL", 342, 6);
    for (let i = 0; i < 6; i++) {
      const n = fixed(al("Dígito " + (i + 1), "HORIZONTAL", 52), 52, 64);
      fill(n);
      radius(n, "field");
      n.strokes = [
        paint(error ? "error" : i === 0 ? "primary" : "backgroundSecondary"),
      ];
      n.primaryAxisAlignItems = n.counterAxisAlignItems = "CENTER";
      append(n, text(error ? String(i + 1) : "", 22, "ExtraBold"));
      append(row, n);
    }
    append(c, row, true);
    gap(c, 24);
    if (error) {
      label(
        c,
        "Código inválido. Verifique e tente novamente.",
        14,
        "Regular",
        "error",
      );
      gap(c, 16);
    }
    button(c, "Verificar");
    gap(c, 16);
    action(c, "Reenviar código (30s)", "textSecondary");
    action(c, "Alterar e-mail");
    return s;
  }
  verification();
  verification(false, true);
  const forgot = auth(
    "Recuperar senha",
    "forgot_password_page",
    "/forgot-password",
    "Recuperar senha",
    "Informe seu e-mail para receber o código de verificação.",
  );
  field(forgot.c, "E-mail", "seu@email.com");
  button(forgot.c, "Enviar código");
  verification(true);
  const reset = auth(
    "Redefinir senha",
    "reset_password_page",
    "/reset-password",
    "Redefinir senha",
    "Escolha uma nova senha para sua conta.",
  );
  field(reset.c, "Nova senha", "Mínimo 8 caracteres", true);
  requirements(reset.c);
  field(reset.c, "Confirmar senha", "Repita a senha", true);
  button(reset.c, "Redefinir senha");
  login(false, false, true);
  const recovery = screen(
    "Sessão · falha de rede",
    "auth/presentation/authenticated_page",
    "/loading",
  );
  fill(recovery, "background");
  const rc = viewport(recovery);
  rc.primaryAxisAlignItems = "CENTER";
  rc.counterAxisAlignItems = "CENTER";
  logo(rc, 200);
  gap(rc, 40);
  label(
    rc,
    "Não foi possível restaurar sua sessão.",
    16,
    "Regular",
    "textPrimary",
    true,
  );
  gap(rc, 16);
  action(rc, "Tentar novamente");
  systemFooter(recovery);

  function backdrop(s, base) {
    const clone = stage(base.clone());
    clone.name = "Contexto · " + base.name;
    append(s, clone);
    clone.layoutPositioning = "ABSOLUTE";
    clone.x = clone.y = 0;
    const scrim = stage(figma.createRectangle());
    scrim.resize(390, 844);
    scrim.name = "Fundo do modal";
    scrim.fills = [
      { type: "SOLID", color: { r: 0, g: 0, b: 0 }, opacity: 0.32 },
    ];
    append(s, scrim);
    scrim.layoutPositioning = "ABSOLUTE";
    scrim.x = scrim.y = 0;
  }
  function sheet(name, source, base, title, height = 650, drag = true) {
    const s = screen(name, source);
    backdrop(s, base);
    const p = fixed(al(title + " · Painel", "VERTICAL", 390), 390, height);
    fill(p);
    p.topLeftRadius = p.topRightRadius = 24;
    p.bottomLeftRadius = p.bottomRightRadius = 0;
    p.clipsContent = true;
    append(s, p);
    p.layoutPositioning = "ABSOLUTE";
    p.x = 0;
    p.y = 844 - height;
    if (drag) {
      const handle = fixed(
        al("Arraste para expandir", "HORIZONTAL", 390),
        390,
        26,
      );
      handle.primaryAxisAlignItems = handle.counterAxisAlignItems = "CENTER";
      const line = fixed(al("Indicador", "VERTICAL", 36), 36, 4);
      fill(line, "backgroundSecondary");
      line.cornerRadius = 2;
      append(handle, line);
      append(p, handle);
    }
    const header = al("Título do painel", "HORIZONTAL", 390, 12);
    pad(header, 12, 20);
    header.counterAxisAlignItems = "CENTER";
    append(header, text(title, 17, "ExtraBold", "textPrimary", 314), true);
    append(header, icon("close-line", 24, "textPrimary"));
    append(p, header);
    const c = viewport(p);
    pad(c, 20);
    return { s, c, p };
  }
  function picture(parent, height = 200, index = 0) {
    const n = fixed(
      al(
        "Banner ilustrativo",
        "VERTICAL",
        parent.width - parent.paddingLeft - parent.paddingRight,
      ),
      parent.width - parent.paddingLeft - parent.paddingRight,
      height,
    );
    n.fills = [
      { type: "IMAGE", imageHash: model.images[index], scaleMode: "FILL" },
    ];
    n.cornerRadius = 16;
    append(parent, n, true);
    return n;
  }
  function preview(error = false) {
    const view = sheet(
      error ? "Prévia · detalhes indisponíveis" : "Prévia do evento",
      "events/presentation/event_preview_sheet",
      backgrounds.explore,
      "Prévia do evento",
      690,
    );
    picture(view.c);
    gap(view.c, 20);
    const tags = al("Categoria e formato", "HORIZONTAL", 350, 8);
    badge(tags, "Música");
    badge(tags, "Presencial", "textPrimary", "backgroundSecondary");
    append(view.c, tags, true);
    gap(view.c, 12);
    label(view.c, event.Title, 24, "ExtraBold");
    gap(view.c, 16);
    iconRow(view.c, "heart-line", "Favoritar", "primary");
    gap(view.c, 16);
    for (const [glyph, value] of [
      ["calendar-event-line", event.Date],
      ["map-pin-line", event.Location],
      ["user-line", "Horizonte Produções"],
    ]) {
      iconRow(view.c, glyph, value, "textPrimary");
      gap(view.c, 12);
    }
    gap(view.c, 12);
    if (error) {
      label(
        view.c,
        "Não foi possível carregar a descrição deste evento.",
        14,
        "Regular",
        "error",
      );
      action(view.c, "Tentar novamente");
    } else {
      label(view.c, "Sobre o evento", 17, "ExtraBold");
      gap(view.c, 8);
      label(
        view.c,
        "Uma noite de encontros e música ao vivo, com artistas convidados e experiências para aproveitar com seus amigos.",
        14,
        "Regular",
        "textSecondary",
      );
    }
    gap(view.c, 28);
    label(view.c, "Avaliações", 17, "ExtraBold");
    gap(view.c, 8);
    iconRow(view.c, "star-fill", event.Rating);
    action(view.c, "Avaliar evento", "primary", "MIN");
    gap(view.c, 28);
    button(view.c, "Escolher ingressos");
    return view.s;
  }
  startGroup(
    "03 · Descoberta e prévia",
    "Busca e filtros permanecem em Explorar · Prévia com resumo imediato, detalhes e avaliações",
  );
  const eventPreview = preview();
  preview(true);
  function searchHeader(s, value = "Busque eventos, shows e experiências") {
    const outer = al("Busca sticky", "VERTICAL", 390);
    pad(outer, 13, 20);
    const row = fixed(al("Busca", "HORIZONTAL", 350, 10), 350, 54);
    pad(row, 12, 14);
    row.counterAxisAlignItems = "CENTER";
    fill(row, "background");
    border(row);
    radius(row, "field");
    append(row, icon("search-line", 22));
    append(row, text(value, 12, "Regular", "textSecondary", 284), true);
    append(outer, row, true);
    append(s, outer);
  }
  const results = screen(
    "Explorar · resultados",
    "explore/presentation/explore_page",
    "/explore",
  );
  searchHeader(results, "Festival");
  const resultsC = viewport(results);
  label(resultsC, "Resultados da busca", 18, "ExtraBold");
  action(resultsC, "Limpar filtros", "primary", "MIN");
  card(resultsC, "Standard", event);
  footer(results, 1);

  startGroup(
    "04 · Compra e ingressos",
    "Escolha, confirmação e acompanhamento do pedido · Detalhes e apresentação do QR Code",
  );
  const checkout = screen(
    "Escolher ingressos",
    "checkout/presentation/checkout_page",
    "/events/:id/checkout",
  );
  appBar(checkout, "Escolher ingressos");
  const cc = viewport(checkout);
  label(cc, event.Title, 24, "ExtraBold");
  gap(cc, 6);
  label(cc, event.Date, 14, "Regular", "textSecondary");
  gap(cc, 24);
  for (const [name, price, amount, qty] of [
    ["Entrada gratuita", "Gratuito", "50 disponíveis", "1"],
    ["Pista · Inteira", "R$ 80,00", "120 disponíveis", "0"],
    ["Camarote", "R$ 160,00", "Indisponível", "0"],
  ]) {
    const n = panel(cc, name);
    label(n, name, 16, "ExtraBold");
    gap(n, 4);
    label(n, price, 14, "Bold", "primaryDark");
    gap(n, 8);
    label(n, amount, 14, "Regular", "textSecondary");
    gap(n, 8);
    const row = al("Quantidade", "HORIZONTAL", 318, 12);
    row.primaryAxisAlignItems = "MAX";
    row.counterAxisAlignItems = "CENTER";
    append(row, icon("indeterminate-circle-line", 28));
    append(row, text(qty, 16, "ExtraBold"));
    append(
      row,
      icon(
        "add-circle-line",
        28,
        amount === "Indisponível" ? "textSecondary" : "primary",
      ),
    );
    append(n, row, true);
    gap(cc, 12);
  }
  const total = al("Resumo fixo", "VERTICAL", 390, 12);
  pad(total, 14, 20);
  fill(total);
  border(total);
  const totalRow = al("Total", "HORIZONTAL", 350, 12);
  append(
    totalRow,
    text("1 ingresso", 14, "Regular", "textSecondary", 235),
    true,
  );
  append(totalRow, text("R$ 0,00", 18, "ExtraBold"));
  append(total, totalRow, true);
  button(total, "Continuar");
  append(checkout, total);
  systemFooter(checkout);
  function orderStatus(status) {
    const title =
      status === "paid"
        ? "Pedido confirmado"
        : status === "pending"
          ? "Aguardando pagamento"
          : "Pedido cancelado";
    const s = screen(
      title,
      "checkout/presentation/order_status_page",
      "/orders/:id/status",
    );
    appBar(s, "Seu pedido");
    const c = viewport(s);
    pad(c, 24);
    const centered = al("Estado do pedido", "HORIZONTAL", 342);
    centered.primaryAxisAlignItems = "CENTER";
    append(
      centered,
      icon(
        status === "paid"
          ? "checkbox-circle-line"
          : status === "pending"
            ? "time-line"
            : "close-circle-line",
        48,
        status === "paid"
          ? "success"
          : status === "pending"
            ? "primary"
            : "error",
      ),
    );
    append(c, centered, true);
    gap(c, 16);
    label(c, title, 24, "ExtraBold");
    gap(c, 8);
    label(
      c,
      status === "paid"
        ? "Seus ingressos estão disponíveis na aba Ingressos."
        : status === "pending"
          ? "Se você já pagou, a confirmação pode levar alguns instantes. Atualize para consultar o status."
          : "Consulte seus pedidos para acompanhar esta compra.",
      14,
      "Regular",
      "textSecondary",
    );
    gap(c, 24);
    const summary = panel(c, "Resumo do pedido", 18);
    label(summary, event.Title, 17, "ExtraBold");
    gap(summary, 8);
    label(summary, "Pedido 0DA4C817", 14, "Regular", "textSecondary");
    gap(summary, 8);
    label(
      summary,
      "Total: " + (status === "paid" ? "R$ 0,00" : "R$ 80,00"),
      14,
      "Bold",
    );
    gap(c, 24);
    if (status !== "canceled")
      button(c, status === "paid" ? "Ver meus ingressos" : "Abrir pagamento");
    if (status === "pending") action(c, "Atualizar status");
    action(c, "Ver todos os pedidos");
    systemFooter(s);
    return s;
  }
  orderStatus("pending");
  orderStatus("paid");
  orderStatus("canceled");
  const td = sheet(
    "Detalhes do ingresso",
    "tickets/presentation/ticket_detail_sheet",
    backgrounds.tickets,
    event.Title,
    680,
  );
  badge(td.c, "Válido");
  gap(td.c, 24);
  const qrButton = stage(nodes[model.components.button].createInstance());
  props(qrButton, { Label: "Ver QR Code" });
  append(td.c, qrButton, true);
  gap(td.c, 24);
  for (const [glyph, name, value] of [
    ["ticket-line", "Tipo de ingresso", "Entrada gratuita"],
    ["calendar-event-line", "Data e horário", event.Date],
    ["map-pin-line", "Local", event.Location],
    ["price-tag-3-line", "Preço do tipo de ingresso", "R$ 0,00"],
    ["hashtag", "Identificador do ingresso", "0DA4C817-E35B-4B32"],
    ["receipt-line", "Identificador do pedido", "7136C092-6DB1-431C"],
  ]) {
    const row = al(name, "HORIZONTAL", 350, 12);
    append(row, icon(glyph, 20, "primaryDark"));
    const copy = al(name + " · Valor", "VERTICAL", 318, 3);
    label(copy, name, 12, "SemiBold", "textSecondary");
    label(copy, value, 14, "Bold");
    append(row, copy, true);
    append(td.c, row, true);
    gap(td.c, 16);
  }
  function qr(unavailable = false) {
    const s = screen(
      unavailable ? "QR Code · indisponível" : "QR Code do ingresso",
      "tickets/presentation/ticket_qr_page",
    );
    appBar(s, "Seu ingresso");
    const c = viewport(s);
    pad(c, 24);
    label(c, event.Title, 24, "ExtraBold", "textPrimary", true);
    gap(c, 6);
    label(c, "Entrada gratuita", 14, "SemiBold", "textSecondary", true);
    gap(c, 12);
    label(
      c,
      unavailable ? "Indisponível" : "Válido",
      14,
      "ExtraBold",
      unavailable ? "textSecondary" : "success",
      true,
    );
    gap(c, 24);
    const qrBox = panel(c, "QR Code", 16);
    qrBox.counterAxisAlignItems = "CENTER";
    if (unavailable) {
      append(qrBox, icon("qr-code-line", 48));
      gap(qrBox, 12);
      label(
        qrBox,
        "Este ingresso não pode ser apresentado na entrada.",
        14,
        "Regular",
        "textSecondary",
        true,
      );
    } else {
      const v = stage(figma.createNodeFromSvg(MOCKUP_ASSETS.qr));
      v.name = "QR ilustrativo · não é um ingresso válido";
      v.rescale(286 / v.width);
      append(qrBox, v);
    }
    gap(c, 20);
    if (!unavailable)
      label(
        c,
        "Apresente este código na entrada.",
        14,
        "Bold",
        "textPrimary",
        true,
      );
    action(c, "Atualizar status");
    systemFooter(s);
  }
  qr();
  qr(true);

  startGroup(
    "05 · Conta e atividade",
    "Pedidos, favoritos, avaliações, dados pessoais, edição de foto e segurança",
  );
  function subpage(name, source, route, title = name) {
    const s = screen(name, source, route);
    appBar(s, title);
    const c = viewport(s);
    systemFooter(s);
    return { s, c };
  }
  const orders = subpage(
    "Pedidos",
    "profile/presentation/activity_pages",
    "/profile/orders",
  );
  for (const [title, price, status] of [
    [event.Title, "R$ 0,00", "Pago"],
    [MOCKUP_DATA.events[1].Title, "R$ 80,00", "Aguardando pagamento"],
  ]) {
    const p = panel(orders.c, title);
    iconRow(p, "receipt-line", title, "textPrimary", 14);
    gap(p, 6);
    label(p, "08 out 2026 · " + price, 13, "Regular", "textSecondary");
    gap(p, 6);
    label(p, status, 14, "Bold", "primaryDark");
    gap(orders.c, 10);
  }
  const orderDetail = subpage(
    "Detalhes do pedido",
    "profile/presentation/activity_pages",
    "/profile/orders/:id",
  );
  label(orderDetail.c, event.Title, 24, "ExtraBold");
  gap(orderDetail.c, 18);
  for (const value of [
    "Status: Pago",
    "Pedido feito em 08 out 2026",
    "Total: R$ 0,00",
  ]) {
    label(orderDetail.c, value);
    gap(orderDetail.c, 6);
  }
  section(orderDetail.c, "Itens", 26);
  const item = panel(orderDetail.c, "Entrada gratuita");
  label(item, "Entrada gratuita", 16, "Bold");
  gap(item, 6);
  label(item, "Emitido · R$ 0,00", 14, "Regular", "textSecondary");
  function chips(parent) {
    const row = al("Estados dos favoritos", "HORIZONTAL", 350, 8);
    for (const [i, value] of [
      "Abertos",
      "Em andamento",
      "Encerrados",
    ].entries())
      badge(
        row,
        value,
        i === 0 ? "primaryDark" : "textSecondary",
        i === 0 ? "orangeSoft" : "surface",
      );
    append(parent, row, true);
    gap(parent, 16);
  }
  const fav = subpage(
    "Favoritos",
    "favorites/presentation/favorites_page",
    "/profile/favorites",
  );
  chips(fav.c);
  for (const [index, value] of MOCKUP_DATA.events.entries()) {
    const p = panel(fav.c, value.Title, 10);
    p.layoutMode = "HORIZONTAL";
    p.primaryAxisSizingMode = "FIXED";
    p.counterAxisSizingMode = "AUTO";
    p.itemSpacing = 14;
    const image = fixed(
      al("Imagem compacta quadrada", "VERTICAL", 102),
      102,
      102,
    );
    image.cornerRadius = 12;
    image.fills = [
      { type: "IMAGE", imageHash: model.images[index], scaleMode: "FILL" },
    ];
    append(p, image);
    const copy = al("Informações", "VERTICAL", 214, 6);
    append(p, copy, true);
    const head = al("Categoria e favorito", "HORIZONTAL", 214, 8);
    head.counterAxisAlignItems = "CENTER";
    append(
      head,
      text(value.Category, 11, "ExtraBold", "primaryDark", 140),
      true,
    );
    append(head, icon("heart-fill", 24, "pink"));
    append(copy, head, true);
    label(copy, value.Title, 14, "ExtraBold");
    iconRow(copy, "calendar-event-line", "17 out · 18:00", "textSecondary", 11);
    iconRow(copy, "star-fill", value.Rating, "textSecondary", 11);
    gap(fav.c, 16);
  }
  const ratings = subpage(
    "Avaliações",
    "ratings/presentation/ratings_page",
    "/profile/ratings",
  );
  const ratedCard = panel(ratings.c, "Avaliação do evento");
  const ratedRow = al("Resumo", "HORIZONTAL", 318, 12);
  const ratedImage = fixed(al("Banner", "VERTICAL", 64), 64, 64);
  ratedImage.cornerRadius = 10;
  ratedImage.fills = [
    { type: "IMAGE", imageHash: model.images[0], scaleMode: "FILL" },
  ];
  append(ratedRow, ratedImage);
  const ratedCopy = al("Sua avaliação", "VERTICAL", 242, 6);
  label(ratedCopy, event.Title, 14, "Bold");
  label(ratedCopy, "Sua nota: 4 de 5", 14, "Regular", "primaryDark");
  append(ratedRow, ratedCopy, true);
  append(ratedCard, ratedRow, true);
  action(ratedCard, "Editar avaliação", "primary", "MIN");
  function personal(editing = false) {
    const view = subpage(
      editing ? "Dados pessoais · edição" : "Dados pessoais",
      "profile/presentation/profile_details_page",
      "/profile/details",
      "Dados pessoais",
    );
    // Editing has a separate fixed footer, so it must precede the gesture bar.
    if (editing) view.s.children[view.s.children.length - 1].remove();
    const photo = panel(view.c, "Foto de perfil", 20);
    photo.layoutMode = "HORIZONTAL";
    photo.primaryAxisSizingMode = "FIXED";
    photo.counterAxisSizingMode = "AUTO";
    photo.itemSpacing = 18;
    photo.counterAxisAlignItems = "CENTER";
    append(photo, avatar(72));
    const photoCopy = al("Foto", "VERTICAL", 220);
    label(photoCopy, "Foto de perfil", 16, "ExtraBold");
    action(
      photoCopy,
      "Alterar foto",
      editing ? "textSecondary" : "primary",
      "MIN",
    );
    append(photo, photoCopy, true);
    section(view.c, "Contato", 28);
    if (!editing) action(view.c, "Editar", "primary", "MIN");
    const contact = panel(view.c, "Contato", 20);
    if (editing) {
      field(contact, "Nome completo", options.name);
      field(contact, "Telefone", "(11) 91234-5678");
      label(
        contact,
        "Telefone opcional · Brasil (+55)",
        12,
        "Regular",
        "textSecondary",
      );
    } else {
      detail(contact, "Nome completo", options.name);
      detail(contact, "Telefone", "(11) 91234-5678");
    }
    section(view.c, "Identificação", 28);
    label(
      view.c,
      "Dados de cadastro · somente leitura",
      12,
      "Regular",
      "textSecondary",
    );
    gap(view.c, 12);
    const identification = panel(view.c, "Identificação", 20);
    detail(identification, "E-mail", email);
    detail(identification, "CPF", "123.456.789-00");
    detail(identification, "Data de nascimento", "01/01/2000");
    if (editing) {
      stickyButton(view.s, "Salvar alterações", "Cancelar edição");
      fill(view.s.children[view.s.children.length - 2], "surface");
    }
    return view.s;
  }
  function detail(parent, name, value) {
    label(parent, name, 12, "SemiBold", "textSecondary");
    gap(parent, 6);
    label(parent, value, 16, "SemiBold");
    gap(parent, 16);
  }
  const personalBase = personal();
  const personalEdit = personal(true);
  function portrait(parent, size) {
    // Illustrative portrait, not a screenshot of the cropper or real account photo.
    const svg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="240" height="240" viewBox="0 0 240 240"><rect width="240" height="240" fill="#FFF0EB"/><path d="M24 240c0-62 43-90 96-90s96 28 96 90" fill="#FF5A36"/><ellipse cx="120" cy="104" rx="46" ry="55" fill="#D69B78"/><path d="M72 105V73c0-55 99-55 99 0v27l-18-39-39 17-32-3-10 30" fill="#18181A"/></svg>';
    const v = stage(figma.createNodeFromSvg(svg));
    v.name = "Foto ilustrativa · vetorial";
    v.rescale(size / v.width);
    append(parent, v);
    return v;
  }
  function avatarPage(crop = false, uploading = false) {
    const view = subpage(
      crop ? "Ajustar foto" : uploading ? "Foto · enviando" : "Prévia da foto",
      "profile/presentation/avatar_editor_page",
      "",
      crop ? "Ajustar foto" : "Prévia da foto",
    );
    view.s.children[view.s.children.length - 1].remove();
    if (crop) {
      label(
        view.c,
        "Arraste e use o zoom para enquadrar sua foto.",
        14,
        "Regular",
        "textSecondary",
      );
      gap(view.c, 32);
      const cropper = fixed(al("Área de recorte", "VERTICAL", 350), 350, 350);
      cropper.clipsContent = true;
      portrait(cropper, 350);
      const ring = stage(figma.createEllipse());
      ring.resize(300, 300);
      ring.fills = [];
      ring.strokes = [paint("surface")];
      ring.strokeWeight = 16;
      append(cropper, ring);
      ring.layoutPositioning = "ABSOLUTE";
      ring.x = ring.y = 25;
      append(view.c, cropper, true);
    } else {
      gap(view.c, 24);
      const centered = al("Prévia da nova foto", "HORIZONTAL", 350);
      centered.primaryAxisAlignItems = "CENTER";
      const image = fixed(al("Foto circular", "VERTICAL", 200), 200, 200);
      image.cornerRadius = 100;
      image.clipsContent = true;
      portrait(image, 200);
      append(centered, image);
      append(view.c, centered, true);
      gap(view.c, 24);
      label(
        view.c,
        "Esta será sua foto de perfil.",
        17,
        "Bold",
        "textPrimary",
        true,
      );
      gap(view.c, 8);
      label(
        view.c,
        "A foto atual será substituída após a confirmação.",
        14,
        "Regular",
        "textSecondary",
        true,
      );
      if (!uploading) action(view.c, "Ajustar recorte");
      if (uploading) {
        gap(view.c, 24);
        const track = fixed(
          al("Progresso do upload", "HORIZONTAL", 350),
          350,
          4,
        );
        fill(track, "backgroundSecondary");
        const current = fixed(al("65%", "VERTICAL", 228), 228, 4);
        fill(current, "primary");
        append(track, current);
        append(view.c, track, true);
        gap(view.c, 8);
        label(view.c, "Enviando foto… 65%", 14, "Regular", "textPrimary", true);
      }
    }
    const actions = al("Ação fixa", "VERTICAL", 390);
    pad(actions, 20);
    fill(actions);
    border(actions);
    button(
      actions,
      crop ? "Continuar" : uploading ? "Enviando…" : "Salvar foto",
      uploading ? "Loading" : "Default",
    );
    append(view.s, actions);
    systemFooter(view.s);
    return view.s;
  }
  avatarPage(true);
  avatarPage();
  avatarPage(false, true);
  const security = subpage(
    "Segurança",
    "profile/presentation/profile_form_pages",
    "/profile/security",
  );
  label(
    security.c,
    "Escolha uma senha forte que você não usa em outros serviços.",
    14,
    "Regular",
    "textSecondary",
  );
  gap(security.c, 24);
  field(security.c, "Senha atual", "••••••••", true);
  field(security.c, "Nova senha", "Sua nova senha", true);
  field(security.c, "Confirmar nova senha", "Repita a nova senha", true);
  button(security.c, "Alterar senha");

  startGroup(
    "06 · Avaliar e confirmar",
    "Painéis de avaliação e confirmações do app · Ações destrutivas em vermelho",
  );
  function ratingEditor(edit = false, readonly = false) {
    const view = sheet(
      readonly
        ? "Avaliação registrada · somente leitura"
        : edit
          ? "Editar avaliação"
          : "Avaliar evento",
      "ratings/presentation/rating_widgets",
      eventPreview,
      edit || readonly ? "Sua avaliação" : "Avaliar evento",
      edit ? 435 : 390,
      false,
    );
    label(view.c, event.Title, 14, "Bold");
    gap(view.c, 20);
    const stars = al("Nota de 1 a 5", "HORIZONTAL", 350, 4);
    for (let i = 1; i <= 5; i++) {
      const touch = fixed(al(i + " estrelas", "HORIZONTAL", 48), 48, 48);
      touch.primaryAxisAlignItems = touch.counterAxisAlignItems = "CENTER";
      append(
        touch,
        icon(
          i <= 4 && (edit || readonly) ? "star-fill" : "star-line",
          34,
          "primary",
        ),
      );
      append(stars, touch);
    }
    append(view.c, stars, true);
    gap(view.c, 12);
    label(
      view.c,
      edit || readonly ? "Sua nota: 4 de 5" : "Selecione uma nota de 1 a 5.",
      14,
      "Regular",
      "textSecondary",
    );
    gap(view.c, 24);
    if (readonly)
      label(
        view.c,
        "Sua avaliação foi registrada.",
        14,
        "Regular",
        "textSecondary",
      );
    else button(view.c, "Salvar avaliação", "Disabled");
    if (edit) action(view.c, "Remover avaliação", "error");
    action(view.c, "Cancelar");
    return view.s;
  }
  const ratingNew = ratingEditor();
  const ratingEdit = ratingEditor(true);
  ratingEditor(false, true);
  function dialog(
    name,
    source,
    base,
    title,
    body,
    cancel,
    confirm,
    destructive = true,
  ) {
    const s = screen(name, source);
    backdrop(s, base);
    const d = al(title + " · Diálogo", "VERTICAL", 342, 16);
    pad(d, 24);
    fill(d);
    d.cornerRadius = 28;
    label(d, title, 20, "Bold");
    label(d, body, 14, "Regular");
    const actions = al("Ações", "HORIZONTAL", 294, 16);
    actions.primaryAxisAlignItems = "MAX";
    if (cancel.length > 18) {
      actions.layoutMode = "VERTICAL";
      actions.primaryAxisSizingMode = "AUTO";
      actions.counterAxisSizingMode = "FIXED";
    }
    append(actions, text(cancel, 14, "Bold", "primary"));
    append(
      actions,
      text(confirm, 14, "Bold", destructive ? "error" : "primary"),
    );
    append(d, actions, true);
    append(s, d);
    d.layoutPositioning = "ABSOLUTE";
    d.x = 24;
    d.y = (844 - d.height) / 2;
    return s;
  }
  dialog(
    "Sair da conta · confirmação",
    "profile/presentation/profile_page",
    backgrounds.profile,
    "Sair da conta?",
    "Você precisará entrar novamente para acessar seus ingressos.",
    "Cancelar",
    "Sair",
  );
  dialog(
    "Remover favorito · confirmação",
    "favorites/presentation/favorites_page",
    fav.s,
    "Remover favorito?",
    "Remover “" + event.Title + "” dos seus favoritos?",
    "Cancelar",
    "Remover",
  );
  dialog(
    "Remover avaliação · confirmação",
    "ratings/presentation/rating_widgets",
    ratingEdit,
    "Remover avaliação?",
    "Sua nota será removida deste evento.",
    "Cancelar",
    "Remover",
  );
  dialog(
    "Descartar edição · confirmação",
    "profile/presentation/profile_details_page",
    personalEdit,
    "Descartar alterações?",
    "As mudanças que você fez ainda não foram salvas.",
    "Continuar editando",
    "Descartar",
  );
  dialog(
    "Confirmação de idade",
    "checkout/presentation/checkout_page",
    checkout,
    "Confirmação de idade",
    "Este evento possui restrição etária. Confirme que você atende à política de idade do organizador.",
    "Cancelar",
    "Li e aceito",
    false,
  );

  startGroup(
    "07 · Estados e feedback",
    "Vazios, falhas e validação · Atualização preserva os dados e usa toast, sem card adicional",
  );
  function feedState(name, kind, error = false) {
    const route =
      kind === "tickets"
        ? "/tickets"
        : kind === "explore"
          ? "/explore"
          : "/home";
    const s = screen(name, kind + "/presentation/" + kind + "_page", route);
    if (kind === "explore") searchHeader(s);
    if (kind === "home") {
      const header = al("Saudação sticky", "HORIZONTAL", 390, 14);
      pad(header, 13, 20);
      header.counterAxisAlignItems = "CENTER";
      const copy = al("Saudação", "VERTICAL", 296, 2);
      label(copy, options.greeting, 12, "SemiBold", "textSecondary");
      label(
        copy,
        "Olá, " + options.name.split(/\s+/)[0] + "!",
        18,
        "ExtraBold",
      );
      append(header, copy, true);
      append(header, avatar(40));
      append(s, header);
    }
    const c = viewport(s);
    gap(c, 40);
    const glyph = error
      ? "wifi-off-line"
      : kind === "tickets"
        ? "ticket-line"
        : "calendar-close-line";
    append(c, icon(glyph, 40, "primary"));
    gap(c, 16);
    label(
      c,
      error
        ? kind === "tickets"
          ? "Ingressos indisponíveis"
          : "Eventos indisponíveis"
        : kind === "tickets"
          ? "Nenhum ingresso ainda"
          : kind === "explore"
            ? "Nenhum evento encontrado"
            : "Ainda não há eventos",
      20,
      "ExtraBold",
    );
    gap(c, 8);
    label(
      c,
      error
        ? "Não foi possível carregar as informações. Confira sua conexão e tente novamente."
        : kind === "tickets"
          ? "Explore os eventos e encontre sua próxima experiência."
          : "Volte mais tarde ou procure outra experiência em Explorar.",
      14,
      "Regular",
      "textSecondary",
    );
    action(
      c,
      error
        ? "Tentar novamente"
        : kind === "explore"
          ? "Limpar filtros"
          : "Explorar eventos",
      "primary",
      "MIN",
    );
    footer(s, kind === "tickets" ? 2 : kind === "explore" ? 1 : 0);
    return s;
  }
  feedState("Início · vazio", "home");
  feedState("Início · falha inicial", "home", true);
  feedState("Explorar · sem resultados", "explore");
  feedState("Explorar · falha inicial", "explore", true);
  feedState("Ingressos · vazio", "tickets");
  feedState("Ingressos · falha inicial", "tickets", true);
  for (const [name, source, route, message] of [
    [
      "Pedidos · vazio",
      "profile/presentation/activity_pages",
      "/profile/orders",
      "Você ainda não fez pedidos.",
    ],
    [
      "Favoritos · vazio",
      "favorites/presentation/favorites_page",
      "/profile/favorites",
      "Nenhum evento aberto salvo",
    ],
    [
      "Avaliações · vazio",
      "ratings/presentation/ratings_page",
      "/profile/ratings",
      "Você ainda não avaliou eventos.",
    ],
  ]) {
    const view = subpage(name, source, route, name.split(" · ")[0]);
    if (route.includes("favorites")) chips(view.c);
    gap(view.c, 32);
    label(
      view.c,
      message,
      route.includes("favorites") ? 20 : 14,
      route.includes("favorites") ? "ExtraBold" : "Regular",
      "textSecondary",
    );
    if (route.includes("favorites")) {
      gap(view.c, 8);
      label(
        view.c,
        "Explore eventos e salve os que você quer acompanhar.",
        14,
        "Regular",
        "textSecondary",
      );
      action(view.c, "Explorar eventos");
    }
  }
  const validation = auth(
    "Login · validação do campo",
    "login_page",
    "/login",
    "Bem-vindo de volta!",
    "Sentimos sua falta. Entre para continuar explorando.",
  );
  field(validation.c, "E-mail", "lucas@", false, "Error");
  field(validation.c, "Senha", "Sua senha", true);
  button(validation.c, "Entrar");
  const refresh = screen(
    "Início · erro ao atualizar",
    "home/presentation/home_page",
    "/home",
  );
  const original = stage(backgrounds.home.clone());
  append(refresh, original);
  original.layoutPositioning = "ABSOLUTE";
  original.x = original.y = 0;
  const toast = al("Toast de erro", "VERTICAL", 350);
  pad(toast, 14, 16);
  fill(toast, "error");
  toast.cornerRadius = 12;
  label(
    toast,
    "Não foi possível atualizar os eventos. Tente novamente.",
    14,
    "Regular",
    "surface",
  );
  append(refresh, toast);
  toast.layoutPositioning = "ABSOLUTE";
  toast.x = 20;
  toast.y = 844 - 110 - toast.height;
  // The runtime checks route coverage separately from visual variants.
  return inventory;
}
