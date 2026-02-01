class StaticController < ApplicationController

  def assetlinks
    render json: [{
      "relation" => ["delegate_permission/common.handle_all_urls"],
      "target" => {
        "namespace" => "android_app",
        "package_name" => "org.autofauna.twa",
        "sha256_cert_fingerprints" => ["98:68:BD:E5:B4:E8:1F:DA:46:60:8A:04:1F:D2:27:D4:5D:C5:8D:B7:85:DB:88:6A:F3:50:39:59:03:96:55:B6"]
      }
    }]
  end
end
