STATUS: ALPHA

# hyrax-ansible
Ansible playbook for configuring a Hyrax IR.

It is hoped that this script will be a starting point for teams running Hyrax-based IRs in production.
The idea is similar to https://github.com/Islandora-Devops/claw-playbook

All roles assume services (Nginx, Fedora 4, PostgreSQL) are installed on one machine and communicate using UNIX sockets or the loopback interface. For large deployments, you'll want to edit these roles so that services are deployed on different machines and that communication between them is encrypted.

These roles do not create the default collection types, the default administrative set and the default load workflows. See [#17](/../../issues/17). Run these commands after running the playbook:

```sh
sudo su hyrax
cd /var/www/hyrax/hyrax-root/
export RAILS_ENV="production"
/usr/local/bin/bundle exec rails hyrax:default_collection_types:create
/usr/local/bin/bundle exec rails hyrax:default_admin_set:create
/usr/local/bin/bundle exec rails hyrax:workflow:load
```

These roles also do not create admin users or any work types. See https://github.com/samvera/hyrax#generate-a-work-type and https://github.com/samvera/hyrax/wiki/Making-Admin-Users-in-Hyrax.

The `hyrax` role assumes that an external SMTP server will be used. Some environments might want to use use a local mail transfer agent. To do so, the `production.rb` template will need to be changed. More information can be found in the Hyrax management guide: https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide#mailers.

This playbook is being tested against CentOS 7, Debian 9, and Ubuntu 18.04. A Vagrantfile is available at https://github.com/cu-library/hyrax-ansible-testvagrants.

`install_hyrax_on_localhost.yml` is a test playbook which runs the provided roles against localhost.

What does production-ready mean? A production ready instance of Hyrax should be secure. It should be regularly backed-up. It should be easy to update. Finally, it should have good performance.

## Security

INCOMPLETE

The services running within the VM should ensure data is protected from unauthorized access and modification. If one were to gain access to a nonprivileged Linux user account, one should not be able to access or modify any IR data. *Currently, this is not true of these roles. Some services are available to any Linux user.*

Attacks like remote code execution, XSS, SQL injection should be mitigated. Remote users should not be able to read or alter the filesystem in unexpected ways. *These roles still need a more thorough review against these types of attacks.*

## Backups

NEEDS TESTING, FEEDBACK WELCOME

The `hyrax` role has three backup scripts. They are copied to the /etc/cron.daily, /etc/cron.weekly, and /etc/cron.monthly directories, so the exact time they run is dependent on the distribution and system configuration.

Daily, Fedora 4 repository data (using the `fcr:backup` REST endpoint), PostgreSQL data (using `pg_dumpall`), the Redis `/var/lib/redis/dump.rdb` file and the Hyrax root directory are copied, tar'd together, and compressed. The resulting backup file has a datestamp and a MD5 checksum added to the filename. The daily backups reside in the `hyrax_backups_directory`/daily directory. As well as performing the backup, the daily backup script deletes any files in the daily directory that are older than 7 days old.

Weekly, a script moves the oldest daily backup to the `hyrax_backups_directory`/weekly directory. The weekly script also deletes files in the weekly directory that are older than 31 days old.

Monthly, a script moves the oldest weekly backup to the `hyrax_backups_directory`/monthly directory. The weekly script also deletes files in the monthly directory that are older than 365 days old.

For large deployments, this amount of backups might overwhelm local storage. It is recommended that the backup schedule and retention periods be tailored for your deployment.

It is up to local system administrators to copy backup data to a NAS or SAN, tape, or to cloud storage like Amazon Glacier or OLRC.

## Updates

INCOMPLETE

Where possible, it should be easy to keep a production server up-to-date. This means these roles should utilize well-known package repositories and package management tools when possible. Roles should be as idempotent and 'low impact' as possible, to encourage system administrators to run them regularly. Local modifications to community code should be minimal. These roles should not overwrite local changes and customizations. These roles do not create admin users, work types, administrative sets or load workflows.

## Performance

INCOMPLETE

These roles should install Hyrax so that it has good performance (max 500ms for most requests) on a "medium sized" server (4 core, 4GB RAM) when being used for typical workloads (documents and images, some multimedia, less than 10,000 digital objects). Community recommended software versions and configuration should be used.

## Software versions

Some software in the provided roles is installed using yum or apt from the default distribution repositories. The software version will depend on the distribution and release. For example, version 7 or 8 of Tomcat might be installed. For Java, OpenJDK version 8 is used.

Nginx is installed using that project's pre-built packages for the stable version, and not the default distribution repositories.

Node.js latest version 10.x is installed using the NodeSource repositories.

Some software is installed at a specific version:

* Fedora Repository v4.7.5 (Set using `fedora4_version` variable.)
* Solr v7.7.0 (Set using `solr_version` variable.)
* Ruby 2.5.3 (Set using `ruby_version` variable.)
* FFmpeg 4.1 (Set using `ffmpeg_version` variable.)
* Rails 5.1.6 (Set using `rails_version` variable.)
* Hyrax 2.4.1 (Set using `hyrax_version` variable.)
* FITS 1.4.0 (Set using `fits_version` variable.)

FFmpeg is built with:

* cmake: 3.12.3 (Set using `cmake_version` variable.)
* NASM 2.14.02 (Set using `nasm_version` variable.)
* Yasm 1.3.0 (Set using `yasm_version` variable.)
* x264: 20190109-2245-stable (Set using `x264_version` variable.)
* x265: 2.8 (Set using `x265_version` variable.)
* fdk-aac: 2.0.0 (Set using `fdk_aac_version` variable.)
* lame: 3.100 (Set using `lame_version` variable.)
* opus: 1.3 (Set using `opus_version` variable.)
* libogg: 1.3.3 (Set using `libogg_version` variable.)
* libvorbis: 1.3.6 (Set using `libvorbis_version` variable.)
* aom: a1615ed01a112432825f231a1fa47295cff127b4 (Set using `aom_version` variable.) Falling back to using a commit instead of a tagged release. The tarballs from https://aomedia.googlesource.com/aom/ are generated when requested for a particular tag. They are not stable releases, and as such do not have stable checksums. A checksum is not provided.
* libvpx: 1.7.0 (Set using `libvpx_version` variable.)
* libass: 0.14.0 (Set using `libass_version` variable.)

## Variables

|Variable|Notes|
|---|---|
|`aom_version` | The version of aom to download. Used to build FFmpeg. |
|`cmake_checksum` | Verify the cmake-`{{ cmake_version }}`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`cmake_version` | The version of cmake to download. Used to build aom library for FFmpeg. |
|`fdk_aac_checksum` | Verify the fdk-aac-`{{ fdk_aac_version }}`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`fdk_aac_version` | The version of fdk-aac to download. Used to build FFmpeg. |
|`fedora4_checksum` | Verify the fcrepo-webapp-`{{ fedora4_version }}`.war file, used by `get_url` module. Format: `<algorithm>:<checksum>` |
|`fedora4_postgresqldatabase_user_password` | The password used by fedora4 to connect to Postgresql. Secure |
|`fedora4_version` | The version of Fedora 4 to download. |
|`ffmpeg_checksum` | Verify the ffmpeg-`{{ ffmpeg_version }}`.tar.bz2 file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`ffmpeg_compile_dir` | The directory where ffmpeg sources will be downloaded, unarchived, and compiled. |
|`ffmpeg_version` | The version of FFmpeg to download. |
|`fits_checksum` | Verify the fits-`{{ fits_version }}`.zip file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`fits_version` | The version of FITS to download. |
|`hyrax_backups_directory` | The location where backup files will be created. |
|`hyrax_contact_form_email`| Email recipient of messages sent via the contact form. |
|`hyrax_from_email_address`| Emails sent from Hyrax will have this as the 'from' address. |
|`hyrax_geonames_username`| The username to use when connecting to the Geonames service. |
|`hyrax_postgresqldatabase_user_password` | The password used by hyrax to connect to Postgresql. Secure |
|`hyrax_secret_key_base` | The secret used by Rails for sessions etc. Secure |
|`hyrax_smtp_port`| The `hyrax_smtp_server`'s SMTP service is accessible at this port |
|`hyrax_smtp_server`| Emails will be sent by STMP using this server. |
|`imagemagick_package` | The name used by the `package` module when installing ImageMagick. Per-Distro |
|`java_openjdk_package` | The name used by the `package` module when installing the Java JDK. Per-Distro |
|`lame_checksum` | Verify the lame-`{{ lame_version }}`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`lame_version` | The version of lame to download. Used to build FFmpeg. |
|`libass_checksum` | Verify the libass-`{{ yasm_version }}`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`libass_version` | The version of libass to download. Used to build FFmpeg. |
|`libogg_checksum` | Verify the libogg-`{{ libogg_version }}`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`libogg_version` | The version of libogg  to download. Used to build FFmpeg. |
|`libvorbis_checksum` | Verify the libvorbis-`{{ libvorbis_version }}`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`libvorbis_version` | The version of libvorbis  to download. Used to build FFmpeg. |
|`libvpx_checksum` | Verify the libvpx-`{{ libvpx_version }}`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`libvpx_version` | The version of libvpx to download. Used to build FFmpeg. |
|`nasm_checksum` | Verify the nasm-`{{ nasm_version }}`.tar.bz2 file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`nasm_version` | The version of NASM to download. Used to build FFmpeg. |
|`opus_checksum` | Verify the opus-`{{ opus_version }}`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`opus_version` | The version of opus to download. Used to build FFmpeg. |
|`postgresql_contrib_package` | The name used by the `package` module when installing Postgresql's additional features. Per-Distro |
|`postgresql_devel_package` | The name used by the `package` module when installing the Postgresql C headers and other development libraries. Per-Distro |
|`postgresql_server_package` | The name used by the `package` module when installing the Postgresql server. Per-Distro |
|`python_psycopg2_package` | The name used by the `package` module when installing the Python Postgresql library (used by Ansible). Per-Distro |
|`redis_package` | The name used by the `package` module when installing Redis. Per-Distro |
|`ruby_tarbz2_sha1_checksum` | Verify the ruby-`{{ ruby_version }`.tar.bz2 file, used by `ruby-install`. Format: `<checksum>` |
|`ruby_version` | The version of Ruby to download and install. |
|`solr_checksum` | Verify the solr-`{{ solr_version }}`.tgz file, used by `get_url` module. Format: `<algorithm>:<checksum>`
|`solr_mirror` | The mirror to use when downloading Solr. |
|`solr_version` | The version of Solr to download. |
|`tomcat_admin_package` | The name used by the `package` module when installing the tomcat manager webapps. Per-Distro |
|`tomcat_fedora4_conf_path` | The path for the configuration file which sets JAVA_OPTS for Fedora4. Per-Distro |
|`tomcat_fedora4_war_path` | The path at which the fedora4 war file will be copied. Per-Distro |
|`tomcat_group` | The primary group for the tomcat service user. Per-Distro |
|`tomcat_package` | The name used by the `package` module when installing tomcat. Per-Distro |
|`tomcat_service_name` | The name of the tomcat service. Per-Distro |
|`tomcat_user_password` | The password used to build the tomcat-users.xml file. Secure |
|`tomcat_user` | The user which runs the tomcat service. Per-Distro |
|`tomcat_users_conf_path` | The path for tomcat-users.xml. Per-Distro |
|`x264_checksum` | Verify the x264-snapshot-`{{ x264_version }}`.tar.bz2 file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`x264_version` | The version of x264 to download. Used to build FFmpeg. |
|`x265_checksum` | Verify the x265_`{{ x265_version }}`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`x265_version` | The version of x265 to download. Used to build FFmpeg. |
|`yasm_checksum` | Verify the yasm-`{{ yasm_version }}`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` |
|`yasm_version` | The version of Yasm to download. Used to build FFmpeg. |

**Per-Distro**: Different value for different OSs. The test playbook uses

```
vars_files:
    - "vars/common.yml"
    - "vars/{{ ansible_distribution }}.yml"
```

and per-distribution variable files to provide different variables for different distributions.

**Secure**: Variables which should be different per-host and stored securely using Ansible Vaults or a tool like Hashicorp Vault. The test playbook insecurely puts these variables in `vars/common.yml`.
