Rails.application.configure do
  ActionMailer::Base.smtp_settings = { address: {{ smtp_address }},
                                       port: {{ smtp_port }},
                                       domain: {{ smtp_domain }},
                                       user_name: {{ smtp_user_name }},
                                       password: {{ smtp_password }},
                                       authentication: {{ smtp_authentication }},
                                       enable_starttls_auto: {{ smtp_enable_starttls_auto }},
                                       openssl_verify_mode: {{ smtp_openssl_verify_mode }},
                                       ssl: {{ smtp_ssl }},
                                       tls: {{ smtp_tls }}
                                     }
end
