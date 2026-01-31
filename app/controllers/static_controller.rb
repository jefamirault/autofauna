class StaticController < ApplicationController

  def assetlinks
    render json: [{
      "relation" => ["delegate_permission/common.handle_all_urls"],
      "target" => {
        "namespace" => "android_app",
        "package_name" => "org.autofauna.twa",
        "sha256_cert_fingerprints" => ["19:78:DA:EF:25:40:95:D1:16:CF:31:20:24:FD:7D:00:67:02:A2:FF:63:91:DD:DB:73:D3:C9:F4:BD:6D:CC:8B"]
      }
    }]
  end
end
