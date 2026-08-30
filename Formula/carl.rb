# frozen_string_literal: true

# Homebrew-формула для Carl — персонального Telegram-бота с методологией ФПФ.
#
# Layout:
#   prefix/bin/carl          — wrapper-скрипт (ссылка на libexec/bin/carl)
#   prefix/libexec/           — изолированное окружение:
#   ├── bin/carl              — entry point (bash → venv/python -m bot.cli)
#   ├── lib/codex/            — зафиксированный Codex CLI
#   │   ├── bin/codex.js      — Node.js entry point
#   │   └── vendor/<triple>/codex/codex — platform binaries
#   └── venv/                 — Python-venv с runtime-зависимостями
#       └── lib/python3.12/site-packages/
#           ├── bot/          — пакет Python
#           ├── fpf/          — read-only FPF-ассеты (FPF-Spec.md, PINNED.md, …)
#           └── pyproject.toml — нужен для fallback-определения версии
#
# Переменные окружения, которые выставляет wrapper:
#   CODEX_BIN  → libexec/lib/codex/bin/codex.js  (собственный Codex, не PATH)
#   PATH       → libexec/bin:$PATH            — entry point и зависимости
#
# Пользовательские данные (секреты, .leo, knowledge, projects) живут в
# ~/.config/carl и cwd, НЕ в prefix. Uninstall удаляет только formula-owned
# файлы; данные пользователя сохраняются.
#
# Обновление resource-hashes:
#   1. Python: `uv lock` → пересобрать resource-блоки из uv.lock (runtime).
#      Homebrew всегда ставит Python resources из исходников
#      (`pip install --no-binary=:all:`) — wheel-URL не работают ни для
#      одного пакета. Все resource-блоки, включая компилируемые
#      (pydantic-core, aiohttp, frozenlist, multidict, propcache,
#      yarl), — PyPI sdist (.tar.gz); URL и sha256 берутся из поля sdist
#      в uv.lock (эквивалент вывода `brew update-python-resources`).
#   2. Codex:  обновить CODEX_VERSION и sha256 ресурса codex.
#      Пакет @openai/codex — self-contained: vendored бинарники для всех
#      платформ включены в tarball, npm-зависимостей нет.
#      SHA256: `shasum -a 256` скачанного .tgz.
#   3. Source: новая версия — новый неизменяемый тег. Собрать
#      `python -m build --sdist`, опубликовать именно этот файл как release
#      asset (`gh release create`, без --clobber поверх существующего тега),
#      затем взять SHA256 уже ОПУБЛИКОВАННОГО файла:
#      `curl -sL <url-релиза> | shasum -a 256`. Хэш локальной пересборки не
#      подставлять — check_formula.py сверяет формулу с реальным
#      опубликованным asset, а не с dist/.
#
class Carl < Formula
  include Language::Python::Virtualenv

  desc "Персональный Telegram-бот, ведущий проект через методологию ФПФ"
  homepage "https://github.com/deadsimple-xyz/carl"
  # Источник — Python sdist (воспроизводимая сборка через hatchling).
  # Содержит bot/, fpf/ и pyproject.toml; не содержит .leo, knowledge, .env.
  url "https://github.com/deadsimple-xyz/carl/releases/download/v0.1.0/leo_bot-0.1.0.tar.gz"
  sha256 "33f23175d7e52fc7b94dd7c88590aa544ddae64493f4aa84c85d47796f74c779"
  license :cannot_represent

  # rust — build-time зависимость pydantic-core. Пакет собирается из sdist
  # через maturin, которому нужен Rust-тулчейн (cargo/rustc); полагаться на
  # случайно установленный rustc на хосте нельзя — формула требует его явно.
  # Build-зависимости объявляются раньше runtime (требование brew audit --strict).
  depends_on "rust" => :build
  # Python 3.12+ — runtime. Node — для запуска зафиксированного Codex CLI.
  depends_on "node"
  depends_on "python@3.12"

  # Короткое имя formula совпадает с homebrew/core/carl (Calendar CLI,
  # codeberg.org/birger/carl) — обе формулы ставят бинарник `carl`.
  conflicts_with "carl", because: "both install a carl binary"
  # ── Python runtime-зависимости ────────────────────────────
  # Homebrew ставит Python resources из исходников (`pip install
  # --no-binary=:all:`), поэтому все resource-блоки — PyPI sdist,
  # включая ранее-wheel компилируемые пакеты (pydantic-core,
  # aiohttp, frozenlist, multidict, propcache, yarl).
  # Обновление: `uv lock` → перегенерировать блоки из uv.lock (исключая
  # leo-bot, pytest, pytest-asyncio, respx, ruff, iniconfig, colorama,
  # pygments, build, packaging, pyproject-hooks, pluggy).
  # URL и sha256 берутся из поля sdist каждого пакета в uv.lock.

  resource "aiofiles" do
    url "https://files.pythonhosted.org/packages/41/c3/534eac40372d8ee36ef40df62ec129bee4fdb5ad9706e58a29be53b2c970/aiofiles-25.1.0.tar.gz"
    sha256 "a8d728f0a29de45dc521f18f07297428d56992a742f0cd2701ba86e44d23d5b2"
  end

  resource "aiogram" do
    url "https://files.pythonhosted.org/packages/55/07/5978f99d7e799843a6a248c5418ef99a8a4aedc8e411b736739b0d93b78f/aiogram-3.30.0.tar.gz"
    sha256 "04a5c43d0acedaf907ffa9a1b6c651cd5fde35b5bca82f521e57d77a57e63bc6"
  end

  resource "aiohappyeyeballs" do
    url "https://files.pythonhosted.org/packages/ce/f4/eec0465c2f67b2664688d0240b3212d5196fd89e741df67ddb81f8d35658/aiohappyeyeballs-2.7.1.tar.gz"
    sha256 "065665c041c42a5938ed220bdcd7230f22527fbec085e1853d2402c8a3615d9d"
  end

  resource "aiohttp" do
    url "https://files.pythonhosted.org/packages/58/d9/22ce5786ac0c1653ae8b6c23bded02c1686d11f0dbb45b31ce128e0df985/aiohttp-3.14.3.tar.gz"
    sha256 "9491196535a88924a60afd5b5f434b5b203b6cc616250878dbdb223a8f7844bc"
  end

  resource "aiosignal" do
    url "https://files.pythonhosted.org/packages/61/62/06741b579156360248d1ec624842ad0edf697050bbaf7c3e46394e106ad1/aiosignal-1.4.0.tar.gz"
    sha256 "f47eecd9468083c2029cc99945502cb7708b082c232f9aca65da147157b251c7"
  end

  resource "annotated-types" do
    url "https://files.pythonhosted.org/packages/5f/56/a8120250d128bed162cd73c76d45f6ef9991f3e068f62a8ee060afa3104a/annotated_types-0.8.0.tar.gz"
    sha256 "13b2beaad985e05e2d6407ee4c4f35590b11f8d693a258a561055cac8f64cab7"
  end

  resource "anyio" do
    url "https://files.pythonhosted.org/packages/61/cc/a381afa6efea9f496eff839d4a6a1aed3bfafc7b3ab4b0d1b243a12573dd/anyio-4.14.2.tar.gz"
    sha256 "cfa139f3ed1a23ee8f88a145ddb5ac7605b8bbfd8592baacd7ce3d8bb4313c7f"
  end

  resource "attrs" do
    url "https://files.pythonhosted.org/packages/9a/8e/82a0fe20a541c03148528be8cac2408564a6c9a0cc7e9171802bc1d26985/attrs-26.1.0.tar.gz"
    sha256 "d03ceb89cb322a8fd706d4fb91940737b6642aa36998fe130a9bc96c985eff32"
  end

  resource "certifi" do
    url "https://files.pythonhosted.org/packages/a3/c2/24167ea9858356b47a87a50d39908bfdb72ceeefe0041586e704e5376b3a/certifi-2026.7.22.tar.gz"
    sha256 "741e2c3b351ddf169a738da9f2c048608ff7f2c5cc02f1ebc6b118bb090d5d55"
  end

  resource "frozenlist" do
    url "https://files.pythonhosted.org/packages/2d/f5/c831fac6cc817d26fd54c7eaccd04ef7e0288806943f7cc5bbf69f3ac1f0/frozenlist-1.8.0.tar.gz"
    sha256 "3ede829ed8d842f6cd48fc7081d7a41001a56f1f38603f9d49bf3020d59a31ad"
  end

  resource "h11" do
    url "https://files.pythonhosted.org/packages/01/ee/02a2c011bdab74c6fb3c75474d40b3052059d95df7e73351460c8588d963/h11-0.16.0.tar.gz"
    sha256 "4e35b956cf45792e4caa5885e69fba00bdbc6ffafbfa020300e549b208ee5ff1"
  end

  resource "httpcore" do
    url "https://files.pythonhosted.org/packages/06/94/82699a10bca87a5556c9c59b5963f2d039dbd239f25bc2a63907a05a14cb/httpcore-1.0.9.tar.gz"
    sha256 "6e34463af53fd2ab5d807f399a9b45ea31c3dfa2276f15a2c3f00afff6e176e8"
  end

  resource "httpx" do
    url "https://files.pythonhosted.org/packages/b1/df/48c586a5fe32a0f01324ee087459e112ebb7224f646c0b5023f5e79e9956/httpx-0.28.1.tar.gz"
    sha256 "75e98c5f16b0f35b567856f597f06ff2270a374470a5c2392242528e3e3e42fc"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/5f/f7/abb373e5757eaec4b922b92f97ec8d6d7e057cf06778247604fbc4e7c3f3/idna-3.19.tar.gz"
    sha256 "5e0811a4383b21dc5838069f801c4fb62113b7447663d2530d2bd6e77b49bf15"
  end

  resource "magic-filter" do
    url "https://files.pythonhosted.org/packages/e6/08/da7c2cc7398cc0376e8da599d6330a437c01d3eace2f2365f300e0f3f758/magic_filter-1.0.12.tar.gz"
    sha256 "4751d0b579a5045d1dc250625c4c508c18c3def5ea6afaf3957cb4530d03f7f9"
  end

  resource "multidict" do
    url "https://files.pythonhosted.org/packages/1a/c2/c2d94cbe6ac1753f3fc980da97b3d930efe1da3af3c9f5125354436c073d/multidict-6.7.1.tar.gz"
    sha256 "ec6652a1bee61c53a3e5776b6049172c53b6aaba34f18c9ad04f82712bac623d"
  end

  resource "propcache" do
    url "https://files.pythonhosted.org/packages/ec/44/c87281c333769159c50594f22610f77398a47ccbfbbf23074e744e86f87c/propcache-0.5.2.tar.gz"
    sha256 "01c4fc7480cd0598bb4b57022df55b9ca296da7fc5a8760bd8451a7e63a7d427"
  end

  resource "pydantic" do
    url "https://files.pythonhosted.org/packages/18/a5/b60d21ac674192f8ab0ba4e9fd860690f9b4a6e51ca5df118733b487d8d6/pydantic-2.13.4.tar.gz"
    sha256 "c40756b57adaa8b1efeeced5c196f3f3b7c435f90e84ea7f443901bec8099ef6"
  end

  resource "pydantic-core" do
    url "https://files.pythonhosted.org/packages/9d/56/921726b776ace8d8f5db44c4ef961006580d91dc52b803c489fafd1aa249/pydantic_core-2.46.4.tar.gz"
    sha256 "62f875393d7f270851f20523dd2e29f082bcc82292d66db2b64ea71f64b6e1c1"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/f6/cc/6253133b5bb138fc3306cebfbda2c520f545d36b5be2c7255cc528bb45d6/typing_extensions-4.16.0.tar.gz"
    sha256 "dc983d19a509c94dba722ee6abd33940f7c05a89e243c47e907eb4db6f1a43e5"
  end

  resource "typing-inspection" do
    url "https://files.pythonhosted.org/packages/a3/26/b09b8010994eccc3c09092e6b34058f36a460eea2d4c3e8b910c695975a0/typing_inspection-0.4.4.tar.gz"
    sha256 "547274fa6b0a561ccf549cc9524b999a578e737d015d8709d021f9d0d13bea47"
  end

  resource "yarl" do
    url "https://files.pythonhosted.org/packages/31/33/ebe9e3d1f86c7a0b51094c0a146392045ca1631d2664889539dec8088a33/yarl-1.24.5.tar.gz"
    sha256 "e81b83143bee16329c23db3c1b2d82b29892fcbcb849186d2f6e98a5abe9a57f"
  end

  # ── Codex CLI (npm, self-contained) ──────────────────────────────────────
  # Пакет @openai/codex — self-contained: vendored бинарники для всех платформ
  # (aarch64-apple-darwin, x86_64-apple-darwin, …) включены в tarball.
  # Структура после извлечения:
  #   libexec/lib/codex/bin/codex.js              — Node.js entry point
  #   libexec/lib/codex/vendor/<triple>/codex/codex — platform binary
  #   libexec/lib/codex/vendor/<triple>/path/rg    — ripgrep binary
  # npm-зависимостей НЕТ — transitive resource-блоки не нужны.
  #
  # Обновление: изменить CODEX_VERSION и sha256.
  # SHA256 вычислить: `curl -sL https://registry.npmjs.org/@openai/codex/-/codex-<version>.tgz | shasum -a 256`

  CODEX_VERSION = "0.60.1"

  resource "codex" do
    url "https://registry.npmjs.org/@openai/codex/-/codex-#{CODEX_VERSION}.tgz"
    sha256 "834005574d68f3636ee63cdea891f95f13a976d3ed223df5b8ff07f876101791"
  end

  def install
    # ── Python venv ────────────────────────────────────────────────────────
    # Создаём изолированный venv через Homebrew Virtualenv API; все Python-ресурсы
    # ставим из локальных sdist tarball (скачаны на этапе brew fetch, проверены
    # по sha256). Homebrew всегда собирает Python resources из исходников
    # (`pip install --no-binary=:all:`), поэтому компилируемые пакеты
    # (pydantic-core, aiohttp, frozenlist, multidict, propcache, yarl)
    # тоже собираются на месте — без сети (build isolation отключена), но с
    # системным C compiler (Xcode CLT).
    # virtualenv_create возвращает объект Virtualenv с методом pip_install.
    python = formula_opt_bin("python@3.12")/"python3.12"
    venv_root = libexec/"venv"
    venv = virtualenv_create(venv_root, python)

    # Runtime-зависимости из resource-блоков (только Python, не codex).
    resources.each do |r|
      next if r.name == "codex"

      venv.pip_install r
    end

    # ── Carl: прямое копирование исходников ────────────────────────────────
    # Не используем `pip wheel .` / `pip install .` — это потребовало бы
    # hatchling (build-system) в build-окружении, а build isolation скачал
    # бы его из сети. Вместо этого копируем пакет в site-packages venv
    # напрямую: entry point создаём вручную.
    site_packages = Pathname.new(Dir[venv_root/"lib/python*/site-packages"].first)
    # Pathname#install копирует источник ВНУТРЬ целевой директории:
    # site_packages.install buildpath/"bot" → site-packages/bot/
    # НЕ (site_packages/"bot").install — это создаст site-packages/bot/bot/.
    site_packages.install buildpath/"bot"
    # FPF-ассеты — рядом с пакетом, чтобы _package_root() нашёл fpf/.
    (site_packages/"fpf").install buildpath/"fpf/FPF-Spec.md",
                                  buildpath/"fpf/PINNED.md",
                                  buildpath/"fpf/Readme.md",
                                  buildpath/"fpf/Narrativization-and-Narrative-Studies-Principles-Framework.md"
    # pyproject.toml — для fallback-определения версии в cli.py.
    site_packages.install buildpath/"pyproject.toml"

    # ── Codex CLI (зафиксированный, собственный) ───────────────────────────
    # Пакет @openai/codex — self-contained tarball с vendored бинарниками
    # для всех платформ. Извлекаем напрямую (npm не нужен для установки).
    # Структура после извлечения:
    #   libexec/lib/codex/bin/codex.js              — Node.js entry point
    #   libexec/lib/codex/vendor/<triple>/codex/codex — platform binary
    codex_dir = libexec/"lib/codex"
    codex_dir.mkpath
    system "tar", "-xzf", resource("codex").cached_download,
           "-C", codex_dir.to_s, "--strip-components=1"

    # ── Entry point + wrapper (единый скрипт) ──────────────────────────────
    # Bash-обёртка: выставляет CODEX_BIN на собственный codex, затем
    # передаёт управление venv/python с модулем bot.cli.
    # _package_root() в cli.py резолвится через bot/__file__ → site-packages,
    # где лежат bot/, fpf/, pyproject.toml.
    (libexec/"bin").mkpath
    carl_exe = libexec/"bin/carl"
    carl_exe.write <<~SH
      #!/bin/bash
      exec env \\
        CODEX_BIN="#{codex_dir}/bin/codex.js" \\
        PATH="#{libexec}/bin:#{formula_opt_bin("node")}:$PATH" \\
        "#{venv_root}/bin/python" -m bot.cli "$@"
    SH
    carl_exe.chmod 0755

    # ── Публичная ссылка ───────────────────────────────────────────────────
    bin.install_symlink libexec/"bin/carl"
  end

  test do
    # carl --version: не требует Telegram-токена, сети и polling.
    version_out = shell_output("#{bin}/carl --version").strip
    assert_match(/\d+\.\d+/, version_out, "carl --version должен содержать номер версии")

    # carl --diagnose-install: находит packaged FPF-assets и завершается с кодом 0.
    diagnose_out = shell_output("#{bin}/carl --diagnose-install")
    assert_match(/✓/, diagnose_out, "диагностика должна найти FPF-ассеты")

    # Импорт bot — пакет доступен в venv site-packages.
    venv_python = libexec/"venv/bin/python"
    import_out = shell_output("#{venv_python} -c 'import bot; print(bot.__file__)'").strip
    assert_match(%r{bot/__init__\.py$}, import_out, "bot должен импортироваться из site-packages")

    # PINNED.md присутствует в installed fpf/ и содержит ожидаемые маркеры.
    site_packages = Dir[(libexec/"venv/lib/python*/site-packages").to_s].first
    fpf_dir = Pathname.new(site_packages)/"fpf"
    pinned = fpf_dir/"PINNED.md"
    assert_path_exists pinned, "PINNED.md должен быть установлен в site-packages/fpf/"
    pinned_content = pinned.read
    assert_match(/FPF-Spec\.md/, pinned_content, "PINNED.md должен ссылаться на FPF-Spec.md")
    assert_path_exists fpf_dir/"FPF-Spec.md", "FPF-Spec.md должен быть установлен"
    assert_predicate fpf_dir/"FPF-Spec.md", :size?, "FPF-Spec.md не должен быть пустым"

    # Codex CLI: проверяем наличие platform binary для текущей архитектуры
    # и запускаем codex.js через node для проверки версии.
    codex_js = libexec/"lib/codex/bin/codex.js"
    assert_path_exists codex_js, "codex.js должен быть установлен в libexec/lib/codex/bin/"

    # Проверяем наличие platform binary (не только codex.js).
    target_triple = if Hardware::CPU.arm?
      "aarch64-apple-darwin"
    else
      "x86_64-apple-darwin"
    end
    platform_binary = libexec/"lib/codex/vendor"/target_triple/"codex/codex"
    assert_path_exists platform_binary,
                       "platform binary #{target_triple}/codex/codex должен быть установлен в vendor/"

    # Запускаем codex.js через node и проверяем версию.
    codex_version_out = shell_output("#{formula_opt_bin("node")}/node #{codex_js} --version 2>&1").strip
    assert_match(/\d+\.\d+/, codex_version_out, "codex --version должен содержать номер версии")
  end
end
