STATUS: ALPHA

# hyrax-ansible
Ansible playbook for installing a Hyrax-based institutional repository.

## Introduction and Assumptions

This repository is a starting point for teams planning on running Hyrax-based IRs in production.
The idea is similar to https://github.com/Islandora-Devops/claw-playbook

These roles install the dependences for Hyrax (Solr, Ruby, Redis, PostreSQL, Node.js, Nginx, FITS, FFmpeg, and Fedora 4) then installs a Hyrax based application from a Github repository using Ansistrano.

This playbook is being tested against the latest versions of CentOS 7, Debian 9, and Ubuntu 18.04. The Vagrantfile used is available at https://github.com/cu-library/hyrax-ansible-testvagrants.

All roles assume services (Nginx, Fedora 4, PostgreSQL) are installed on one machine and communicate using UNIX sockets or the loopback interface. For large deployments, you'll want to edit these roles so that services are deployed on different machines and that communication between them is encrypted.

These roles also do not create admin users. See https://github.com/samvera/hyrax/wiki/Making-Admin-Users-in-Hyrax. But it does run the following to set up basic data structures needed for Hyrax / Hyku.

`bundle exec rails hyrax:default_collection_types:create hyrax:default_admin_set:create hyrax:workflow:load`

These roles assume that an external SMTP server will be used. Some environments might want to use use a local mail transfer agent. More information can be found in the Hyrax management guide: https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide#mailers.

`install_hyrax_on_localhost.yml` is a test playbook which runs the provided roles against localhost.

## Setup, Usage and Deployment
Initial provisioning of Linux boxes is left outside the scope of this project. We assume a working CentOS 7, Debian 9 or Ubuntu 18.04 system. If you are installing this repository on the box itself, check out the repository in to a local directory, verify the variables in `vars/common.yml`, then do the following:

```sh
ansible-galaxy install -r requirements.yml
ansible-playbook install_hyrax_on_localhost.yml
```

After initial setup you can use `ansible-playbook deploy.yml` and `ansible-playbook rollback.yml` to deploy and rollback various versions of the application code

### Carleton University Library's Use Of This Repo

Carleton University Library forked https://github.com/samvera/hyku and this repository into two private Github repositories. In those forks, we changed variables in the `common.yml` file including `ansistrano_git_repo` to point to our fork of Hyku. We moved the sensitive variables to an Ansible vault. Finally, we included the inventory and Ansible configuration needed to deploy on virtual machines in our environment.

## "Production Ready"

What does production ready mean? A production ready instance of Hyrax should be secure. It should be regularly backed-up. It should be easy to update. Finally, it should have good performance.

### Security

INCOMPLETE

The services running within the VM should ensure data is protected from unauthorized access and modification. If one were to gain access to a nonprivileged Linux user account, one should not be able to access or modify any IR data. *Currently, this is not true of these roles. Some services are available to any Linux user.*

### Backups

NEEDS TESTING, FEEDBACK WELCOME

The `hyrax` role has three backup scripts. They are copied to the /etc/cron.daily, /etc/cron.weekly, and /etc/cron.monthly directories, so the exact time they run is dependent on the distribution and system configuration.

Daily, Fedora 4 repository data (using the `fcr:backup` REST endpoint), PostgreSQL data (using `pg_dumpall`), the Redis `/var/lib/redis/dump.rdb` file and the Hyrax root directory are copied, tar'd together, and compressed. The resulting backup file has a datestamp and a MD5 checksum added to the filename. The daily backups reside in the `hyrax_backups_directory`/daily directory. As well as performing the backup, the daily backup script deletes any files in the daily directory that are older than 7 days old.

Weekly, a script moves the oldest daily backup to the `hyrax_backups_directory`/weekly directory. The weekly script also deletes files in the weekly directory that are older than 31 days old.

Monthly, a script moves the oldest weekly backup to the `hyrax_backups_directory`/monthly directory. The weekly script also deletes files in the monthly directory that are older than 365 days old.

For large deployments, this amount of backups might overwhelm local storage. It is recommended that the backup schedule and retention periods be tailored for your deployment.

It is up to local system administrators to copy backup data to a NAS or SAN, tape, or to cloud storage like Amazon Glacier or OLRC.

### Updates

NEEDS TESTING, FEEDBACK WELCOME

Where possible, it should be easy to keep a production server up-to-date. This means these roles should utilize well-known package repositories and package management tools when possible. Roles should be as idempotent and 'low impact' as possible, to encourage system administrators to run them regularly. Local modifications to community code should be minimal. These roles should not overwrite local changes and customizations.

### Performance

NEEDS TESTING, FEEDBACK WELCOME

These roles should install Hyrax so that it has good performance (max 500ms for most requests) on a "medium sized" server (4 core, 4GB RAM) when being used for typical workloads (documents and images, some multimedia, less than 10,000 digital objects). Community recommended software versions and configuration should be used.

## Software versions

Some software in the provided roles is installed using yum or apt from the default distribution repositories. The software version will depend on the distribution and release. For example, version 7 or 8 of Tomcat might be installed. For Java, OpenJDK version 8 is used.

Nginx is installed using that project's pre-built packages for the stable version, and not the default distribution repositories.

Node.js latest version 10.x is installed using the NodeSource repositories.

Some software is installed at a specific version:

* Fedora Repository 4.7.5 (Set using `fedora4_version` variable.)
* Solr 7.7.1 (Set using `solr_version` variable.)
* Ruby 2.5.3 (Set using `ruby_version` variable.)
* FFmpeg 4.1.1 (Set using `ffmpeg_version` variable.)
* Rails 5.1.6 (Set using `rails_version` variable.)
* FITS 1.4.0 (Set using `fits_version` variable.)

FFmpeg is built with:

* cmake: 3.13.4 (Set using `cmake_version` variable.)
* NASM 2.14.02 (Set using `nasm_version` variable.)
* Yasm 1.3.0 (Set using `yasm_version` variable.)
* x264: 20190227-2245-stable (Set using `x264_version` variable.)
* x265: 3.0 (Set using `x265_version` variable.)
* fdk-aac: 2.0.0 (Set using `fdk_aac_version` variable.)
* lame: 3.100 (Set using `lame_version` variable.)
* opus: 1.3 (Set using `opus_version` variable.)
* libogg: 1.3.3 (Set using `libogg_version` variable.)
* libvorbis: 1.3.6 (Set using `libvorbis_version` variable.)
* aom: a1615ed01a112432825f231a1fa47295cff127b4 (Set using `aom_version` variable.) Falling back to using a commit instead of a tagged release. The tarballs from https://aomedia.googlesource.com/aom/ are generated when requested for a particular tag. They are not stable releases, and as such do not have stable checksums. A checksum is not provided.
* libvpx: 1.8.0 (Set using `libvpx_version` variable.)
* libass: 0.14.0 (Set using `libass_version` variable.)

## Variables

|Variable|Notes|Default|
|---|---|---|
|`ansistrano_deploy_to` | Path where Hyrax app is deployed. | `/var/www/hyrax` |
|`ansistrano_keep_releases` | Number of old releases to keep. | `5` |
|`ansistrano_shared_paths` | Array of shared paths that are symlinked to each release. | `log, public/system, tmp, vendor/bundle` |
|`ansistrano_shared_files` | Array of shared files that are symlinked to each release. | `config/database.yml, config/puma.rb`|
|`ansistrano_deploy_via` | Ansistrano tool for depoyment, can by rsync or git. | `git` |
|`ansistrano_git_repo` | Repo of the application to deploy | `https://github.com/samvera/hyku.git` |
|`ansistrano_git_branch` | What version of the repository to check out. This can be the full 40-character SHA-1 hash, the literal string HEAD, a branch name, or a tag name. | `master` |
|`ansistrano_git_identity_key_path` | If specified this file is copied over and used as the identity key for the git commands, path is relative to the playbook in which it is used ||
|`aom_version` | The version of aom to download. Used to build FFmpeg. | `a1615ed01a112432825f231a1fa47295cff127b4` |
|`bundler_version` | The version of the gem bundler to install. | `1.17.3` |
|`cmake_checksum` | Verify the cmake-`3.13.4`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:563a39e0a7c7368f81bfa1c3aff8b590a0617cdfe51177ddc808f66cc0866c76` |
|`cmake_version` | The version of cmake to download. Used to build aom library for FFmpeg. | `3.13.4` |
|`fdk_aac_checksum` | Verify the fdk-aac-`2.0.0`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:a98a3f2b0658683c51739f6362f496e3d7d2c073` |
|`fdk_aac_version` | The version of fdk-aac to download. Used to build FFmpeg. | `2.0.0` |
|`fedora4_checksum` | Verify the fcrepo-webapp-`4.7.5`.war file, used by `get_url` module. Format: `<algorithm>:<checksum>` | `sha1:243df71ceef8dca9309f230f2abb31c195368c5c` |
|`fedora4_postgresqldatabase_user_password` | **Secure.** The password used by fedora4 to connect to Postgresql. | `insecure_password` |
|`fedora4_version` | The version of Fedora 4 to download. | `4.7.5` |
|`ffmpeg_checksum` | Verify the ffmpeg-`4.1.1`.tar.bz2 file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:9076734d98fb8d6ad1cff8f8f68228afa0bb2204` |
|`ffmpeg_compile_dir` | The directory where ffmpeg sources will be downloaded, unarchived, and compiled. | `/opt/ffmpeg` |
|`ffmpeg_version` | The version of FFmpeg to download. | `4.1.1` |
|`fits_checksum` | Verify the fits-`1.4.0`.zip file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:24ebec8157dda63bf60bd3009a6e8961b8f35b05` |
|`fits_version` | The version of FITS to download. | `1.4.0` |
|`hyrax_backups_directory` | The location where backup files will be created. | `/var/backups` |
|`hyrax_database_pool_size` | The size of the database pool. | `30` |
|`hyrax_from_email_address ` | The email address to use for the from field when sending emails from Hyrax. | `test@example.com` |
|`hyrax_postgresqldatabase_user_password` | **Secure.** The password used by hyrax to connect to Postgresql. | `insecure_password` |
|`hyrax_secret_key_base` | **Secure.** The secret used by Rails for sessions etc. | `insecure_key_base` |
|`hyrax_smtp_address` | Rails smtp address. | `smtp.example.com` |
|`hyrax_smtp_port` | Rails smtp port. | `25` |
|`hyrax_smtp_domain` | Rails smtp domain for mailer. | `example.com` |
|`hyrax_smtp_user_name` | **Secure.** Rails smtp username for mailer. | `change_this_username` |
|`hyrax_smtp_password` | **Secure.** Rails smtp password for mailer. | `insecure_password` |
|`hyrax_smtp_authentication` | Rails authentication method for mailer. | `False` |
|`hyrax_smtp_enable_starttls_auto` | Rails starttls setting for mailer. | `False` |
|`hyrax_smtp_openssl_verify_mode` | Rails openssl verify mode for mailer. | `False` |
|`hyrax_smtp_ssl` | Rails ssl setting for mailer. | `False` |
|`hyrax_smtp_tls` | Rails tls setting for mailer. | `False` |
|`imagemagick_package` | **Per-Distro** The name used by the `package` module when installing ImageMagick. ||
|`java_openjdk_package` | **Per-Distro** The name used by the `package` module when installing the Java JDK. ||
|`lame_checksum` | Verify the lame-`3.100`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:64c53b1a4d493237cef5e74944912cd9f98e618d` |
|`lame_version` | The version of lame to download. Used to build FFmpeg. | `3.100` |
|`libass_checksum` | Verify the libass-`1.3.0`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:aec905e8b1db9a9762f90ec11037807fcfe714d1` |
|`libass_version` | The version of libass to download. Used to build FFmpeg. | `0.14.0` |
|`libogg_checksum` | Verify the libogg-`1.3.3`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:28ba40fd2e2d41988f658a0016fa7b534e509bc0` |
|`libogg_version` | The version of libogg  to download. Used to build FFmpeg. | `1.3.3` |
|`libvorbis_checksum` | Verify the libvorbis-`1.3.6`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:91f140c220d1fe3376d637dc5f3d046263784b1f` |
|`libvorbis_version` | The version of libvorbis  to download. Used to build FFmpeg. | `1.3.6` |
|`libvpx_checksum` | Verify the libvpx-`1.8.0`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:0a5ff6d36e592b404fae4435adc76a68e3d96afe` |
|`libvpx_version` | The version of libvpx to download. Used to build FFmpeg. | `1.8.0` |
|`make_jobs` | Sets an environment variable MAKEFLAGS to '-j X' in the test playbook. | `2` |
|`nasm_checksum` | Verify the nasm-`2.14.02`.tar.bz2 file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:fe098ee4dc9c4c983696c4948e64b23e4098b92b` |
|`nasm_version` | The version of NASM to download. Used to build FFmpeg. | `2.14.02` |
|`opus_checksum` | Verify the opus-`1.3`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:63088df89c6d868bfb160a1eff1797cb5fe42fee` |
|`opus_version` | The version of opus to download. Used to build FFmpeg. | `1.3` |
|`postgresql_contrib_package` | **Per-Distro** The name used by the `package` module when installing Postgresql's additional features. ||
|`postgresql_devel_package` | **Per-Distro** The name used by the `package` module when installing the Postgresql C headers and other development libraries. ||
|`postgresql_server_package` | **Per-Distro** The name used by the `package` module when installing the Postgresql server. ||
|`puma_web_concurency` | Number of Puma processes to start. | `4` |
|`python_psycopg2_package` | **Per-Distro** The name used by the `package` module when installing the Python Postgresql library (used by Ansible). ||
|`redis_package` | **Per-Distro** The name used by the `package` module when installing Redis. ||
|`ruby_tarbz2_sha1_checksum` | Verify the ruby-`2.5.3`.tar.bz2 file, used by `ruby-install`. Format: `<checksum>` | `d47ede7dab79de25fcc274dfcad0f92f389a4313` |
|`ruby_version` | The version of Ruby to download and install. | `2.5.3` |
|`sidekiq_threads` | Tune the number of sidekiq threads that will be started. | `10` |
|`solr_checksum` | Verify the solr-`7.7.1`.tgz file, used by `get_url` module. Format: `<algorithm>:<checksum>` | `sha512:9b2f85ce46ab4a8601e0f3d0f6bfa1268d885cc54886a589354dc24434134e294a6714daf2514e362f8a6c1f5fb268c12fb2f86aae7b7a03321419b9f99b4567` |
|`solr_mirror` | The mirror to use when downloading Solr. | `https://mirror.csclub.uwaterloo.ca/apache` |
|`solr_version` | The version of Solr to download. | `7.7.1` |
|`tomcat_admin_package` | **Per-Distro** The name used by the `package` module when installing the tomcat manager webapps. ||
|`tomcat_fedora4_conf_path` | **Per-Distro** The path for the configuration file which sets JAVA_OPTS for Fedora4. ||
|`tomcat_fedora4_war_path` | **Per-Distro** The path at which the fedora4 war file will be copied. ||
|`tomcat_group` | **Per-Distro** The primary group for the tomcat service user. ||
|`tomcat_package` | **Per-Distro** The name used by the `package` module when installing tomcat. ||
|`tomcat_service_name` | **Per-Distro** The name of the tomcat service. ||
|`tomcat_user_password` | **Secure.** The password used to build the tomcat-users.xml file. | `insecure_password` |
|`tomcat_user` | **Per-Distro** The user which runs the tomcat service. ||
|`tomcat_users_conf_path` | **Per-Distro** The path for tomcat-users.xml. ||
|`x264_checksum` | Verify the x264-snapshot-`20190227-2245-stable`.tar.bz2 file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:95328420e69d39c2055b34289b7208cd4b39fec2` |
|`x264_version` | The version of x264 to download. Used to build FFmpeg. | `20190227-2245-stable` |
|`x265_checksum` | Verify the x265_`3.0`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `md5:8ff1780246bb7ac8506239f6129c04ec` |
|`x265_version` | The version of x265 to download. Used to build FFmpeg. | `3.0` |
|`yasm_checksum` | Verify the yasm-`1.3.0`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha1:b7574e9f0826bedef975d64d3825f75fbaeef55e` |
|`yasm_version` | The version of Yasm to download. Used to build FFmpeg. | `1.3.0` |

**Per-Distro**: Different value for different OSs. The test playbook uses

```
vars_files:
    - "vars/common.yml"
    - "vars/{{ ansible_distribution }}.yml"
```

and per-distribution variable files to provide different variables for different distributions.

**Secure**: Variables which should be different per-host and stored securely using Ansible Vaults or a tool like Hashicorp Vault. The test playbook insecurely puts these variables in `vars/common.yml`.


