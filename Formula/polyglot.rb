require "download_strategy"
require "utils/github/api"

# The release asset lives on a private repository. The declared url is the asset's browser url; at fetch
# time the release is read by tag through the GitHub REST API with Homebrew's own GitHub credential, and the
# asset is downloaded from its API url. `sha256` still pins the bytes (same approach as Loop's own formula).
class PolyglotReleaseDownloadStrategy < CurlDownloadStrategy
  ASSET_URL = %r{\Ahttps://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/([^/]+)\z}

  private

  def resolve_url_basename_time_file_size(url, timeout: nil)
    return super if url.start_with?("#{GitHub::API_URL}/")

    super(polyglot_asset_api_url(url), timeout:)
  end

  def polyglot_asset_api_url(url)
    @polyglot_asset_api_url ||= begin
      match = ASSET_URL.match(url)
      raise CurlDownloadStrategyError.new(url, "polyglot_release_asset_url_invalid") unless match

      owner, repository, tag, asset = match.captures
      token = GitHub::API.credentials
      if token.blank?
        raise CurlDownloadStrategyError.new(
          url, "polyglot_release_download_unauthenticated: run `gh auth login`, then run brew again"
        )
      end

      base = "#{GitHub::API_URL}/repos/#{owner}/#{repository}/releases"
      release = GitHub::API.open_rest("#{base}/tags/#{tag}")
      assets = GitHub::API.open_rest("#{base}/#{release.fetch("id")}/assets?per_page=100")
      found = assets.find { |candidate| candidate["name"] == asset }
      raise CurlDownloadStrategyError.new(url, "polyglot_release_asset_missing: #{asset} on #{tag}") if found.nil?

      meta[:headers] = ["Authorization: Bearer #{token}", "Accept: application/octet-stream"]
      found.fetch("url")
    end
  end
end

class Polyglot < Formula
  include Language::Python::Virtualenv

  desc "Language-quality checker and native-quality writer for learner texts"
  homepage "https://github.com/deadsimple-xyz/polyglot"
  # version and sha256 are rendered by Loop's shared brew publisher from VERSION and the release asset
  url "https://github.com/deadsimple-xyz/polyglot/releases/download/polyglot-v0.1.0/polyglot-0.1.0.tar.gz",
      using: PolyglotReleaseDownloadStrategy
  version "0.1.0"
  sha256 "db7f36fb7ee0fe8759dc444c9e9a292a1dec0bdea9552efcaacb106999f191bb"
  license :cannot_represent

  depends_on "uv" => :build
  depends_on "languagetool"
  depends_on "python@3.12"

  def install
    venv = virtualenv_create(libexec, "python3.12")
    # locked dependencies from uv.lock; the optional morph extra is not installed
    system Formula["uv"].opt_bin/"uv", "export", "--frozen", "--no-dev", "--no-emit-project",
           "--no-hashes", "-o", "requirements.txt"
    system venv.root/"bin/python", "-m", "pip", "install", "-r", "requirements.txt"
    system venv.root/"bin/python", "-m", "pip", "install", "--no-deps", "."
    bin.install_symlink libexec/"bin/polyglot"
  end

  def caveats
    <<~EOS
      Morph models (up to 9 GB) are not installed. Download them with:
        polyglot models
      Start LanguageTool for the L1 grammar layer:
        languagetool-server --port 8081
    EOS
  end

  test do
    assert_match "usage", shell_output("#{bin}/polyglot --help").downcase
    (testpath/"sample.md").write("Это простой текст.\n")
    system bin/"polyglot", "check", "sample.md", "--lang", "ru", "--out", "out"
    assert_path_exists testpath/"out/report.md"
  end
end
