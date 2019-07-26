Rails.application.configure do
  ActionMailer::Base.smtp_settings = { address: "{{ hyrax_smtp_address }}",
                                       port: {{ hyrax_smtp_port }},
                                       domain: "{{ hyrax_smtp_domain }}",
{% if hyrax_smtp_user_name|length %}                                       user_name: "{{ hyrax_smtp_user_name }}",{% endif %}
{% if hyrax_smtp_password|length %}                                       password: "{{ hyrax_smtp_password }}",{% endif %}
                                       authentication: {{ hyrax_smtp_authentication | lower }},
                                       enable_starttls_auto: {{ hyrax_smtp_enable_starttls_auto | lower }},
                                       openssl_verify_mode: {{ hyrax_smtp_openssl_verify_mode | lower }},
                                       ssl: {{ hyrax_smtp_ssl | lower }},
                                       tls: {{ hyrax_smtp_tls | lower }}
                                     }
end
