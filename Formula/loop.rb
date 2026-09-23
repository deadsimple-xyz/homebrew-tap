# Template of the `loop` formula for the deadsimple-xyz/homebrew-tap tap. The ONLY source of the formula:
# services/loop-orchestrator/tools/package-loop-release.mjs renders it with the release's version, sha256
# and repository, and refuses if a placeholder is left (stack.md, Event ingress, "Homebrew distribution").

require "download_strategy"
require "utils/github/api"

# The release asset lives on a private repository. The declared url is the asset's browser url; at fetch
# time the release is read by tag through the GitHub REST API with Homebrew's own GitHub credential, and the
# asset is downloaded from its API url. `sha256` still pins the bytes.
class LoopReleaseDownloadStrategy < CurlDownloadStrategy
  ASSET_URL = %r{\Ahttps://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/([^/]+)\z}

  private

  def resolve_url_basename_time_file_size(url, timeout: nil)
    return super if url.start_with?("#{GitHub::API_URL}/")

    # The API url redirects to a short-lived storage url; Homebrew downloads that resolved url and drops
    # the Authorization header on the host change.
    super(loop_asset_api_url(url), timeout:)
  end

  def loop_asset_api_url(url)
    @loop_asset_api_url ||= begin
      match = ASSET_URL.match(url)
      raise CurlDownloadStrategyError.new(url, "loop_release_asset_url_invalid") unless match

      owner, repository, tag, asset = match.captures
      token = GitHub::API.credentials
      if token.blank?
        raise CurlDownloadStrategyError.new(
          url, "loop_release_download_unauthenticated: sign in to GitHub with `gh auth login`, then run brew again"
        )
      end

      # The release's own `assets` array was measured EMPTY on a private-repository release whose assets were
      # uploaded and listed by the release's assets endpoint (loop-v0.1.0, 23 Sep 2026), so the assets are read
      # from that endpoint, by the release id the tag resolves to.
      base = "#{GitHub::API_URL}/repos/#{owner}/#{repository}/releases"
      release = GitHub::API.open_rest("#{base}/tags/#{tag}")
      assets = GitHub::API.open_rest("#{base}/#{release.fetch("id")}/assets?per_page=100")
      found = assets.find { |candidate| candidate["name"] == asset }
      raise CurlDownloadStrategyError.new(url, "loop_release_asset_missing: #{asset} on #{tag}") if found.nil?

      meta[:headers] = ["Authorization: Bearer #{token}", "Accept: application/octet-stream"]
      found.fetch("url")
    end
  end
end

class Loop < Formula
  desc "GitHub-native autonomous product delivery, run as a background service"
  homepage "https://github.com/deadsimple-xyz/loop"
  url "https://github.com/deadsimple-xyz/loop/releases/download/loop-v0.1.19/loop-0.1.19-darwin-arm64.tar.gz",
      using: LoopReleaseDownloadStrategy
  version "0.1.19"
  sha256 "ec356b47e777f43771a0d94104287b17e43b38f4f05e3f91fdc431e1be8cc660"

  depends_on arch: :arm64
  # The host's tunnel connector (infra/loop-host/launchd/loop-cloudflared runs /opt/homebrew/bin/cloudflared).
  depends_on "cloudflared"
  # `loop create`: the GitHub CLI for the owner's token (/opt/homebrew/bin/gh), and the two tools
  # lib/loop-product-operations.mjs pins by exact Cellar path and version (gitleaks 8.30.1, git-filter-repo 2.47.0).
  depends_on "gh"
  depends_on "git-filter-repo"
  # The manager's GitHub hands: tools/loop-github-mcp.mjs runs `github-mcp-server stdio --toolsets issues`.
  depends_on "github-mcp-server"
  depends_on "gitleaks"
  depends_on :macos

  def install
    libexec.install Dir["libexec/*"]
    (bin/"loop").write <<~SH
      #!/bin/bash
      exec "#{opt_libexec}/node/bin/node" "#{opt_libexec}/services/loop-orchestrator/tools/loop.mjs" "$@"
    SH
    chmod 0755, bin/"loop"
  end

  def caveats
    <<~EOS
      Loop runs as a background service and starts itself after every login:
        brew services start deadsimple-xyz/tap/loop
      Upgrades are `brew upgrade deadsimple-xyz/tap/loop`; the running service moves to the new version by
      itself. Homebrew asks you to trust a tap formula before a plain `brew upgrade` includes it:
        brew trust --formula deadsimple-xyz/tap/loop
    EOS
  end

  service do
    name macos: "com.deadsimple.loop.service"
    run [opt_bin/"loop", "service", "--installed-root", opt_libexec/"services/loop-orchestrator"]
    keep_alive true
    run_at_load true
    process_type :background
    log_path var/"log/loop/service.log"
    error_log_path var/"log/loop/service.log"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/loop version")
  end
end
