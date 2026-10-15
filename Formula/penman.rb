# Rendered by Loop's render-homebrew-formula.mjs from the released source archive metadata.
require "download_strategy"
require "utils/github/api"

# The release asset lives on a private repository. The declared url is the asset's browser url; at fetch
# time the release is read by tag through the GitHub REST API with Homebrew's own GitHub credential, and the
# asset is downloaded from its API url. `sha256` still pins the bytes.
class PenmanReleaseDownloadStrategy < CurlDownloadStrategy
  ASSET_URL = %r{\Ahttps://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/([^/]+)\z}

  private

  def resolve_url_basename_time_file_size(url, timeout: nil)
    return super if url.start_with?("#{GitHub::API_URL}/")

    super(penman_asset_api_url(url), timeout:)
  end

  def penman_asset_api_url(url)
    @penman_asset_api_url ||= begin
      match = ASSET_URL.match(url)
      raise CurlDownloadStrategyError.new(url, "penman_release_asset_url_invalid") unless match

      owner, repository, tag, asset = match.captures
      token = GitHub::API.credentials
      if token.blank?
        raise CurlDownloadStrategyError.new(
          url, "penman_release_download_unauthenticated: sign in to GitHub with `gh auth login`, then run brew again"
        )
      end

      base = "#{GitHub::API_URL}/repos/#{owner}/#{repository}/releases"
      release = GitHub::API.open_rest("#{base}/tags/#{tag}")
      assets = GitHub::API.open_rest("#{base}/#{release.fetch("id")}/assets?per_page=100")
      found = assets.find { |candidate| candidate["name"] == asset }
      raise CurlDownloadStrategyError.new(url, "penman_release_asset_missing: #{asset} on #{tag}") if found.nil?

      meta[:headers] = ["Authorization: Bearer #{token}", "Accept: application/octet-stream"]
      found.fetch("url")
    end
  end
end

class Penman < Formula
  include Language::Python::Virtualenv

  desc "Books to three-level learner editions, report.md and EPUB files"
  homepage "https://github.com/deadsimple-xyz/penman"
  url "https://github.com/deadsimple-xyz/penman/releases/download/penman-v0.1.0/penman-0.1.0.tar.gz",
      using: PenmanReleaseDownloadStrategy
  version "0.1.0"
  sha256 "6abfdf1fb16da353e7cb0b06ebaf02219355d65fc82ae226477e81ce0c61c7e0"

  depends_on "python@3.12"
  depends_on "rust" => :build # jiter and pydantic-core build from source

  # Python dependencies pinned to corpus/refine/uv.lock (a test keeps them equal).
  resource "annotated-types" do
    url "https://files.pythonhosted.org/packages/5f/56/a8120250d128bed162cd73c76d45f6ef9991f3e068f62a8ee060afa3104a/annotated_types-0.8.0.tar.gz"
    sha256 "13b2beaad985e05e2d6407ee4c4f35590b11f8d693a258a561055cac8f64cab7"
  end

  resource "anthropic" do
    url "https://files.pythonhosted.org/packages/0b/ed/e76e50601b7c476bcb9a2a7a4c4dab6f1a9b2c03e3922de8b3ec599ccbc5/anthropic-1.13.0.tar.gz"
    sha256 "ad11d9bb9adafdfea26113943bcde9973e2a439ebeeda6c89ff3e3d85bb2f5c1"
  end

  resource "anyio" do
    url "https://files.pythonhosted.org/packages/a9/d2/f4d173e22df740bc37b1db102b386ba719b66e95b0f0d751f556b387e6d2/anyio-4.15.1.tar.gz"
    sha256 "9f28306018cbd6d329e64a36d58256edff76dd996fe423bc957326e578b82a94"
  end

  resource "dawg2-python" do
    url "https://files.pythonhosted.org/packages/2d/03/85171ce1e59088237aebf21943d1136463f6422820f096ac8cf9322aa851/dawg2_python-0.9.0.tar.gz"
    sha256 "adea0312acd1a958659e8448ce6899046c0858d0b6c8949a51eebdeb5a113e4a"
  end

  resource "docstring-parser" do
    url "https://files.pythonhosted.org/packages/e0/4d/f332313098c1de1b2d2ff91cf2674415cc7cddab2ca1b01ae29774bd5fdf/docstring_parser-0.18.0.tar.gz"
    sha256 "292510982205c12b1248696f44959db3cdd1740237a968ea1e2e7a900eeb2015"
  end

  resource "ftfy" do
    url "https://files.pythonhosted.org/packages/a5/d3/8650919bc3c7c6e90ee3fa7fd618bf373cbbe55dff043bd67353dbb20cd8/ftfy-6.3.1.tar.gz"
    sha256 "9b3c3d90f84fb267fe64d375a07b7f8912d817cf86009ae134aa03e1819506ec"
  end

  resource "h11" do
    url "https://files.pythonhosted.org/packages/01/ee/02a2c011bdab74c6fb3c75474d40b3052059d95df7e73351460c8588d963/h11-0.16.0.tar.gz"
    sha256 "4e35b956cf45792e4caa5885e69fba00bdbc6ffafbfa020300e549b208ee5ff1"
  end

  resource "httpcore2" do
    url "https://files.pythonhosted.org/packages/cb/f3/1db7aa2bc2524062192bb0e0323969492d1883152a232fe36eea65f4e35c/httpcore2-2.13.1.tar.gz"
    sha256 "e0aa977abe17e69a3b820a24542a6fa88702676d83880b8d194dcd18408e5103"
  end

  resource "httpx2" do
    url "https://files.pythonhosted.org/packages/d5/44/474bef2a0e9d90f1715d32cb98b0738695ca17ba324095fb2497ed7fbd59/httpx2-2.13.1.tar.gz"
    sha256 "e48744a19e3af5ee48313d0ce5fe941d5422fae5705ea922a4aabf94d7800dfa"
  end

  resource "httpx2-jsfetch" do
    url "https://files.pythonhosted.org/packages/cd/c4/0e5636363151a2a1795e0a77617168b9ca438e1748ec05fc9b5687f93d64/httpx2_jsfetch-1.0.tar.gz"
    sha256 "70a0e3eabfef7cce5ad9c629f7d01ca05e418f586646f4ddf14782e4c1454c60"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/f5/08/8eea9d4b8302028f3abb2c0813953f7aec26d33b7a8960ed760e65ff29fa/idna-3.20.tar.gz"
    sha256 "a7db850025b95ded1eae8a46181a1a6c56c92c96f0e2b005d9ff8dc0210cab44"
  end

  resource "jiter" do
    url "https://files.pythonhosted.org/packages/9c/1f/8176d92e001f86505424b41664032ae26a882bc9ca41a32c803f373f9195/jiter-0.17.0.tar.gz"
    sha256 "03e432f226a453851079fb84cd17c6da9991eab723e28d716f14ae3d906e0c12"
  end

  resource "langcodes" do
    url "https://files.pythonhosted.org/packages/a9/75/f9edc5d72945019312f359e69ded9f82392a81d49c5051ed3209b100c0d2/langcodes-3.5.1.tar.gz"
    sha256 "40bff315e01b01d11c2ae3928dd4f5cbd74dd38f9bd912c12b9a3606c143f731"
  end

  resource "locate" do
    url "https://files.pythonhosted.org/packages/26/b0/6b303d4a2a20046dc396de914a6c1840253ff874630f00864ffe623acb68/locate-1.1.1.tar.gz"
    sha256 "432750f5b7e89f8c99942ca7d8722ccd1e7954b20e6a973027fccb6cc00af857"
  end

  resource "msgpack" do
    url "https://files.pythonhosted.org/packages/0a/e7/bb605a7bab2d8425a64b3fa762b39dc1bf1c7e3f11ba6fb5413d6db0ff8c/msgpack-1.2.3.tar.gz"
    sha256 "32edb81a2b5eb7cd7c9d941b2bfbbb082fd2cd09e0e725930316af6b708db186"
  end

  resource "pydantic" do
    url "https://files.pythonhosted.org/packages/7c/0b/8e10b2e693af8ec54346a14caf36221334775975a747c9ceaa3f8371d96d/pydantic-2.14.1.tar.gz"
    sha256 "94f478203dd03404682a1ada216965651dd74b1d2d5ffd62e00e0837caab5c26"
  end

  resource "pydantic-core" do
    url "https://files.pythonhosted.org/packages/a6/24/af4ec4be49fbc810f35b0bdcacc3d433b56bbfa469fd3bfd4ae116cd9bf1/pydantic_core-2.50.1.tar.gz"
    sha256 "e50d7b94baac6c7d09927fa5ca5800a0c7ee5015c7fcff65beb3a1931b5a6e09"
  end

  resource "pymorphy3" do
    url "https://files.pythonhosted.org/packages/17/63/3a1eabd3a7e6e060b69a87fe9c28fe89f75f4d49e55f0caf2e29c943c003/pymorphy3-2.0.6.tar.gz"
    sha256 "1603df3bc9e116967c990607f5b97d42fb1c572d6839b851af3501e51d7f5493"
  end

  resource "pymorphy3-dicts-ru" do
    url "https://files.pythonhosted.org/packages/ba/13/02ffe6893a777add5c8a43f212f31a3f6a03e7d44a484cf7b5ac5381fddb/pymorphy3-dicts-ru-2.4.417150.4580142.tar.gz"
    sha256 "39ab379d4ca905bafed50f5afc3a3de6f9643605776fbcabc4d3088d4ed382b0"
  end

  resource "regex" do
    url "https://files.pythonhosted.org/packages/fc/f2/af1da9d3ceed77bfcdce40427d49ba0be94e4fe84245e3bfef68c10e75b6/regex-2026.9.29.tar.gz"
    sha256 "8b5fcc4771732191b2b7d1dd68d8f0353f47f8d90b6150f6dce58bf1112442cb"
  end

  resource "setuptools" do
    url "https://files.pythonhosted.org/packages/6d/44/f5da03a8ef95d369145c5bb53050e7877c9f3d312e128605fd9504829143/setuptools-84.0.0.tar.gz"
    sha256 "f4695c21257f0d9b537ec2692c941d02ee143b7cc1276941349a546573b2ef73"
  end

  resource "sniffio" do
    url "https://files.pythonhosted.org/packages/a2/87/a6771e1546d97e7e041b6ae58d80074f81b7d5121207425c964ddf5cfdbd/sniffio-1.3.1.tar.gz"
    sha256 "f4324edc670a0f49750a81b895f35c3adb843cca46f0530f79fc1babb23789dc"
  end

  resource "truststore" do
    url "https://files.pythonhosted.org/packages/53/a3/1585216310e344e8102c22482f6060c7a6ea0322b63e026372e6dcefcfd6/truststore-0.10.4.tar.gz"
    sha256 "9d91bd436463ad5e4ee4aba766628dd6cd7010cf3e2461756b3303710eebc301"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/f6/cc/6253133b5bb138fc3306cebfbda2c520f545d36b5be2c7255cc528bb45d6/typing_extensions-4.16.0.tar.gz"
    sha256 "dc983d19a509c94dba722ee6abd33940f7c05a89e243c47e907eb4db6f1a43e5"
  end

  resource "typing-inspection" do
    url "https://files.pythonhosted.org/packages/a3/26/b09b8010994eccc3c09092e6b34058f36a460eea2d4c3e8b910c695975a0/typing_inspection-0.4.4.tar.gz"
    sha256 "547274fa6b0a561ccf549cc9524b999a578e737d015d8709d021f9d0d13bea47"
  end

  resource "wcwidth" do
    url "https://files.pythonhosted.org/packages/f0/b4/7830542634bb2d3e62aa3b586a72d5b3b6c91c3168929e7000ef3fed041d/wcwidth-0.9.2.tar.gz"
    sha256 "ae0ef90b90f6af38b54f1fe6d58662ec33b3cb4b8391958a62416d654231727b"
  end

  resource "wordfreq" do
    url "https://files.pythonhosted.org/packages/4c/cd/9581ff0ea2c581012d0caae4bba024f3ff6b46e030a55ddec1ce545e2caf/wordfreq-3.1.1.tar.gz"
    sha256 "7943098975f25c2a70e1151ee5a62083b14a5f86f6cc5703cc9526f716ceb408"
  end

  def install
    venv = virtualenv_create(libexec, "python3.12")
    venv.pip_install resources
    venv.pip_install_and_link buildpath/"corpus/refine"
  end

  test do
    assert_match "usage", shell_output("#{bin}/penman --help").downcase
    assert_match "book", shell_output("#{bin}/penman run --help")
  end
end
