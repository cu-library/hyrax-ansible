Rails.application.configure do
  ActionMailer::Base.smtp_settings = { address: {{ hyrax_smtp_address }},
                                       port: {{ hyrax_smtp_port }},
                                       domain: {{ hyrax_smtp_domain }},
                                       user_name: {{ hyrax_smtp_user_name }},
                                       password: {{ hyrax_smtp_password }},
                                       authentication: {{ hyrax_smtp_authentication }},
                                       enable_starttls_auto: {{ hyrax_smtp_enable_starttls_auto }},
                                       openssl_verify_mode: {{ hyrax_smtp_openssl_verify_mode }},
                                       ssl: {{ hyrax_smtp_ssl }},
                                       tls: {{ hyrax_smtp_tls }}
                                     }
end
