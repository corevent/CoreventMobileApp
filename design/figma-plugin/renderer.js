// Native editable Figma nodes; no screenshots of interfaces are imported.
// Main tabs plus all user-facing Flutter routes, panels and representative states.
async function renderMockups(options, fonts, position, registerRoot, buildId) {
  const vars = await ensureTokens();
  const hex = MOCKUP_DATA.colors;
  function stage(node) {
    node.setPluginData(BUILD_KEY, buildId);
    return node;
  }
  function paint(key) {
    const h = hex[key];
    /** @type {SolidPaint} */
    const p = {
      type: "SOLID",
      color: {
        r: parseInt(h.slice(0, 2), 16) / 255,
        g: parseInt(h.slice(2, 4), 16) / 255,
        b: parseInt(h.slice(4, 6), 16) / 255,
      },
    };
    return figma.variables.setBoundVariableForPaint(
      p,
      "color",
      vars["AppColors/" + key],
    );
  }
  function fill(n, key = "surface") {
    n.fills = [paint(key)];
  }
  function border(n) {
    n.strokes = [paint("backgroundSecondary")];
    n.strokeWeight = 1;
  }
  function radius(n, key) {
    n.cornerRadius = { field: 14, button: 18, card: 20 }[key];
    n.setBoundVariable("cornerRadius", vars["AppRadii/" + key]);
  }
  function al(name, dir = "VERTICAL", w = 350, gap = 0) {
    const n = stage(figma.createFrame());
    n.name = name;
    n.layoutMode = dir;
    n.resize(w, 1);
    n.primaryAxisSizingMode = dir === "VERTICAL" ? "AUTO" : "FIXED";
    n.counterAxisSizingMode = dir === "VERTICAL" ? "FIXED" : "AUTO";
    n.itemSpacing = gap;
    const spacing = Object.entries({
      xs: 4,
      sm: 8,
      md: 16,
      lg: 24,
      xl: 32,
      xxl: 48,
    }).find(([, value]) => value === gap);
    if (spacing)
      n.setBoundVariable("itemSpacing", vars["AppSpacing/" + spacing[0]]);
    n.fills = [];
    return n;
  }
  function append(p, n, grow = false) {
    p.appendChild(n);
    if (grow) n.layoutSizingHorizontal = "FILL";
    return n;
  }
  function text(
    value,
    size = 14,
    style = "Regular",
    color = "textPrimary",
    width,
  ) {
    const n = stage(figma.createText());
    n.name = value;
    n.fontName = fonts[style];
    n.fontSize = size;
    n.lineHeight = { unit: "PIXELS", value: Math.ceil(size * 1.4) };
    n.characters = value;
    n.fills = [paint(color)];
    if (width) {
      n.textAutoResize = "HEIGHT";
      n.resize(width, n.height);
    } else n.textAutoResize = "WIDTH_AND_HEIGHT";
    return n;
  }
  function comp(name, dir = "VERTICAL", w = 350, gap = 0) {
    const n = stage(figma.createComponent());
    n.name = name;
    n.layoutMode = dir;
    n.resize(w, 1);
    n.primaryAxisSizingMode = dir === "VERTICAL" ? "AUTO" : "FIXED";
    n.counterAxisSizingMode = dir === "VERTICAL" ? "FIXED" : "AUTO";
    n.itemSpacing = gap;
    n.fills = [];
    return n;
  }
  function pad(n, v, h = v) {
    n.paddingTop = v;
    n.paddingBottom = v;
    n.paddingLeft = h;
    n.paddingRight = h;
  }
  function bindComponentProperties(c, n, references) {
    let owner = n.parent;
    while (owner && owner.type !== "COMPONENT" && owner.type !== "INSTANCE") {
      owner = owner.parent;
    }
    if (owner !== c) {
      throw new Error(
        `Anexe a camada “${n.name}” ao componente “${c.name}” antes de vincular suas propriedades.`,
      );
    }
    n.componentPropertyReferences = {
      ...n.componentPropertyReferences,
      ...references,
    };
  }
  function prop(c, n, label) {
    const key = c.addComponentProperty(label, "TEXT", n.characters);
    bindComponentProperties(c, n, { characters: key });
    return key;
  }
  function base64Bytes(str) {
    const chars =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    const out = [];
    let buffer = 0,
      bits = 0;
    for (const ch of str) {
      if (ch === "=") break;
      const v = chars.indexOf(ch);
      if (v < 0) continue;
      buffer = (buffer << 6) | v;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        out.push((buffer >> bits) & 255);
      }
    }
    return new Uint8Array(out);
  }
  function flatIds(roots) {
    const ids = [];
    for (const n of roots) {
      ids.push(n.id);
      if ("findAll" in n) ids.push(...n.findAll(() => true).map((x) => x.id));
    }
    return [...new Set(ids)];
  }

  const library = stage(figma.createFrame());
  library.name = "Corevent · Componentes locais";
  library.resize(1800, 2850);
  library.clipsContent = false;
  fill(library);
  registerRoot(library);
  // Temporary placement, away from existing canvas content.
  library.x = position.x;
  library.y = position.y + 1300;

  function buildComponents() {
    const page = library;
    const svgs = MOCKUP_ASSETS.icons;
    const hashes = MOCKUP_ASSETS.photos.map(
      (data) => figma.createImage(base64Bytes(data)).hash,
    );
    const icons = {};
    let ix = 0;
    for (const [name, svg] of Object.entries(svgs)) {
      const c = comp("Remix/" + name, "VERTICAL", 24);
      c.resize(24, 24);
      c.primaryAxisSizingMode = "FIXED";
      c.counterAxisSizingMode = "FIXED";
      const v = figma.createNodeFromSvg(
        svg
          .replace("<svg ", '<svg width="24" height="24" ')
          .replace(/currentColor/g, "#6B6B70"),
      );
      stage(v);
      append(c, v);
      v.resize(24, 24);
      page.appendChild(c);
      c.x = 100 + (ix % 14) * 56;
      c.y = 1960 + Math.floor(ix / 14) * 64;
      icons[name] = c;
      ix++;
    }
    const scaledIcons = {};
    function sizedIcon(name, size) {
      const key = name + "/" + size;
      if (scaledIcons[key]) return scaledIcons[key];
      if (size === 24) return icons[name];
      const c = stage(icons[name].clone());
      c.name = "Remix/" + name + "/" + size;
      c.rescale(size / 24);
      page.appendChild(c);
      const position = Object.keys(scaledIcons).length;
      c.x = 100 + (position % 14) * 64;
      c.y = 2360 + Math.floor(position / 14) * 64;
      scaledIcons[key] = c;
      return c;
    }
    function icon(name, size = 24, color = "textSecondary") {
      const n = sizedIcon(name, size).createInstance();
      n.name = "Icon/" + name;
      for (const v of n.findAll((x) => x.type === "VECTOR"))
        if (v.fills.length) v.fills = [paint(color)];
      return n;
    }
    function iconBox(
      name,
      size = 46,
      color = "orangeSoft",
      glyph = "ticket-line",
    ) {
      const n = al(name, "HORIZONTAL", size);
      n.resize(size, size);
      n.primaryAxisSizingMode = "FIXED";
      n.counterAxisSizingMode = "FIXED";
      n.primaryAxisAlignItems = "CENTER";
      n.counterAxisAlignItems = "CENTER";
      fill(n, color);
      n.cornerRadius = 12;
      append(n, icon(glyph, 24, "primaryDark"));
      return n;
    }
    const navs = [];
    const labels = ["Início", "Explorar", "Ingressos", "Perfil"];
    const glyphs = ["home", "compass-3", "ticket", "user"];
    for (let active = 0; active < 4; active++) {
      const c = comp("Active=" + labels[active], "HORIZONTAL", 390);
      c.resize(390, 66);
      c.primaryAxisSizingMode = "FIXED";
      c.counterAxisSizingMode = "FIXED";
      fill(c);
      c.strokes = [paint("backgroundSecondary")];
      c.strokeTopWeight = 1;
      c.strokeLeftWeight = 0;
      c.strokeRightWeight = 0;
      c.strokeBottomWeight = 0;
      for (let i = 0; i < 4; i++) {
        const item = al(labels[i], "VERTICAL", 97.5, 4);
        item.resize(97.5, 66);
        item.primaryAxisSizingMode = "FIXED";
        item.primaryAxisAlignItems = "CENTER";
        item.counterAxisAlignItems = "CENTER";
        append(c, item);
        append(
          item,
          icon(
            glyphs[i] + (i === active ? "-fill" : "-line"),
            24,
            i === active ? "primary" : "textSecondary",
          ),
        );
        append(
          item,
          text(
            labels[i],
            11,
            "Bold",
            i === active ? "primary" : "textSecondary",
          ),
        );
      }
      navs.push(c);
    }
    const navSet = stage(figma.combineAsVariants(navs, page));
    navSet.name = "BottomNavigation";
    navSet.layoutMode = "VERTICAL";
    navSet.itemSpacing = 24;
    pad(navSet, 16);
    navSet.x = 100;
    navSet.y = 290;
    const cards = [],
      cardProps = {};
    for (let index = 0; index < 2; index++) {
      const featured = index === 0,
        c = comp(
          "Size=" + (featured ? "Featured" : "Standard"),
          "VERTICAL",
          350,
        );
      fill(c);
      border(c);
      radius(c, "card");
      c.clipsContent = true;
      const banner = al("Banner", "HORIZONTAL", 350);
      banner.resize(350, featured ? 197 : 175);
      banner.primaryAxisSizingMode = "FIXED";
      banner.counterAxisSizingMode = "FIXED";
      pad(banner, 8, 12);
      banner.counterAxisAlignItems = "MIN";
      banner.itemSpacing = 8;
      banner.fills = [
        { type: "IMAGE", imageHash: hashes[index], scaleMode: "FILL" },
      ];
      append(c, banner);
      const chip = al("Category", "HORIZONTAL", 80);
      chip.primaryAxisSizingMode = "AUTO";
      chip.counterAxisSizingMode = "AUTO";
      pad(chip, 5, 8);
      fill(chip);
      chip.cornerRadius = 8;
      const category = append(
        chip,
        text(
          featured ? "Música" : "Arte e cultura",
          11,
          "ExtraBold",
          "primaryDark",
        ),
      );
      append(banner, chip);
      const space = append(banner, al("Flexible space", "HORIZONTAL", 1), true);
      const favorite = al("Favorite", "HORIZONTAL", 48);
      favorite.resize(48, 48);
      favorite.primaryAxisSizingMode = "FIXED";
      favorite.counterAxisSizingMode = "FIXED";
      favorite.primaryAxisAlignItems = "CENTER";
      favorite.counterAxisAlignItems = "CENTER";
      favorite.cornerRadius = 24;
      fill(favorite);
      append(favorite, icon("heart-line", 24, "primaryDark"));
      append(banner, favorite);
      const body = al("Information", "VERTICAL", 350, 6);
      pad(body, 14);
      body.paddingTop = 12;
      append(c, body);
      const title = append(
        body,
        text(
          featured ? "Festival Horizonte" : "Noite de arte e música",
          featured ? 20 : 16,
          "ExtraBold",
          "textPrimary",
          322,
        ),
        true,
      );
      const fields = [
        [
          "calendar-event-line",
          featured ? "Sáb, 17 out · 18:00" : "Dom, 18 out · 16:00",
          "Date",
        ],
        [
          "map-pin-line",
          featured
            ? "Parque Ibirapuera · São Paulo, SP"
            : "Centro Cultural · São Paulo, SP",
          "Location",
        ],
      ];
      const props = {
        Title: prop(c, title, "Title"),
        Category: prop(c, category, "Category"),
      };
      for (const [ico, value, key] of fields) {
        const row = al(key, "HORIZONTAL", 322, 7);
        row.counterAxisAlignItems = "CENTER";
        append(body, row, true);
        append(row, icon(ico, 17));
        const t = append(
          row,
          text(value, 12, "Regular", "textSecondary", 298),
          true,
        );
        props[key] = prop(c, t, key);
      }
      const rating = al("Rating", "HORIZONTAL", 322, 6);
      rating.counterAxisAlignItems = "CENTER";
      rating.paddingTop = 4;
      append(body, rating, true);
      append(rating, icon("star-fill", 17, "primary"));
      const rt = append(
        rating,
        text(
          featured ? "4.8 (1234)" : "4.6 (82)",
          12,
          "Medium",
          "textSecondary",
        ),
      );
      props.Rating = prop(c, rt, "Rating");
      cards.push(c);
      cardProps[featured ? "Featured" : "Standard"] = props;
    }
    const cardSet = stage(figma.combineAsVariants(cards, page));
    cardSet.name = "EventSummaryCard";
    cardSet.layoutMode = "HORIZONTAL";
    cardSet.itemSpacing = 24;
    pad(cardSet, 16);
    cardSet.x = 600;
    cardSet.y = 290;
    const interest = comp("InterestTile", "HORIZONTAL", 170, 10);
    interest.resize(170, 64);
    interest.primaryAxisSizingMode = "FIXED";
    interest.counterAxisSizingMode = "FIXED";
    interest.counterAxisAlignItems = "CENTER";
    pad(interest, 12);
    fill(interest);
    border(interest);
    radius(interest, "card");
    append(interest, icon("music-2-line", 22, "primaryDark"));
    const interestLabel = append(
      interest,
      text("Música", 13, "Bold", "textPrimary", 112),
      true,
    );
    const interestProp = prop(interest, interestLabel, "Label");
    page.appendChild(interest);
    interest.x = 1400;
    interest.y = 310;
    const rowC = comp("ProfileRow", "HORIZONTAL", 350, 16);
    pad(rowC, 14, 16);
    rowC.counterAxisAlignItems = "CENTER";
    fill(rowC);
    append(rowC, icon("receipt-line", 24, "primary"));
    const textStack = al("Text", "VERTICAL", 246, 2);
    append(rowC, textStack, true);
    const rowTitle = append(
      textStack,
      text("Pedidos", 14, "Bold", "textPrimary", 230),
      true,
    );
    const rowDescription = append(
      textStack,
      text(
        "Acompanhe suas compras e pagamentos",
        12,
        "Regular",
        "textSecondary",
        230,
      ),
      true,
    );
    append(rowC, icon("arrow-right-s-line", 20));
    const rowProps = {
      Title: prop(rowC, rowTitle, "Title"),
      Description: prop(rowC, rowDescription, "Description"),
    };
    const hasDescription = rowC.addComponentProperty(
      "Has description",
      "BOOLEAN",
      true,
    );
    bindComponentProperties(rowC, rowDescription, { visible: hasDescription });
    page.appendChild(rowC);
    rowC.x = 1400;
    rowC.y = 420;
    const button = comp("OutlinedButton", "HORIZONTAL", 350, 8);
    button.resize(350, 48);
    button.primaryAxisSizingMode = "FIXED";
    button.counterAxisSizingMode = "FIXED";
    button.primaryAxisAlignItems = "CENTER";
    button.counterAxisAlignItems = "CENTER";
    fill(button);
    button.strokes = [paint("primary")];
    button.strokeWeight = 1;
    radius(button, "button");
    append(button, icon("qr-code-line", 22, "primaryDark"));
    const buttonText = append(
      button,
      text("Ver QR Code", 14, "ExtraBold", "primaryDark"),
    );
    const buttonProp = prop(button, buttonText, "Label");
    page.appendChild(button);
    button.x = 1400;
    button.y = 560;
    const ticket = comp("TicketCard", "VERTICAL", 350, 14);
    pad(ticket, 16);
    fill(ticket);
    border(ticket);
    radius(ticket, "card");
    const tHead = al("Ticket heading", "HORIZONTAL", 318, 12);
    append(ticket, tHead, true);
    append(tHead, iconBox("Ticket"));
    const tt = al("Event and ticket", "VERTICAL", 260, 4);
    append(tHead, tt, true);
    const te = append(
      tt,
      text("Festival Horizonte", 16, "ExtraBold", "textPrimary", 260),
      true,
    );
    const tn = append(
      tt,
      text("Ingresso geral", 14, "SemiBold", "textSecondary", 260),
      true,
    );
    const badge = al("Status", "HORIZONTAL", 60);
    badge.primaryAxisSizingMode = "AUTO";
    badge.counterAxisSizingMode = "AUTO";
    pad(badge, 6, 9);
    badge.cornerRadius = 8;
    fill(badge, "orangeSoft");
    append(badge, text("Válido", 11, "ExtraBold", "primaryDark"));
    append(ticket, badge);
    const divider = stage(figma.createRectangle());
    divider.name = "Divider";
    divider.resize(318, 1);
    fill(divider, "backgroundSecondary");
    append(ticket, divider, true);
    const tFoot = al("Identifier", "HORIZONTAL", 318, 8);
    tFoot.counterAxisAlignItems = "CENTER";
    append(ticket, tFoot, true);
    const ti = append(
      tFoot,
      text("Ingresso 9C42F103", 12, "SemiBold", "textSecondary", 285),
      true,
    );
    append(tFoot, icon("arrow-right-s-line", 20));
    const tb = button.createInstance();
    append(ticket, tb, true);
    ticket.description = "Ingresso válido com QR disponível. Sem sombras.";
    const ticketProps = {
      Event: prop(ticket, te, "Event"),
      Type: prop(ticket, tn, "Ticket type"),
      Id: prop(ticket, ti, "Id"),
    };
    page.appendChild(ticket);
    ticket.x = 600;
    ticket.y = 760;
    for (const [name, size] of [
      ["wifi-line", 14],
      ["battery-line", 18],
      ["search-line", 22],
      ["palette-line", 22],
      ["restaurant-line", 22],
      ["run-line", 22],
      ["code-s-slash-line", 22],
      ["book-open-line", 22],
    ])
      sizedIcon(name, size);
    return {
      createdNodeIds: flatIds(page.children),
      components: {
        scaledIcons: Object.fromEntries(
          Object.entries(scaledIcons).map(([k, v]) => [k, v.id]),
        ),
        icons: Object.fromEntries(
          Object.entries(icons).map(([k, v]) => [k, v.id]),
        ),
        nav: navs.map((n) => n.id),
        cards: { Featured: cards[0].id, Standard: cards[1].id },
        interest: interest.id,
        row: rowC.id,
        button: button.id,
        ticket: ticket.id,
      },
      properties: {
        cards: cardProps,
        interest: interestProp,
        row: rowProps,
        hasDescription,
        button: buttonProp,
        ticket: ticketProps,
      },
      images: hashes,
      counts: {
        components: page.findAllWithCriteria({ types: ["COMPONENT"] }).length,
        sets: 2,
      },
      mutatedNodeIds: [page.id],
    };
  }

  async function buildScreens(model) {
    const C = model.components,
      P = model.properties;
    const nodes = {};
    for (const id of [
      ...Object.values(C.icons),
      ...Object.values(C.scaledIcons),
      ...C.nav,
      ...Object.values(C.cards),
      C.interest,
      C.row,
      C.button,
      C.ticket,
    ])
      nodes[id] = await figma.getNodeByIdAsync(id);
    const page = figma.currentPage;
    const additionalIconSizes = {};
    function icon(name, size = 24, color = "textSecondary") {
      const key = name + "/" + size;
      let source = nodes[C.scaledIcons[key] || C.icons[name]];
      if (!source) throw new Error("Ícone não encontrado: " + name);
      if (source.width !== size) {
        if (!additionalIconSizes[key]) {
          const scaled = stage(source.clone());
          scaled.name = "Remix/" + key;
          scaled.rescale(size / source.width);
          const index = Object.keys(additionalIconSizes).length;
          library.appendChild(scaled);
          scaled.x = 1050 + (index % 8) * 72;
          scaled.y = 2360 + Math.floor(index / 8) * 80;
          additionalIconSizes[key] = scaled;
        }
        source = additionalIconSizes[key];
      }
      const n = stage(source.createInstance());
      for (const v of n.findAll((x) => x.type === "VECTOR"))
        if (v.fills.length) v.fills = [paint(color)];
      return n;
    }
    function setText(instance, props, values) {
      const definitions = instance.componentProperties;
      instance.setProperties(
        Object.fromEntries(
          Object.entries(values).map(([key, value]) => {
            const declared = props[key].split("#")[0];
            const actual = Object.keys(definitions).find(
              (k) => k.split("#")[0] === declared,
            );
            if (!actual) throw new Error("Property unavailable: " + declared);
            return [actual, value];
          }),
        ),
      );
    }
    function gap(parent, height) {
      const n = al("Space " + height, "VERTICAL", 1);
      n.resize(1, height);
      n.primaryAxisSizingMode = "FIXED";
      append(parent, n);
      return n;
    }
    function divider(parent, width) {
      const n = stage(figma.createRectangle());
      n.name = "Divider";
      n.resize(width, 1);
      fill(n, "backgroundSecondary");
      append(parent, n, true);
    }
    function bottomBorder(n) {
      n.strokes = [paint("backgroundSecondary")];
      n.strokeTopWeight = 0;
      n.strokeLeftWeight = 0;
      n.strokeRightWeight = 0;
      n.strokeBottomWeight = 1;
    }
    function avatar(size) {
      const n = al("Avatar · iniciais", "HORIZONTAL", size);
      n.resize(size, size);
      n.primaryAxisSizingMode = "FIXED";
      n.counterAxisSizingMode = "FIXED";
      n.primaryAxisAlignItems = "CENTER";
      n.counterAxisAlignItems = "CENTER";
      fill(n, "orangeSoft");
      n.cornerRadius = size / 2;
      append(
        n,
        text(
          options.name
            .trim()
            .split(/\s+/)
            .filter(Boolean)
            .slice(0, 2)
            .map((part) => part[0])
            .join("")
            .toUpperCase(),
          size === 40 ? 14 : size === 72 ? 22 : 18,
          "ExtraBold",
          "primaryDark",
        ),
      );
      return n;
    }
    const board = al("Corevent · Todas as telas", "VERTICAL", 1800, 20);
    pad(board, 40);
    fill(board, "background");
    page.appendChild(board);
    registerRoot(board);
    board.x = position.x;
    board.y = position.y;
    append(board, text("Corevent · Todas as telas", 28, "ExtraBold"));
    append(
      board,
      text(
        "Baseado no Flutter atual · Android · Dados e imagens ilustrativos",
        13,
        "Medium",
        "textSecondary",
      ),
    );
    let phoneRow;
    let rowCount = 0;
    let groupName;
    function startGroup(label, description) {
      groupName = label;
      append(board, text(label, 24, "ExtraBold"));
      append(board, text(description, 13, "Regular", "textSecondary", 1720));
      newRow();
    }
    function newRow() {
      phoneRow = al(groupName + " · Mockups Android", "HORIZONTAL", 1720, 40);
      append(board, phoneRow);
      rowCount = 0;
    }
    startGroup(
      "01 · Navegação principal",
      "Início, Explorar, Ingressos e Perfil · Topos sticky e navegação inferior",
    );
    const screens = [],
      columns = [];
    function phone(index, label, source = "", route = "") {
      if (rowCount === 4) newRow();
      rowCount++;
      const column = al(label, "VERTICAL", 390, 12);
      append(phoneRow, column);
      append(column, text(label, 15, "Bold", "textSecondary"));
      const screen = al(label + " · Android 390 × 844", "VERTICAL", 390);
      screen.resize(390, 844);
      screen.primaryAxisSizingMode = "FIXED";
      screen.counterAxisSizingMode = "FIXED";
      fill(screen);
      border(screen);
      screen.cornerRadius = 24;
      screen.clipsContent = true;
      screen.setPluginData(
        "coreventSource",
        source ||
          ["home", "explore", "tickets", "profile"].map(
            (feature) =>
              "lib/features/" +
              feature +
              "/presentation/" +
              feature +
              "_page.dart",
          )[index],
      );
      screen.setPluginData(
        "coreventRoute",
        route || ["/home", "/explore", "/tickets", "/profile"][index] || "",
      );
      append(column, screen);
      const status = al("Barra do sistema", "HORIZONTAL", 390, 6);
      status.resize(390, 28);
      status.primaryAxisSizingMode = "FIXED";
      status.counterAxisSizingMode = "FIXED";
      pad(status, 4, 20);
      status.counterAxisAlignItems = "CENTER";
      append(screen, status);
      append(status, text("9:41", 11, "Bold", "textPrimary", 290), true);
      append(status, icon("wifi-line", 14, "textPrimary"));
      append(status, icon("battery-line", 18, "textPrimary"));
      screens.push(screen);
      columns.push(column);
      return screen;
    }
    function viewport(screen) {
      const v = al("Área rolável", "VERTICAL", 390);
      v.resize(390, 600);
      v.primaryAxisSizingMode = "FIXED";
      v.counterAxisSizingMode = "FIXED";
      v.clipsContent = true;
      v.overflowDirection = "VERTICAL";
      append(screen, v);
      v.layoutSizingVertical = "FILL";
      const content = al("Conteúdo", "VERTICAL", 390);
      pad(content, 24, 20);
      append(v, content, true);
      return content;
    }
    function footer(screen, index) {
      append(screen, nodes[C.nav[index]].createInstance());
      const sys = al("Navegação do sistema", "HORIZONTAL", 390);
      sys.resize(390, 24);
      sys.primaryAxisSizingMode = "FIXED";
      sys.counterAxisSizingMode = "FIXED";
      sys.primaryAxisAlignItems = "CENTER";
      sys.counterAxisAlignItems = "CENTER";
      append(screen, sys);
      const bar = stage(figma.createRectangle());
      bar.name = "Gesture handle";
      bar.resize(104, 4);
      bar.cornerRadius = 2;
      fill(bar, "textPrimary");
      append(sys, bar);
    }
    function section(content, title, top = 0) {
      if (top) gap(content, top);
      append(content, text(title, 18, "ExtraBold", "textPrimary", 350), true);
      gap(content, 14);
    }
    function card(content, style, values) {
      const n = nodes[C.cards[style]].createInstance();
      setText(
        n,
        P.cards[style],
        values || MOCKUP_DATA.events[style === "Featured" ? 0 : 1],
      );
      append(content, n, true);
      return n;
    }
    const home = phone(0, "01 · Início");
    const homeHeader = al("Saudação sticky", "HORIZONTAL", 390, 14);
    pad(homeHeader, 13, 20);
    homeHeader.counterAxisAlignItems = "CENTER";
    bottomBorder(homeHeader);
    append(home, homeHeader);
    const greeting = al("Saudação", "VERTICAL", 296, 2);
    append(homeHeader, greeting, true);
    append(greeting, text(options.greeting, 12, "SemiBold", "textSecondary"));
    append(
      greeting,
      text(
        "Olá, " + options.name.trim().split(/\s+/)[0] + "!",
        18,
        "ExtraBold",
      ),
    );
    append(homeHeader, avatar(40));
    const hc = viewport(home);
    section(hc, "Para sua próxima saída");
    card(hc, "Featured");
    section(hc, "Encontre sua experiência", 28);
    const interests = [
      ["Música", "music-2-line"],
      ["Arte e cultura", "palette-line"],
      ["Gastronomia", "restaurant-line"],
      ["Esportes", "run-line"],
      ["Tecnologia", "code-s-slash-line"],
      ["Educação", "book-open-line"],
    ];
    for (let r = 0; r < 3; r++) {
      const row = al("Interesses " + r, "HORIZONTAL", 350, 10);
      append(hc, row, true);
      for (let k = 0; k < 2; k++) {
        const [label, glyph] = interests[r * 2 + k];
        const n = nodes[C.interest].createInstance();
        n.setProperties({ [P.interest]: label });
        const current = n.findAllWithCriteria({ types: ["INSTANCE"] })[0];
        current.swapComponent(
          nodes[C.scaledIcons[glyph + "/22"] || C.icons[glyph]],
        );
        for (const v of current.findAll((x) => x.type === "VECTOR"))
          if (v.fills.length) v.fills = [paint("primaryDark")];
        append(row, n);
      }
      if (r < 2) gap(hc, 10);
    }
    gap(hc, 12);
    append(hc, text("Ver todas as categorias", 13, "ExtraBold", "primaryDark"));
    section(hc, "Neste fim de semana", 28);
    card(hc, "Standard");
    gap(hc, 18);
    append(
      hc,
      text("Explorar o fim de semana", 13, "ExtraBold", "primaryDark"),
    );
    footer(home, 0);
    const explore = phone(1, "02 · Explorar");
    const searchHeader = al("Busca sticky", "VERTICAL", 390);
    pad(searchHeader, 13, 20);
    bottomBorder(searchHeader);
    append(explore, searchHeader);
    const search = al("Campo de busca", "HORIZONTAL", 350, 10);
    search.resize(350, 54);
    search.primaryAxisSizingMode = "FIXED";
    search.counterAxisSizingMode = "FIXED";
    pad(search, 12, 14);
    search.counterAxisAlignItems = "CENTER";
    fill(search, "background");
    border(search);
    radius(search, "field");
    append(searchHeader, search);
    append(search, icon("search-line", 22));
    append(
      search,
      text(
        "Busque eventos, shows e experiências",
        12,
        "Regular",
        "textSecondary",
        284,
      ),
      true,
    );
    const ec = viewport(explore);
    section(ec, "Categorias");
    const chipsView = al("Categorias · rolagem horizontal", "HORIZONTAL", 350);
    chipsView.resize(350, 38);
    chipsView.primaryAxisSizingMode = "FIXED";
    chipsView.counterAxisSizingMode = "FIXED";
    chipsView.clipsContent = true;
    chipsView.overflowDirection = "HORIZONTAL";
    append(ec, chipsView);
    const chips = al("Chips", "HORIZONTAL", 500, 8);
    chips.counterAxisSizingMode = "AUTO";
    append(chipsView, chips);
    for (const label of ["Todas", "Música", "Tecnologia", "Esportes"]) {
      const n = al("Filtro " + label, "HORIZONTAL", 80);
      n.primaryAxisSizingMode = "AUTO";
      n.counterAxisSizingMode = "AUTO";
      pad(n, 9, 12);
      n.cornerRadius = 18;
      fill(n, label === "Todas" ? "orangeSoft" : "surface");
      border(n);
      append(
        n,
        text(
          label,
          12,
          "Bold",
          label === "Todas" ? "primaryDark" : "textSecondary",
        ),
      );
      append(chips, n);
    }
    section(ec, "Todos os eventos", 24);
    card(ec, "Standard", MOCKUP_DATA.events[0]);
    gap(ec, 12);
    card(ec, "Standard");
    footer(explore, 1);
    const tickets = phone(2, "03 · Ingressos");
    const tc = viewport(tickets);
    const ticket1 = nodes[C.ticket].createInstance();
    append(tc, ticket1, true);
    gap(tc, 12);
    const ticket2 = nodes[C.ticket].createInstance();
    setText(ticket2, P.ticket, {
      Event: "Noite de arte e música",
      Type: "Entrada gratuita",
      Id: "Ingresso 7136C092",
    });
    append(tc, ticket2, true);
    footer(tickets, 2);
    const profile = phone(3, "04 · Perfil");
    const ph = al("Conta sticky", "HORIZONTAL", 390, 14);
    pad(ph, 16, 20);
    ph.counterAxisAlignItems = "CENTER";
    bottomBorder(ph);
    append(profile, ph);
    append(ph, avatar(54));
    const pt = al("Conta", "VERTICAL", 268, 4);
    append(ph, pt, true);
    append(pt, text(options.name, 18, "ExtraBold", "textPrimary", 268), true);
    append(
      pt,
      text(
        "Membro há " + options.memberDays + " dias",
        13,
        "Regular",
        "textSecondary",
      ),
    );
    const pc = viewport(profile);
    pc.paddingTop = 24;
    function group(title, rows) {
      append(pc, text(title, 14, "ExtraBold", "textSecondary"));
      gap(pc, 12);
      const g = al(title + " · Opções", "VERTICAL", 350);
      fill(g);
      border(g);
      radius(g, "card");
      g.clipsContent = true;
      append(pc, g, true);
      for (let i = 0; i < rows.length; i++) {
        if (i) divider(g, 350);
        const [label, description, glyph] = rows[i];
        const n = nodes[C.row].createInstance();
        setText(n, P.row, { Title: label, Description: description || "" });
        if (!description) n.setProperties({ [P.hasDescription]: false });
        const ico = n.findAllWithCriteria({ types: ["INSTANCE"] })[0];
        ico.swapComponent(nodes[C.icons[glyph]]);
        for (const v of ico.findAll((x) => x.type === "VECTOR"))
          if (v.fills.length) v.fills = [paint("primary")];
        append(g, n, true);
      }
    }
    group("Minha atividade", [
      ["Pedidos", "Acompanhe suas compras e pagamentos", "receipt-line"],
      ["Favoritos", "Eventos que você salvou", "heart-line"],
      ["Avaliações", "Suas notas sobre eventos", "star-line"],
    ]);
    gap(pc, 24);
    group("Minha conta", [
      ["Dados pessoais", null, "user-line"],
      ["Segurança", "Altere sua senha", "lock-line"],
    ]);
    gap(pc, 28);
    const logout = nodes[C.button].createInstance();
    logout.setProperties({ [P.button]: "Sair da conta" });
    logout.strokes = [paint("backgroundSecondary")];
    const li = logout.findAllWithCriteria({ types: ["INSTANCE"] })[0];
    li.swapComponent(nodes[C.icons["logout-box-r-line"]]);
    for (const v of li.findAll((x) => x.type === "VECTOR"))
      if (v.fills.length) v.fills = [paint("primaryDark")];
    append(pc, logout, true);
    footer(profile, 3);
    await renderAdditionalScreens({
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
      bottomBorder,
      avatar,
      phone,
      viewport,
      footer,
      section,
      card,
      startGroup,
      backgrounds: { home, explore, tickets, profile },
    });
    append(
      board,
      text(
        "Superfícies brancas · Bordas sutis · Plus Jakarta Sans · Remix Icons · Sem sombras, gradientes ou glow",
        12,
        "Medium",
        "textSecondary",
      ),
    );
    return {
      createdNodeIds: flatIds([board]),
      board: board.id,
      screens: screens.map((n) => ({
        id: n.id,
        name: n.name,
        width: n.width,
        height: n.height,
        source: n.getPluginData("coreventSource"),
        route: n.getPluginData("coreventRoute"),
      })),
      textCount: board.findAllWithCriteria({ types: ["TEXT"] }).length,
      instanceCount: board.findAllWithCriteria({ types: ["INSTANCE"] }).length,
      fonts: [
        ...new Set(
          board
            .findAllWithCriteria({ types: ["TEXT"] })
            .map((n) => n.fontName.family),
        ),
      ],
      mutatedNodeIds: [page.id],
    };
  }

  const model = buildComponents();
  const result = await buildScreens(model);
  const board = await figma.getNodeByIdAsync(result.board);
  if (!board || board.type !== "FRAME") {
    throw new Error("Não foi possível localizar o painel de telas.");
  }
  library.y = position.y + board.height + 120;
  library.resize(
    1800,
    Math.max(
      2850,
      ...library.children.map((node) => node.y + node.height + 80),
    ),
  );
  const all = board.findAll(() => true);
  const imageNodes = all.filter(
    (node) =>
      "fills" in node &&
      node.fills !== figma.mixed &&
      node.fills.some((paint) => paint.type === "IMAGE"),
  );
  if (
    result.screens.length !== MOCKUP_DATA.catalog.length ||
    new Set(result.screens.map((screen) => screen.name)).size !==
      result.screens.length ||
    result.screens.some(
      (screen) => screen.width !== 390 || screen.height !== 844,
    )
  ) {
    throw new Error(
      "Verifique a quantidade, os nomes e o tamanho dos frames Android de 390 × 844.",
    );
  }
  if (
    imageNodes.length < 8 ||
    all.some((node) => "effects" in node && node.effects.length)
  ) {
    throw new Error(
      "Verifique os banners e a ausência de efeitos nos mockups.",
    );
  }
  if (result.fonts.length !== 1 || result.fonts[0] !== FONT_FAMILY) {
    throw new Error("A fonte da composição ficou inconsistente.");
  }
  const missingRoutes = MOCKUP_DATA.routes.filter(
    (route) => !result.screens.some((screen) => screen.route === route),
  );
  if (missingRoutes.length)
    throw new Error("Rotas sem mockup: " + missingRoutes.join(", "));
  const missingViews = MOCKUP_DATA.catalog.filter(
    (view) =>
      !result.screens.some(
        (screen) =>
          screen.name === view.name + " · Android 390 × 844" &&
          screen.source === view.source &&
          screen.route === view.route,
      ),
  );
  if (missingViews.length)
    throw new Error(
      "Mockups ausentes ou com referência diferente: " +
        missingViews.map((view) => view.name).join(", "),
    );
  return { ...result, library: library.id };
}
