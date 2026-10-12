// Local Figma Plugin API. This file is not run through MCP.
const OWNER_KEY = "coreventMockupsOwner";
const ROLE_KEY = "coreventMockupsRole";
const BUILD_KEY = "coreventMockupsBuild";
const FONT_FAMILY = "Plus Jakarta Sans";
let running = false;

async function loadFonts() {
  const available = await figma.listAvailableFontsAsync();
  const normalize = (value) => value.toLowerCase().replace(/\s/g, "");
  const fonts = {};
  for (const style of ["Regular", "Medium", "SemiBold", "Bold", "ExtraBold"]) {
    const match = available.find(
      ({ fontName }) =>
        fontName.family === FONT_FAMILY &&
        normalize(fontName.style) === normalize(style),
    );
    if (!match) {
      throw new Error(
        `Instale Plus Jakarta Sans (${style}) e reinicie o Figma Desktop. Consulte o README do plugin.`,
      );
    }
    fonts[style] = match.fontName;
  }
  await Promise.all(
    Object.values(fonts).map((font) => figma.loadFontAsync(font)),
  );
  return fonts;
}

async function ensureTokens() {
  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const local = await figma.variables.getLocalVariablesAsync();
  const findCollection = (role, name) => {
    let collection = collections.find(
      (item) => item.getPluginData(ROLE_KEY) === role,
    );
    if (!collection) {
      collection = figma.variables.createVariableCollection(name);
      collection.setPluginData(ROLE_KEY, role);
      collection.renameMode(collection.defaultModeId, "Light");
    }
    return collection;
  };
  const primitives = findCollection(
    "primitives",
    "Corevent Mockups · Primitivos",
  );
  const semantic = findCollection("semantic", "Corevent Mockups · App");
  const upsert = (collection, name, type, value, scopes) => {
    let variable = local.find(
      (item) =>
        item.variableCollectionId === collection.id && item.name === name,
    );
    if (!variable)
      variable = figma.variables.createVariable(name, collection, type);
    if (variable.resolvedType !== type)
      throw new Error(`Tipo incompatível no token ${name}.`);
    variable.scopes = scopes;
    variable.setValueForMode(collection.defaultModeId, value);
    return variable;
  };
  const variables = {};
  for (const [name, hex] of Object.entries(MOCKUP_DATA.colors)) {
    const rgb = {
      r: parseInt(hex.slice(0, 2), 16) / 255,
      g: parseInt(hex.slice(2, 4), 16) / 255,
      b: parseInt(hex.slice(4, 6), 16) / 255,
      a: 1,
    };
    const primitive = upsert(primitives, `color/${name}`, "COLOR", rgb, []);
    const key = `AppColors/${name}`;
    variables[key] = upsert(
      semantic,
      key,
      "COLOR",
      figma.variables.createVariableAlias(primitive),
      ["ALL_FILLS", "STROKE_COLOR"],
    );
    variables[key].setVariableCodeSyntax("ANDROID", `AppColors.${name}`);
  }
  for (const [name, value] of Object.entries({
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
  })) {
    const key = `AppSpacing/${name}`;
    variables[key] = upsert(semantic, key, "FLOAT", value, ["GAP"]);
    variables[key].setVariableCodeSyntax("ANDROID", `AppSpacing.${name}`);
  }
  for (const [name, value] of Object.entries({
    field: 14,
    button: 18,
    card: 20,
  })) {
    const key = `AppRadii/${name}`;
    variables[key] = upsert(semantic, key, "FLOAT", value, ["CORNER_RADIUS"]);
  }
  return variables;
}

function validateOptions(message) {
  const name = String(message.name || "").trim();
  const memberDays = Number(message.memberDays);
  if (!name || name.length > 40)
    throw new Error("Informe um nome de até 40 caracteres.");
  if (!Number.isInteger(memberDays) || memberDays < 0 || memberDays > 99999) {
    throw new Error("Informe uma quantidade válida de dias.");
  }
  if (!["Bom dia", "Boa tarde", "Boa noite"].includes(message.greeting)) {
    throw new Error("Escolha uma saudação válida.");
  }
  return {
    name,
    memberDays,
    greeting: message.greeting,
    copy: message.copy === true,
  };
}

async function generate(message) {
  const options = validateOptions(message);
  // Check fonts before creating any canvas nodes.
  const fonts = await loadFonts();
  const page = figma.currentPage;
  const previous = options.copy
    ? []
    : page.children.filter(
        (node) => node.getPluginData(OWNER_KEY) === "primary",
      );
  const oldBoard = previous.find(
    (node) => node.getPluginData(ROLE_KEY) === "screens",
  );
  const right = page.children.reduce(
    (max, node) => Math.max(max, node.x + node.width),
    0,
  );
  const position = oldBoard
    ? { x: oldBoard.x, y: oldBoard.y }
    : { x: right + 100, y: 100 };
  const created = [];
  const buildId = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  try {
    const result = await renderMockups(
      options,
      fonts,
      position,
      (node) => created.push(node),
      buildId,
    );
    const board = await figma.getNodeByIdAsync(result.board);
    const library = await figma.getNodeByIdAsync(result.library);
    if (
      !board ||
      board.type !== "FRAME" ||
      !library ||
      library.type !== "FRAME"
    ) {
      throw new Error("Não foi possível localizar os blocos gerados.");
    }
    board.setPluginData(OWNER_KEY, options.copy ? "copy" : "primary");
    board.setPluginData(ROLE_KEY, "screens");
    library.setPluginData(OWNER_KEY, options.copy ? "copy" : "primary");
    library.setPluginData(ROLE_KEY, "components");
    // Existing mockups remain until the replacement has passed validation.
    for (const node of previous) node.remove();
    page.selection = [board];
    const firstScreen = await figma.getNodeByIdAsync(result.screens[0].id);
    figma.viewport.scrollAndZoomIntoView(firstScreen ? [firstScreen] : [board]);
    figma.commitUndo();
    return `${options.copy ? "Cópia criada" : "Mockups gerados/atualizados"}: ${result.screens.length} telas e estados, ${result.textCount} textos editáveis. Fluxos organizados em grupos; componentes abaixo.`;
  } catch (error) {
    for (const node of created) if (!node.removed) node.remove();
    // Also clean up unattached nodes from an interrupted construction.
    for (const node of [...page.children]) {
      if (node.getPluginData(BUILD_KEY) === buildId) node.remove();
    }
    throw error;
  }
}

figma.showUI(__html__, { width: 360, height: 640, themeColors: false });
figma.ui.onmessage = async (message) => {
  if (message.type === "ready") {
    figma.ui.postMessage({
      type: "defaults",
      name: MOCKUP_DATA.name,
      memberDays: MOCKUP_DATA.memberDays,
      greeting: MOCKUP_DATA.greeting,
    });
    return;
  }
  if (message.type === "close") {
    if (!running) figma.closePlugin();
    return;
  }
  if (message.type !== "generate" || running) return;
  running = true;
  figma.ui.postMessage({ type: "busy" });
  try {
    const detail = await generate(message);
    figma.ui.postMessage({ type: "success", detail });
  } catch (error) {
    figma.ui.postMessage({
      type: "error",
      detail: error instanceof Error ? error.message : String(error),
    });
  } finally {
    running = false;
  }
};
