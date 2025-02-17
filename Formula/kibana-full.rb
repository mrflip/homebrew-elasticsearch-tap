VERSION="8.3.2"
class KibanaFull < Formula
  desc "Analytics and search dashboard for Elasticsearch"
  homepage "https://www.elastic.co/products/kibana"
  url "https://artifacts.elastic.co/downloads/kibana/kibana-#{VERSION}-darwin-x86_64.tar.gz?tap=elastic/homebrew-tap"
  version VERSION
  sha256 "be25dd4095ac8f349a2cf290ad6aa7c3e05334e68edce3f47cf6cab44c507a40"
  conflicts_with "kibana"

  def install
    libexec.install(
      "bin",
      "config",
      "data",
      "node",
      "node_modules",
      "package.json",
      "plugins",
      "src",
      "x-pack",
    )

    Pathname.glob(libexec/"bin/*") do |f|
      next if f.directory?
      bin.install libexec/"bin"/f
    end
    bin.env_script_all_files(
      libexec/"bin",
      {
        "KIBANA_PATH_CONF" => etc/"kibana",
        "KBN_PATH_CONF"    => etc/"kibana",
        "DATA_PATH"        => var/"lib/kibana/data",
        "LOG_PATH"         => var/"llog/kibana/log",
      },
    )

    cd libexec do
      packaged_config = IO.read "config/kibana.yml"
      actual_config = packaged_config + "\npath.data: #{var}/lib/kibana/data\n"
      actual_config.gsub!(
        /# Enables you to specify a file where Kibana stores log output/,
        <<~EOS
        # Enables you to specify a file where Kibana stores log output
        logging.appenders.default:
          type:          file
          fileName:      /usr/local/var/log/kibana/kibana.log
          layout:        { type: json }
        EOS
      )
      IO.write("config/kibana.yml", actual_config)
      (etc/"kibana").install Dir["config/*"]
      rm_rf "config"
      rm_rf "data"
    end
  end

  def post_install
    (var/"lib/kibana/data").mkpath
    (var/"lib/kibana/log").mkpath
    (prefix/"plugins").mkdir
  end

  def caveats; <<~EOS
    Config: #{etc}/kibana/
    If you wish to preserve your plugins upon upgrade, make a copy of
    #{opt_prefix}/plugins before upgrading, and copy it into the
    new keg location after upgrading.
  EOS
  end
  
  service do
    run [opt_bin/"kibana"]
    working_dir HOMEBREW_PREFIX
    log_path var/"log/kibana.log"
    error_log_path var/"log/kibana.log"
  end

  test do
    ENV["BABEL_CACHE_PATH"] = testpath/".babelcache.json"
    assert_match(/#{version}/, shell_output("#{bin}/kibana -V"))
  end
end
