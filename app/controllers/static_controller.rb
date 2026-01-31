class StaticController < ApplicationController

  def assetlinks
    render json: [{
      "relation" => ["delegate_permission/common.handle_all_urls"],
      "target" => {
        "namespace" => "android_app",
        "package_name" => "com.autofauna.app",
        "sha256_cert_fingerprints" => ["TODO:REPLACE:WITH:ACTUAL:FINGERPRINT"]
      }
    }]
  end
end
